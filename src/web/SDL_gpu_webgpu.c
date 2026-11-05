/* Goose compiler: an SDL_GPU backend over WebGPU, for --target wasm64-web
   (docs/design/wasm.md §8, milestone 4). SDL 3.4 has no WebGPU driver, so a
   page that uses the gfx package builds SDL with SDL_GPU_PRIVATE and links
   this file as its PrivateGPUDriver: SDL_gpu.c validates each call as for
   any backend and hands it here, and the gfx package runs unchanged. The
   work is done by the JavaScript half, sdl_gpu_webgpu.js (wg_* below),
   over navigator.gpu; what is asynchronous there suspends the program
   through JSPI.

   Shaders arrive as the GSWG payload the compiler puts in a web build's
   shader blobs in place of the SPIR-V (src/gfx_blob.h): WGSL from
   cute_spirv, whose @group is SDL_GPU's set, with its bindings. Uniform
   pushes go to a ring buffer, bound with dynamic offsets; resources are
   bound as bind groups made at the draw that needs them.

   Compiled inside SDL's own build (SDL3-static), for its internal headers.
   Copyright the Goose authors; Apache 2.0, as the rest of the compiler. */

/* With SDL's src/ on the include path (the build adds it). */
#include "SDL_internal.h"
#include "gpu/SDL_sysgpu.h"
#include "video/SDL_sysvideo.h"
#include "video/emscripten/SDL_emscriptenvideo.h"

#include <stdint.h>
#include <stdio.h>

/* gfx_blob.h's web payload, kept in step with the compiler's copy. */
#pragma pack(push, 1)
typedef struct {
    char magic[4];
    uint32_t version;
    uint32_t num_bindings;
    uint32_t wgsl_size;
} WG_PayloadHeader;

typedef struct {
    uint8_t group, binding, slot, kind, dim, sample_type, comparison, access, store_binding;
    uint8_t pad[3];
    char format[20];
} WG_Binding;
#pragma pack(pop)

enum { WG_SAMPLED = 0, WG_SAMPLER = 1, WG_STORAGE_TEXTURE = 2, WG_STORAGE_BUFFER = 3,
       WG_UNIFORM = 4, WG_SPLIT_LOAD = 5 };

/* --- the JavaScript half (sdl_gpu_webgpu.js) -------------------------------- */

extern int wg_available(void);
extern int wg_init(int low_power);
extern int wg_has_feature(const char *name);
extern void wg_destroy(void);
extern void wg_release(int id);
extern int wg_buffer(Uint32 size, Uint32 usage);
extern int wg_texture(const char *json);
extern int wg_sampler(const char *json);
extern int wg_shader(const char *wgsl);
extern int wg_render_pipeline(const char *json);
extern int wg_compute_pipeline(const char *wgsl, const char *groups);
extern int wg_bind_group(int enc, int pipe, int group, int n, const Uint32 *words);
extern int wg_canvas(const char *selector);
extern int wg_canvas_format(void);
extern int wg_acquire(int canvas, int wait, Uint32 *size);
extern int wg_encoder(void);
extern int wg_submit(int enc, int cancel);
extern int wg_fence_done(int fence);
extern int wg_fence_wait(int fence);
extern int wg_idle(void);
extern Uint32 wg_uniform(const void *data, Uint32 len);
extern int wg_render_pass(int enc, const char *json);
extern void wg_pass_end(int pass);
extern void wg_set_pipeline(int pass, int pipe);
extern void wg_set_viewport(int pass, float x, float y, float w, float h, float mn, float mx);
extern void wg_set_scissor(int pass, Uint32 x, Uint32 y, Uint32 w, Uint32 h);
extern void wg_set_blend(int pass, float r, float g, float b, float a);
extern void wg_set_stencil(int pass, Uint32 ref);
extern void wg_set_vertex_buffer(int pass, Uint32 slot, int buf, Uint32 offset);
extern void wg_set_index_buffer(int pass, int buf, int wide, Uint32 offset);
extern void wg_set_bind_group(int pass, int enc, int group, int bg, int n, const Uint32 *offs);
extern void wg_draw(int pass, Uint32 n, Uint32 inst, Uint32 first, Uint32 first_inst);
extern void wg_draw_indexed(int pass, Uint32 n, Uint32 inst, Uint32 first, Sint32 base,
                            Uint32 first_inst);
extern void wg_draw_indirect(int pass, int buf, Uint32 offset, int indexed);
extern int wg_compute_pass(int enc);
extern void wg_dispatch(int pass, Uint32 x, Uint32 y, Uint32 z);
extern void wg_dispatch_indirect(int pass, int buf, Uint32 offset);
extern void wg_upload_buffer(int enc, int dst, Uint32 dst_off, const void *src, Uint32 size);
extern void wg_upload_texture(int enc, int dst, Uint32 mip, Uint32 x, Uint32 y, Uint32 z, Uint32 w,
                              Uint32 h, Uint32 d, const void *src, Uint32 pitch, Uint32 row_bytes,
                              Uint32 rows);
extern void wg_copy_buffer(int enc, int src, Uint32 so, int dst, Uint32 doff, Uint32 size);
extern void wg_copy_texture(int enc, int src, Uint32 smip, Uint32 sx, Uint32 sy, Uint32 sz, int dst,
                            Uint32 dmip, Uint32 dx, Uint32 dy, Uint32 dz, Uint32 w, Uint32 h,
                            Uint32 d);
extern void wg_download_buffer(int enc, int src, Uint32 so, Uint32 size, void *dst);
extern void wg_download_texture(int enc, int src, Uint32 mip, Uint32 x, Uint32 y, Uint32 z, Uint32 w,
                                Uint32 h, Uint32 d, void *dst, Uint32 pitch, Uint32 row_bytes,
                                Uint32 rows);
extern void wg_blit(int enc, const char *json);
extern void wg_mipmaps(int enc, int tex);

/* --- objects ---------------------------------------------------------------- */

typedef struct WG_Renderer WG_Renderer;

typedef struct {
    int module;
    SDL_GPUShaderStage stage;
    Uint32 num_bindings;
    WG_Binding *bindings;
} WG_Shader;

typedef struct {
    TextureCommonHeader header;
    int id;
    bool swapchain;
} WG_Texture;

typedef struct {
    int id;
    Uint32 size;
} WG_Buffer;

typedef struct {
    Uint8 *mem;
    Uint32 size;
    SDL_GPUTransferBufferUsage usage;
} WG_TransferBuffer;

typedef struct {
    int id;
} WG_Sampler;

/* A pipeline's bind groups, by WebGPU group: what each binding takes. */
#define WG_MAX_GROUPS 4
#define WG_MAX_BINDINGS 48
typedef struct {
    Uint32 n;
    WG_Binding b[WG_MAX_BINDINGS];
    Uint32 nsamplers, nstorage_textures;   /* where storage textures and buffers start */
    bool uniforms;
} WG_Group;

typedef struct {
    GraphicsPipelineCommonHeader header;
    int id;
    Uint32 ngroups;
    WG_Group groups[WG_MAX_GROUPS];
} WG_GraphicsPipeline;

typedef struct {
    ComputePipelineCommonHeader header;
    int id;
    Uint32 ngroups;
    WG_Group groups[WG_MAX_GROUPS];
} WG_ComputePipeline;

typedef struct {
    int id;
} WG_Fence;

typedef struct {
    SDL_Window *window;
    int canvas;
    WG_Texture texture;
} WG_Window;

/* What a stage has bound, by SDL_GPU slot. */
typedef struct {
    WG_Texture *sampler_textures[MAX_TEXTURE_SAMPLERS_PER_STAGE];
    WG_Sampler *samplers[MAX_TEXTURE_SAMPLERS_PER_STAGE];
    WG_Texture *storage_textures[MAX_STORAGE_TEXTURES_PER_STAGE];
    WG_Buffer *storage_buffers[MAX_STORAGE_BUFFERS_PER_STAGE];
    Uint32 uniform_offsets[MAX_UNIFORM_BUFFERS_PER_STAGE];
} WG_Stage;

typedef struct {
    CommandBufferCommonHeader common;
    WG_Renderer *renderer;
    int enc;
    int pass, cpass;
    WG_GraphicsPipeline *graphics;
    WG_ComputePipeline *compute;
    WG_Stage stages[3];                    /* vertex, fragment, compute */
    WG_Texture *rw_textures[MAX_COMPUTE_WRITE_TEXTURES];
    Uint32 rw_texture_mips[MAX_COMPUTE_WRITE_TEXTURES];
    WG_Buffer *rw_buffers[MAX_COMPUTE_WRITE_BUFFERS];
    bool dirty[WG_MAX_GROUPS];
    int groups[WG_MAX_GROUPS];             /* the bind group each group has, or -1 */
} WG_CommandBuffer;

struct WG_Renderer {
    SDL_GPUDevice *device;
    WG_Window **windows;
    int nwindows, windows_cap;
    bool rgba_canvas;
};

#define WG_VERTEX 0
#define WG_FRAGMENT 1
#define WG_COMPUTE 2

/* --- names WebGPU gives what SDL_GPU numbers ---------------------------------- */

static const char *WG_TextureFormat(SDL_GPUTextureFormat f) {
    switch (f) {
    case SDL_GPU_TEXTUREFORMAT_A8_UNORM: return NULL;
    case SDL_GPU_TEXTUREFORMAT_R8_UNORM: return "r8unorm";
    case SDL_GPU_TEXTUREFORMAT_R8G8_UNORM: return "rg8unorm";
    case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM: return "rgba8unorm";
    case SDL_GPU_TEXTUREFORMAT_R16_UNORM: return NULL;
    case SDL_GPU_TEXTUREFORMAT_R10G10B10A2_UNORM: return "rgb10a2unorm";
    case SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM: return "bgra8unorm";
    case SDL_GPU_TEXTUREFORMAT_R8_SNORM: return "r8snorm";
    case SDL_GPU_TEXTUREFORMAT_R8G8_SNORM: return "rg8snorm";
    case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_SNORM: return "rgba8snorm";
    case SDL_GPU_TEXTUREFORMAT_R16_FLOAT: return "r16float";
    case SDL_GPU_TEXTUREFORMAT_R16G16_FLOAT: return "rg16float";
    case SDL_GPU_TEXTUREFORMAT_R16G16B16A16_FLOAT: return "rgba16float";
    case SDL_GPU_TEXTUREFORMAT_R32_FLOAT: return "r32float";
    case SDL_GPU_TEXTUREFORMAT_R32G32_FLOAT: return "rg32float";
    case SDL_GPU_TEXTUREFORMAT_R32G32B32A32_FLOAT: return "rgba32float";
    case SDL_GPU_TEXTUREFORMAT_R11G11B10_UFLOAT: return "rg11b10ufloat";
    case SDL_GPU_TEXTUREFORMAT_R8_UINT: return "r8uint";
    case SDL_GPU_TEXTUREFORMAT_R8G8_UINT: return "rg8uint";
    case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UINT: return "rgba8uint";
    case SDL_GPU_TEXTUREFORMAT_R16_UINT: return "r16uint";
    case SDL_GPU_TEXTUREFORMAT_R16G16_UINT: return "rg16uint";
    case SDL_GPU_TEXTUREFORMAT_R16G16B16A16_UINT: return "rgba16uint";
    case SDL_GPU_TEXTUREFORMAT_R32_UINT: return "r32uint";
    case SDL_GPU_TEXTUREFORMAT_R32G32_UINT: return "rg32uint";
    case SDL_GPU_TEXTUREFORMAT_R32G32B32A32_UINT: return "rgba32uint";
    case SDL_GPU_TEXTUREFORMAT_R8_INT: return "r8sint";
    case SDL_GPU_TEXTUREFORMAT_R8G8_INT: return "rg8sint";
    case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_INT: return "rgba8sint";
    case SDL_GPU_TEXTUREFORMAT_R16_INT: return "r16sint";
    case SDL_GPU_TEXTUREFORMAT_R16G16_INT: return "rg16sint";
    case SDL_GPU_TEXTUREFORMAT_R16G16B16A16_INT: return "rgba16sint";
    case SDL_GPU_TEXTUREFORMAT_R32_INT: return "r32sint";
    case SDL_GPU_TEXTUREFORMAT_R32G32_INT: return "rg32sint";
    case SDL_GPU_TEXTUREFORMAT_R32G32B32A32_INT: return "rgba32sint";
    case SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB: return "rgba8unorm-srgb";
    case SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB: return "bgra8unorm-srgb";
    case SDL_GPU_TEXTUREFORMAT_D16_UNORM: return "depth16unorm";
    case SDL_GPU_TEXTUREFORMAT_D24_UNORM: return "depth24plus";
    case SDL_GPU_TEXTUREFORMAT_D32_FLOAT: return "depth32float";
    case SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT: return "depth24plus-stencil8";
    case SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT:
        return wg_has_feature("depth32float-stencil8") ? "depth32float-stencil8" : NULL;
    default: return NULL;
    }
}

static bool WG_IsDepthFormat(SDL_GPUTextureFormat f) {
    return f == SDL_GPU_TEXTUREFORMAT_D16_UNORM || f == SDL_GPU_TEXTUREFORMAT_D24_UNORM ||
           f == SDL_GPU_TEXTUREFORMAT_D32_FLOAT || f == SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT ||
           f == SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT;
}

static const char *WG_VertexFormat(SDL_GPUVertexElementFormat f) {
    switch (f) {
    case SDL_GPU_VERTEXELEMENTFORMAT_INT: return "sint32";
    case SDL_GPU_VERTEXELEMENTFORMAT_INT2: return "sint32x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_INT3: return "sint32x3";
    case SDL_GPU_VERTEXELEMENTFORMAT_INT4: return "sint32x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_UINT: return "uint32";
    case SDL_GPU_VERTEXELEMENTFORMAT_UINT2: return "uint32x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_UINT3: return "uint32x3";
    case SDL_GPU_VERTEXELEMENTFORMAT_UINT4: return "uint32x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_FLOAT: return "float32";
    case SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2: return "float32x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_FLOAT3: return "float32x3";
    case SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4: return "float32x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_BYTE2: return "sint8x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_BYTE4: return "sint8x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2: return "uint8x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4: return "uint8x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_BYTE2_NORM: return "snorm8x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_BYTE4_NORM: return "snorm8x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_UBYTE2_NORM: return "unorm8x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_UBYTE4_NORM: return "unorm8x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_SHORT2: return "sint16x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_SHORT4: return "sint16x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_USHORT2: return "uint16x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_USHORT4: return "uint16x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_SHORT2_NORM: return "snorm16x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_SHORT4_NORM: return "snorm16x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_USHORT2_NORM: return "unorm16x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_USHORT4_NORM: return "unorm16x4";
    case SDL_GPU_VERTEXELEMENTFORMAT_HALF2: return "float16x2";
    case SDL_GPU_VERTEXELEMENTFORMAT_HALF4: return "float16x4";
    default: return "float32";
    }
}

static const char *WG_Compare(SDL_GPUCompareOp op) {
    switch (op) {
    case SDL_GPU_COMPAREOP_NEVER: return "never";
    case SDL_GPU_COMPAREOP_LESS: return "less";
    case SDL_GPU_COMPAREOP_EQUAL: return "equal";
    case SDL_GPU_COMPAREOP_LESS_OR_EQUAL: return "less-equal";
    case SDL_GPU_COMPAREOP_GREATER: return "greater";
    case SDL_GPU_COMPAREOP_NOT_EQUAL: return "not-equal";
    case SDL_GPU_COMPAREOP_GREATER_OR_EQUAL: return "greater-equal";
    default: return "always";
    }
}

static const char *WG_StencilOp(SDL_GPUStencilOp op) {
    switch (op) {
    case SDL_GPU_STENCILOP_ZERO: return "zero";
    case SDL_GPU_STENCILOP_REPLACE: return "replace";
    case SDL_GPU_STENCILOP_INCREMENT_AND_CLAMP: return "increment-clamp";
    case SDL_GPU_STENCILOP_DECREMENT_AND_CLAMP: return "decrement-clamp";
    case SDL_GPU_STENCILOP_INVERT: return "invert";
    case SDL_GPU_STENCILOP_INCREMENT_AND_WRAP: return "increment-wrap";
    case SDL_GPU_STENCILOP_DECREMENT_AND_WRAP: return "decrement-wrap";
    default: return "keep";
    }
}

static const char *WG_BlendFactor(SDL_GPUBlendFactor f) {
    switch (f) {
    case SDL_GPU_BLENDFACTOR_ZERO: return "zero";
    case SDL_GPU_BLENDFACTOR_ONE: return "one";
    case SDL_GPU_BLENDFACTOR_SRC_COLOR: return "src";
    case SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR: return "one-minus-src";
    case SDL_GPU_BLENDFACTOR_DST_COLOR: return "dst";
    case SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR: return "one-minus-dst";
    case SDL_GPU_BLENDFACTOR_SRC_ALPHA: return "src-alpha";
    case SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_ALPHA: return "one-minus-src-alpha";
    case SDL_GPU_BLENDFACTOR_DST_ALPHA: return "dst-alpha";
    case SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_ALPHA: return "one-minus-dst-alpha";
    case SDL_GPU_BLENDFACTOR_CONSTANT_COLOR: return "constant";
    case SDL_GPU_BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR: return "one-minus-constant";
    case SDL_GPU_BLENDFACTOR_SRC_ALPHA_SATURATE: return "src-alpha-saturated";
    default: return "one";
    }
}

static const char *WG_BlendOp(SDL_GPUBlendOp op) {
    switch (op) {
    case SDL_GPU_BLENDOP_SUBTRACT: return "subtract";
    case SDL_GPU_BLENDOP_REVERSE_SUBTRACT: return "reverse-subtract";
    case SDL_GPU_BLENDOP_MIN: return "min";
    case SDL_GPU_BLENDOP_MAX: return "max";
    default: return "add";
    }
}

static const char *WG_Address(SDL_GPUSamplerAddressMode m) {
    switch (m) {
    case SDL_GPU_SAMPLERADDRESSMODE_MIRRORED_REPEAT: return "mirror-repeat";
    case SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE: return "clamp-to-edge";
    default: return "repeat";
    }
}

static const char *WG_Load(SDL_GPULoadOp op) {
    return op == SDL_GPU_LOADOP_LOAD ? "load" : "clear";
}

static const char *WG_Store(SDL_GPUStoreOp op) {
    return op == SDL_GPU_STOREOP_STORE || op == SDL_GPU_STOREOP_RESOLVE_AND_STORE ? "store"
                                                                                  : "discard";
}

/* --- a growing text, for the descriptions JS reads as JSON -------------------- */

typedef struct {
    char *s;
    size_t n, cap;
} WG_Text;

static void WG_Put(WG_Text *t, const char *fmt, ...) {
    va_list ap;
    for (;;) {
        va_start(ap, fmt);
        int k = SDL_vsnprintf(t->s ? t->s + t->n : NULL, t->s ? t->cap - t->n : 0, fmt, ap);
        va_end(ap);
        if (k < 0) return;
        if (t->s && t->n + (size_t)k < t->cap) {
            t->n += (size_t)k;
            return;
        }
        size_t cap = t->cap ? t->cap : 256;
        while (cap <= t->n + (size_t)k) cap *= 2;
        t->s = (char *)SDL_realloc(t->s, cap);
        t->cap = cap;
        if (!t->n) t->s[0] = 0;
    }
}

/* --- the device ------------------------------------------------------------------ */

static void WEBGPU_DestroyDevice(SDL_GPUDevice *device) {
    WG_Renderer *r = (WG_Renderer *)device->driverData;
    for (int i = 0; i < r->nwindows; i++) SDL_free(r->windows[i]);
    SDL_free(r->windows);
    SDL_free(r);
    SDL_free(device);
    wg_destroy();
}

static SDL_PropertiesID WEBGPU_GetDeviceProperties(SDL_GPUDevice *device) {
    (void)device;
    SDL_PropertiesID props = SDL_CreateProperties();
    SDL_SetStringProperty(props, SDL_PROP_GPU_DEVICE_NAME_STRING, "WebGPU");
    SDL_SetStringProperty(props, SDL_PROP_GPU_DEVICE_DRIVER_NAME_STRING, "webgpu");
    return props;
}

/* --- shaders ------------------------------------------------------------------------ */

/* The payload of a shader's code (gfx_blob.h): its bindings and WGSL. */
static bool WG_ReadPayload(const Uint8 *code, size_t size, WG_Binding **bindings, Uint32 *n,
                           const char **wgsl) {
    WG_PayloadHeader h;
    if (size < sizeof h) return SDL_SetError("WebGPU: a shader without its WGSL payload");
    SDL_memcpy(&h, code, sizeof h);
    if (SDL_memcmp(h.magic, "GSWG", 4) != 0)
        return SDL_SetError("WebGPU: a shader built for another target (rebuild the program "
                            "with goose build --target wasm64-web)");
    if (h.version != 1) return SDL_SetError("WebGPU: a shader payload of version %u", h.version);
    if (sizeof h + (size_t)h.num_bindings * sizeof(WG_Binding) + h.wgsl_size + 1 > size)
        return SDL_SetError("WebGPU: a damaged shader payload");
    *n = h.num_bindings;
    *bindings = (WG_Binding *)SDL_malloc(sizeof(WG_Binding) * (h.num_bindings ? h.num_bindings : 1));
    SDL_memcpy(*bindings, code + sizeof h, sizeof(WG_Binding) * h.num_bindings);
    *wgsl = (const char *)code + sizeof h + sizeof(WG_Binding) * h.num_bindings;
    for (Uint32 i = 0; i < h.num_bindings; i++)
        if ((*bindings)[i].kind == WG_SPLIT_LOAD) {
            SDL_free(*bindings);
            return SDL_SetError("WebGPU: a storage image both read and written, which this "
                                "backend cannot bind yet");
        }
    return true;
}

static SDL_GPUShader *WEBGPU_CreateShader(SDL_GPURenderer *driverData,
                                          const SDL_GPUShaderCreateInfo *ci) {
    (void)driverData;
    WG_Shader *s = (WG_Shader *)SDL_calloc(1, sizeof *s);
    const char *wgsl;
    if (!WG_ReadPayload(ci->code, ci->code_size, &s->bindings, &s->num_bindings, &wgsl)) {
        SDL_free(s);
        return NULL;
    }
    s->stage = ci->stage;
    s->module = wg_shader(wgsl);
    return (SDL_GPUShader *)s;
}

static void WEBGPU_ReleaseShader(SDL_GPURenderer *driverData, SDL_GPUShader *shader) {
    (void)driverData;
    WG_Shader *s = (WG_Shader *)shader;
    wg_release(s->module);
    SDL_free(s->bindings);
    SDL_free(s);
}

/* A shader's bindings added to a pipeline's groups. */
static void WG_AddBindings(Uint32 *ngroups, WG_Group *groups, const WG_Binding *b, Uint32 n) {
    for (Uint32 i = 0; i < n; i++) {
        if (b[i].group >= WG_MAX_GROUPS) continue;
        WG_Group *g = &groups[b[i].group];
        if (g->n == WG_MAX_BINDINGS) continue;
        g->b[g->n++] = b[i];
        if (b[i].kind == WG_SAMPLER) g->nsamplers++;
        if (b[i].kind == WG_STORAGE_TEXTURE) g->nstorage_textures++;
        if (b[i].kind == WG_UNIFORM) g->uniforms = true;
        if (b[i].group + 1u > *ngroups) *ngroups = b[i].group + 1u;
    }
}

/* Bindings sorted by number, which is the order dynamic offsets go in. */
static void WG_SortGroup(WG_Group *g) {
    for (Uint32 i = 1; i < g->n; i++)
        for (Uint32 j = i; j > 0 && g->b[j - 1].binding > g->b[j].binding; j--) {
            WG_Binding t = g->b[j];
            g->b[j] = g->b[j - 1];
            g->b[j - 1] = t;
        }
}

/* The groups as JSON: an array of arrays of bindings. */
static void WG_GroupsJson(WG_Text *t, Uint32 ngroups, const WG_Group *groups, const int *vis) {
    WG_Put(t, "[");
    for (Uint32 g = 0; g < ngroups; g++) {
        WG_Put(t, "%s[", g ? "," : "");
        for (Uint32 i = 0; i < groups[g].n; i++) {
            const WG_Binding *b = &groups[g].b[i];
            WG_Put(t, "%s{\"binding\":%u,\"kind\":%u,\"dim\":%u,\"st\":%u,\"cmp\":%u,\"access\":%u,"
                      "\"format\":\"%s\",\"vis\":%d}",
                   i ? "," : "", b->binding, b->kind, b->dim, b->sample_type, b->comparison,
                   b->access, b->format, vis[g]);
        }
        WG_Put(t, "]");
    }
    WG_Put(t, "]");
}

/* --- pipelines ------------------------------------------------------------------------ */

static SDL_GPUGraphicsPipeline *WEBGPU_CreateGraphicsPipeline(
    SDL_GPURenderer *driverData, const SDL_GPUGraphicsPipelineCreateInfo *ci) {
    (void)driverData;
    WG_Shader *vs = (WG_Shader *)ci->vertex_shader, *fs = (WG_Shader *)ci->fragment_shader;
    WG_GraphicsPipeline *p = (WG_GraphicsPipeline *)SDL_calloc(1, sizeof *p);
    /* SDL_GPU's graphics sets: 0 and 1 the vertex stage's, 2 and 3 the
       fragment stage's, which is what the WGSL's groups are. */
    p->ngroups = 4;
    WG_AddBindings(&p->ngroups, p->groups, vs->bindings, vs->num_bindings);
    WG_AddBindings(&p->ngroups, p->groups, fs->bindings, fs->num_bindings);
    for (int g = 0; g < WG_MAX_GROUPS; g++) WG_SortGroup(&p->groups[g]);
    int vis[4] = { 1, 1, 2, 2 };

    WG_Text t = { 0 };
    WG_Put(&t, "{\"vs\":%d,\"fs\":%d,\"groups\":", vs->module, fs->module);
    WG_GroupsJson(&t, 4, p->groups, vis);
    WG_Put(&t, ",\"pipe\":{\"vertex\":{\"entryPoint\":\"main\",\"buffers\":[");
    const SDL_GPUVertexInputState *vi = &ci->vertex_input_state;
    Uint32 nslots = 0;
    for (Uint32 i = 0; i < vi->num_vertex_buffers; i++)
        if (vi->vertex_buffer_descriptions[i].slot + 1 > nslots)
            nslots = vi->vertex_buffer_descriptions[i].slot + 1;
    for (Uint32 s = 0; s < nslots; s++) {
        const SDL_GPUVertexBufferDescription *d = NULL;
        for (Uint32 i = 0; i < vi->num_vertex_buffers; i++)
            if (vi->vertex_buffer_descriptions[i].slot == s) d = &vi->vertex_buffer_descriptions[i];
        if (!d) {
            WG_Put(&t, "%snull", s ? "," : "");
            continue;
        }
        WG_Put(&t, "%s{\"arrayStride\":%u,\"stepMode\":\"%s\",\"attributes\":[", s ? "," : "",
               d->pitch, d->input_rate == SDL_GPU_VERTEXINPUTRATE_INSTANCE ? "instance" : "vertex");
        bool firstattr = true;
        for (Uint32 a = 0; a < vi->num_vertex_attributes; a++) {
            const SDL_GPUVertexAttribute *at = &vi->vertex_attributes[a];
            if (at->buffer_slot != s) continue;
            WG_Put(&t, "%s{\"shaderLocation\":%u,\"offset\":%u,\"format\":\"%s\"}",
                   firstattr ? "" : ",", at->location, at->offset, WG_VertexFormat(at->format));
            firstattr = false;
        }
        WG_Put(&t, "]}");
    }
    WG_Put(&t, "]}");

    const char *topology;
    switch (ci->primitive_type) {
    case SDL_GPU_PRIMITIVETYPE_TRIANGLESTRIP: topology = "triangle-strip"; break;
    case SDL_GPU_PRIMITIVETYPE_LINELIST: topology = "line-list"; break;
    case SDL_GPU_PRIMITIVETYPE_LINESTRIP: topology = "line-strip"; break;
    case SDL_GPU_PRIMITIVETYPE_POINTLIST: topology = "point-list"; break;
    default: topology = "triangle-list"; break;
    }
    const SDL_GPURasterizerState *rs = &ci->rasterizer_state;
    WG_Put(&t, ",\"primitive\":{\"topology\":\"%s\",\"frontFace\":\"%s\",\"cullMode\":\"%s\"}",
           topology, rs->front_face == SDL_GPU_FRONTFACE_CLOCKWISE ? "cw" : "ccw",
           rs->cull_mode == SDL_GPU_CULLMODE_FRONT ? "front"
           : rs->cull_mode == SDL_GPU_CULLMODE_BACK ? "back" : "none");
    const SDL_GPUMultisampleState *ms = &ci->multisample_state;
    int samples = ms->sample_count == SDL_GPU_SAMPLECOUNT_1 ? 1 : 4;
    WG_Put(&t, ",\"multisample\":{\"count\":%d,\"mask\":%u,\"alphaToCoverageEnabled\":%s}",
           samples, ms->enable_mask ? ms->sample_mask : 0xFFFFFFFFu,
           ms->enable_alpha_to_coverage ? "true" : "false");
    const SDL_GPUGraphicsPipelineTargetInfo *ti = &ci->target_info;
    if (ti->has_depth_stencil_target) {
        const SDL_GPUDepthStencilState *ds = &ci->depth_stencil_state;
        const char *fmt = WG_TextureFormat(ti->depth_stencil_format);
        WG_Put(&t, ",\"depthStencil\":{\"format\":\"%s\",\"depthWriteEnabled\":%s,"
                   "\"depthCompare\":\"%s\"",
               fmt ? fmt : "depth32float",
               ds->enable_depth_test && ds->enable_depth_write ? "true" : "false",
               ds->enable_depth_test ? WG_Compare(ds->compare_op) : "always");
        if (ds->enable_stencil_test) {
            const SDL_GPUStencilOpState *f = &ds->front_stencil_state, *b = &ds->back_stencil_state;
            WG_Put(&t, ",\"stencilReadMask\":%u,\"stencilWriteMask\":%u,"
                       "\"stencilFront\":{\"compare\":\"%s\",\"failOp\":\"%s\",\"depthFailOp\":\"%s\","
                       "\"passOp\":\"%s\"},\"stencilBack\":{\"compare\":\"%s\",\"failOp\":\"%s\","
                       "\"depthFailOp\":\"%s\",\"passOp\":\"%s\"}",
                   ds->compare_mask, ds->write_mask, WG_Compare(f->compare_op),
                   WG_StencilOp(f->fail_op), WG_StencilOp(f->depth_fail_op),
                   WG_StencilOp(f->pass_op), WG_Compare(b->compare_op), WG_StencilOp(b->fail_op),
                   WG_StencilOp(b->depth_fail_op), WG_StencilOp(b->pass_op));
        }
        if (rs->enable_depth_bias)
            WG_Put(&t, ",\"depthBias\":%d,\"depthBiasSlopeScale\":%g,\"depthBiasClamp\":%g",
                   (int)rs->depth_bias_constant_factor, (double)rs->depth_bias_slope_factor,
                   (double)rs->depth_bias_clamp);
        WG_Put(&t, "}");
    }
    WG_Put(&t, ",\"fragment\":{\"entryPoint\":\"main\",\"targets\":[");
    for (Uint32 i = 0; i < ti->num_color_targets; i++) {
        const SDL_GPUColorTargetDescription *c = &ti->color_target_descriptions[i];
        const SDL_GPUColorTargetBlendState *bs = &c->blend_state;
        const char *fmt = WG_TextureFormat(c->format);
        unsigned mask = bs->enable_color_write_mask ? (unsigned)bs->color_write_mask : 0xFu;
        WG_Put(&t, "%s{\"format\":\"%s\",\"writeMask\":%u", i ? "," : "", fmt ? fmt : "rgba8unorm",
               mask);
        if (bs->enable_blend)
            WG_Put(&t, ",\"blend\":{\"color\":{\"srcFactor\":\"%s\",\"dstFactor\":\"%s\","
                       "\"operation\":\"%s\"},\"alpha\":{\"srcFactor\":\"%s\",\"dstFactor\":\"%s\","
                       "\"operation\":\"%s\"}}",
                   WG_BlendFactor(bs->src_color_blendfactor), WG_BlendFactor(bs->dst_color_blendfactor),
                   WG_BlendOp(bs->color_blend_op), WG_BlendFactor(bs->src_alpha_blendfactor),
                   WG_BlendFactor(bs->dst_alpha_blendfactor), WG_BlendOp(bs->alpha_blend_op));
        WG_Put(&t, "}");
    }
    WG_Put(&t, "]}}}");
    p->id = wg_render_pipeline(t.s);
    SDL_free(t.s);
    if (!p->id) {
        SDL_free(p);
        SDL_SetError("WebGPU: creating a graphics pipeline failed");
        return NULL;
    }
    return (SDL_GPUGraphicsPipeline *)p;
}

static SDL_GPUComputePipeline *WEBGPU_CreateComputePipeline(
    SDL_GPURenderer *driverData, const SDL_GPUComputePipelineCreateInfo *ci) {
    (void)driverData;
    WG_Binding *b;
    Uint32 n;
    const char *wgsl;
    if (!WG_ReadPayload(ci->code, ci->code_size, &b, &n, &wgsl)) return NULL;
    WG_ComputePipeline *p = (WG_ComputePipeline *)SDL_calloc(1, sizeof *p);
    /* SDL_GPU's compute sets: 0 read-only resources, 1 read-write ones, 2
       uniforms. */
    p->ngroups = 3;
    WG_AddBindings(&p->ngroups, p->groups, b, n);
    for (int g = 0; g < WG_MAX_GROUPS; g++) WG_SortGroup(&p->groups[g]);
    SDL_free(b);
    int vis[4] = { 4, 4, 4, 4 };
    WG_Text t = { 0 };
    WG_GroupsJson(&t, p->ngroups, p->groups, vis);
    p->id = wg_compute_pipeline(wgsl, t.s);
    SDL_free(t.s);
    if (!p->id) {
        SDL_free(p);
        SDL_SetError("WebGPU: creating a compute pipeline failed");
        return NULL;
    }
    return (SDL_GPUComputePipeline *)p;
}

static void WEBGPU_ReleaseGraphicsPipeline(SDL_GPURenderer *driverData,
                                           SDL_GPUGraphicsPipeline *pipeline) {
    (void)driverData;
    WG_GraphicsPipeline *p = (WG_GraphicsPipeline *)pipeline;
    wg_release(p->id);
    SDL_free(p);
}

static void WEBGPU_ReleaseComputePipeline(SDL_GPURenderer *driverData,
                                          SDL_GPUComputePipeline *pipeline) {
    (void)driverData;
    WG_ComputePipeline *p = (WG_ComputePipeline *)pipeline;
    wg_release(p->id);
    SDL_free(p);
}

/* --- resources ---------------------------------------------------------------------- */

static SDL_GPUSampler *WEBGPU_CreateSampler(SDL_GPURenderer *driverData,
                                            const SDL_GPUSamplerCreateInfo *ci) {
    (void)driverData;
    WG_Text t = { 0 };
    bool linear = ci->min_filter == SDL_GPU_FILTER_LINEAR && ci->mag_filter == SDL_GPU_FILTER_LINEAR &&
                  ci->mipmap_mode == SDL_GPU_SAMPLERMIPMAPMODE_LINEAR;
    WG_Put(&t, "{\"addressModeU\":\"%s\",\"addressModeV\":\"%s\",\"addressModeW\":\"%s\","
               "\"magFilter\":\"%s\",\"minFilter\":\"%s\",\"mipmapFilter\":\"%s\","
               "\"lodMinClamp\":%g,\"lodMaxClamp\":%g",
           WG_Address(ci->address_mode_u), WG_Address(ci->address_mode_v),
           WG_Address(ci->address_mode_w), ci->mag_filter == SDL_GPU_FILTER_LINEAR ? "linear" : "nearest",
           ci->min_filter == SDL_GPU_FILTER_LINEAR ? "linear" : "nearest",
           ci->mipmap_mode == SDL_GPU_SAMPLERMIPMAPMODE_LINEAR ? "linear" : "nearest",
           (double)ci->min_lod, (double)(ci->max_lod < 32.0f ? ci->max_lod : 32.0f));
    if (ci->enable_compare) WG_Put(&t, ",\"compare\":\"%s\"", WG_Compare(ci->compare_op));
    if (ci->enable_anisotropy && linear && ci->max_anisotropy > 1.0f)
        WG_Put(&t, ",\"maxAnisotropy\":%d", (int)(ci->max_anisotropy < 16.0f ? ci->max_anisotropy : 16.0f));
    WG_Put(&t, "}");
    WG_Sampler *s = (WG_Sampler *)SDL_calloc(1, sizeof *s);
    s->id = wg_sampler(t.s);
    SDL_free(t.s);
    return (SDL_GPUSampler *)s;
}

static void WEBGPU_ReleaseSampler(SDL_GPURenderer *driverData, SDL_GPUSampler *sampler) {
    (void)driverData;
    WG_Sampler *s = (WG_Sampler *)sampler;
    wg_release(s->id);
    SDL_free(s);
}

static SDL_GPUTexture *WEBGPU_CreateTexture(SDL_GPURenderer *driverData,
                                            const SDL_GPUTextureCreateInfo *ci) {
    (void)driverData;
    const char *format = WG_TextureFormat(ci->format);
    if (!format) {
        SDL_SetError("WebGPU: a texture format WebGPU does not have");
        return NULL;
    }
    SDL_GPUTextureUsageFlags u = ci->usage;
    bool sampled = (u & (SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ |
                         SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ)) != 0;
    bool target = (u & (SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) != 0;
    /* Mipmaps are made by drawing each level from the one above. */
    if (ci->num_levels > 1 && (u & SDL_GPU_TEXTUREUSAGE_SAMPLER) && !WG_IsDepthFormat(ci->format))
        target = true;
    bool storage = (u & (SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ |
                         SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ |
                         SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE |
                         SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE)) != 0;
    Uint32 layers = ci->layer_count_or_depth ? ci->layer_count_or_depth : 1;
    WG_Text t = { 0 };
    WG_Put(&t, "{\"format\":\"%s\",\"w\":%u,\"h\":%u,\"layers\":%u,\"dim\":\"%s\",\"mips\":%u,"
               "\"samples\":%d,\"sampled\":%s,\"target\":%s,\"storage\":%s,\"cube\":%s}",
           format, ci->width, ci->height, layers, ci->type == SDL_GPU_TEXTURETYPE_3D ? "3d" : "2d",
           ci->num_levels ? ci->num_levels : 1, ci->sample_count == SDL_GPU_SAMPLECOUNT_1 ? 1 : 4,
           sampled ? "true" : "false", target ? "true" : "false", storage ? "true" : "false",
           ci->type == SDL_GPU_TEXTURETYPE_CUBE || ci->type == SDL_GPU_TEXTURETYPE_CUBE_ARRAY
               ? "true" : "false");
    WG_Texture *tex = (WG_Texture *)SDL_calloc(1, sizeof *tex);
    tex->header.info = *ci;
    tex->id = wg_texture(t.s);
    SDL_free(t.s);
    return (SDL_GPUTexture *)tex;
}

static void WEBGPU_ReleaseTexture(SDL_GPURenderer *driverData, SDL_GPUTexture *texture) {
    (void)driverData;
    WG_Texture *t = (WG_Texture *)texture;
    if (t->swapchain) return;
    wg_release(t->id);
    SDL_free(t);
}

static SDL_GPUBuffer *WEBGPU_CreateBuffer(SDL_GPURenderer *driverData, SDL_GPUBufferUsageFlags usage,
                                          Uint32 size, const char *debugName) {
    (void)driverData;
    (void)debugName;
    Uint32 u = 0;
    if (usage & SDL_GPU_BUFFERUSAGE_VERTEX) u |= 1;
    if (usage & SDL_GPU_BUFFERUSAGE_INDEX) u |= 2;
    if (usage & SDL_GPU_BUFFERUSAGE_INDIRECT) u |= 4;
    if (usage & (SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ | SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ |
                 SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE))
        u |= 8;
    WG_Buffer *b = (WG_Buffer *)SDL_calloc(1, sizeof *b);
    b->id = wg_buffer(size, u);
    b->size = size;
    return (SDL_GPUBuffer *)b;
}

static void WEBGPU_ReleaseBuffer(SDL_GPURenderer *driverData, SDL_GPUBuffer *buffer) {
    (void)driverData;
    WG_Buffer *b = (WG_Buffer *)buffer;
    wg_release(b->id);
    SDL_free(b);
}

/* A transfer buffer is the program's own memory: mapping it is handing out
   the pointer, once every download into it has landed. */
static SDL_GPUTransferBuffer *WEBGPU_CreateTransferBuffer(SDL_GPURenderer *driverData,
                                                          SDL_GPUTransferBufferUsage usage,
                                                          Uint32 size, const char *debugName) {
    (void)driverData;
    (void)debugName;
    WG_TransferBuffer *t = (WG_TransferBuffer *)SDL_calloc(1, sizeof *t);
    t->mem = (Uint8 *)SDL_calloc(1, size ? size : 1);
    t->size = size;
    t->usage = usage;
    return (SDL_GPUTransferBuffer *)t;
}

static void WEBGPU_ReleaseTransferBuffer(SDL_GPURenderer *driverData,
                                         SDL_GPUTransferBuffer *transferBuffer) {
    (void)driverData;
    WG_TransferBuffer *t = (WG_TransferBuffer *)transferBuffer;
    SDL_free(t->mem);
    SDL_free(t);
}

static void *WEBGPU_MapTransferBuffer(SDL_GPURenderer *driverData, SDL_GPUTransferBuffer *transferBuffer,
                                      bool cycle) {
    (void)driverData;
    (void)cycle;
    WG_TransferBuffer *t = (WG_TransferBuffer *)transferBuffer;
    if (t->usage == SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD) wg_idle();
    return t->mem;
}

static void WEBGPU_UnmapTransferBuffer(SDL_GPURenderer *driverData,
                                       SDL_GPUTransferBuffer *transferBuffer) {
    (void)driverData;
    (void)transferBuffer;
}

static void WEBGPU_SetBufferName(SDL_GPURenderer *d, SDL_GPUBuffer *b, const char *t) {
    (void)d; (void)b; (void)t;
}
static void WEBGPU_SetTextureName(SDL_GPURenderer *d, SDL_GPUTexture *x, const char *t) {
    (void)d; (void)x; (void)t;
}
static void WEBGPU_InsertDebugLabel(SDL_GPUCommandBuffer *c, const char *t) { (void)c; (void)t; }
static void WEBGPU_PushDebugGroup(SDL_GPUCommandBuffer *c, const char *t) { (void)c; (void)t; }
static void WEBGPU_PopDebugGroup(SDL_GPUCommandBuffer *c) { (void)c; }

/* --- command buffers ------------------------------------------------------------------ */

static SDL_GPUCommandBuffer *WEBGPU_AcquireCommandBuffer(SDL_GPURenderer *driverData) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)SDL_calloc(1, sizeof *cb);
    cb->renderer = (WG_Renderer *)driverData;
    cb->enc = wg_encoder();
    for (int g = 0; g < WG_MAX_GROUPS; g++) cb->groups[g] = -1;
    return (SDL_GPUCommandBuffer *)cb;
}

static int WG_Submit(WG_CommandBuffer *cb, bool cancel) {
    int fence = wg_submit(cb->enc, cancel);
    SDL_free(cb);
    return fence;
}

static bool WEBGPU_Submit(SDL_GPUCommandBuffer *commandBuffer) {
    wg_release(WG_Submit((WG_CommandBuffer *)commandBuffer, false));
    return true;
}

static SDL_GPUFence *WEBGPU_SubmitAndAcquireFence(SDL_GPUCommandBuffer *commandBuffer) {
    WG_Fence *f = (WG_Fence *)SDL_calloc(1, sizeof *f);
    f->id = WG_Submit((WG_CommandBuffer *)commandBuffer, false);
    return (SDL_GPUFence *)f;
}

static bool WEBGPU_Cancel(SDL_GPUCommandBuffer *commandBuffer) {
    wg_release(WG_Submit((WG_CommandBuffer *)commandBuffer, true));
    return true;
}

static bool WEBGPU_Wait(SDL_GPURenderer *driverData) {
    (void)driverData;
    return wg_idle() != 0;
}

static bool WEBGPU_WaitForFences(SDL_GPURenderer *driverData, bool waitAll, SDL_GPUFence *const *fences,
                                 Uint32 numFences) {
    (void)driverData;
    (void)waitAll;
    for (Uint32 i = 0; i < numFences; i++) wg_fence_wait(((WG_Fence *)fences[i])->id);
    return true;
}

static bool WEBGPU_QueryFence(SDL_GPURenderer *driverData, SDL_GPUFence *fence) {
    (void)driverData;
    return wg_fence_done(((WG_Fence *)fence)->id) != 0;
}

static void WEBGPU_ReleaseFence(SDL_GPURenderer *driverData, SDL_GPUFence *fence) {
    (void)driverData;
    wg_release(((WG_Fence *)fence)->id);
    SDL_free(fence);
}

/* --- render passes ---------------------------------------------------------------------- */

static void WEBGPU_BeginRenderPass(SDL_GPUCommandBuffer *commandBuffer,
                                   const SDL_GPUColorTargetInfo *colorTargetInfos, Uint32 numColorTargets,
                                   const SDL_GPUDepthStencilTargetInfo *depth) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_Text t = { 0 };
    WG_Put(&t, "{\"color\":[");
    for (Uint32 i = 0; i < numColorTargets; i++) {
        const SDL_GPUColorTargetInfo *c = &colorTargetInfos[i];
        WG_Texture *tex = (WG_Texture *)c->texture;
        bool is3d = tex->header.info.type == SDL_GPU_TEXTURETYPE_3D;
        WG_Put(&t, "%s{\"tex\":%d,\"dim\":\"2d\",\"mip\":%u,\"layer\":%d,\"load\":\"%s\",\"store\":\"%s\","
                   "\"clear\":[%g,%g,%g,%g]",
               i ? "," : "", tex->id, c->mip_level, is3d || tex->swapchain ? -1 : (int)c->layer_or_depth_plane,
               WG_Load(c->load_op), WG_Store(c->store_op), (double)c->clear_color.r,
               (double)c->clear_color.g, (double)c->clear_color.b, (double)c->clear_color.a);
        if (is3d) WG_Put(&t, ",\"depthSlice\":%u", c->layer_or_depth_plane);
        if ((c->store_op == SDL_GPU_STOREOP_RESOLVE || c->store_op == SDL_GPU_STOREOP_RESOLVE_AND_STORE) &&
            c->resolve_texture)
            WG_Put(&t, ",\"resolve\":%d,\"rmip\":%u,\"rlayer\":%u",
                   ((WG_Texture *)c->resolve_texture)->id, c->resolve_mip_level, c->resolve_layer);
        WG_Put(&t, "}");
    }
    WG_Put(&t, "]");
    if (depth) {
        WG_Put(&t, ",\"depth\":{\"tex\":%d,\"mip\":%u,\"layer\":%u,\"load\":\"%s\",\"store\":\"%s\","
                   "\"clear\":%g,\"sload\":\"%s\",\"sstore\":\"%s\",\"sclear\":%u}",
               ((WG_Texture *)depth->texture)->id, depth->mip_level, depth->layer,
               WG_Load(depth->load_op), WG_Store(depth->store_op), (double)depth->clear_depth,
               WG_Load(depth->stencil_load_op), WG_Store(depth->stencil_store_op), depth->clear_stencil);
    }
    WG_Put(&t, "}");
    cb->pass = wg_render_pass(cb->enc, t.s);
    SDL_free(t.s);
    cb->graphics = NULL;
}

static void WEBGPU_EndRenderPass(SDL_GPUCommandBuffer *commandBuffer) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_pass_end(cb->pass);
    cb->pass = 0;
    cb->graphics = NULL;
    SDL_zeroa(cb->stages[WG_VERTEX].sampler_textures);
    SDL_zeroa(cb->stages[WG_FRAGMENT].sampler_textures);
}

static void WG_DirtyAll(WG_CommandBuffer *cb) {
    for (int g = 0; g < WG_MAX_GROUPS; g++) {
        cb->dirty[g] = true;
        cb->groups[g] = -1;
    }
}

static void WEBGPU_BindGraphicsPipeline(SDL_GPUCommandBuffer *commandBuffer,
                                        SDL_GPUGraphicsPipeline *graphicsPipeline) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    cb->graphics = (WG_GraphicsPipeline *)graphicsPipeline;
    wg_set_pipeline(cb->pass, cb->graphics->id);
    WG_DirtyAll(cb);
}

static void WEBGPU_SetViewport(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUViewport *v) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_set_viewport(cb->pass, v->x, v->y, v->w, v->h, v->min_depth, v->max_depth);
}

static void WEBGPU_SetScissor(SDL_GPUCommandBuffer *commandBuffer, const SDL_Rect *r) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_set_scissor(cb->pass, (Uint32)r->x, (Uint32)r->y, (Uint32)r->w, (Uint32)r->h);
}

static void WEBGPU_SetBlendConstants(SDL_GPUCommandBuffer *commandBuffer, SDL_FColor c) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_set_blend(cb->pass, c.r, c.g, c.b, c.a);
}

static void WEBGPU_SetStencilReference(SDL_GPUCommandBuffer *commandBuffer, Uint8 reference) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_set_stencil(cb->pass, reference);
}

static void WEBGPU_BindVertexBuffers(SDL_GPUCommandBuffer *commandBuffer, Uint32 firstSlot,
                                     const SDL_GPUBufferBinding *bindings, Uint32 numBindings) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    for (Uint32 i = 0; i < numBindings; i++)
        wg_set_vertex_buffer(cb->pass, firstSlot + i, ((WG_Buffer *)bindings[i].buffer)->id,
                             bindings[i].offset);
}

static void WEBGPU_BindIndexBuffer(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUBufferBinding *binding,
                                   SDL_GPUIndexElementSize size) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_set_index_buffer(cb->pass, ((WG_Buffer *)binding->buffer)->id,
                        size == SDL_GPU_INDEXELEMENTSIZE_32BIT, binding->offset);
}

/* The stage whose resources a group holds, and whether it holds uniforms:
   SDL_GPU's sets. */
static int WG_GroupStage(bool compute, int g) {
    if (compute) return WG_COMPUTE;
    return g < 2 ? WG_VERTEX : WG_FRAGMENT;
}

static void WG_BindSamplers(WG_CommandBuffer *cb, int stage, Uint32 firstSlot,
                            const SDL_GPUTextureSamplerBinding *b, Uint32 n) {
    for (Uint32 i = 0; i < n; i++) {
        cb->stages[stage].sampler_textures[firstSlot + i] = (WG_Texture *)b[i].texture;
        cb->stages[stage].samplers[firstSlot + i] = (WG_Sampler *)b[i].sampler;
    }
    WG_DirtyAll(cb);
}

static void WG_BindStorageTextures(WG_CommandBuffer *cb, int stage, Uint32 firstSlot,
                                   SDL_GPUTexture *const *t, Uint32 n) {
    for (Uint32 i = 0; i < n; i++) cb->stages[stage].storage_textures[firstSlot + i] = (WG_Texture *)t[i];
    WG_DirtyAll(cb);
}

static void WG_BindStorageBuffers(WG_CommandBuffer *cb, int stage, Uint32 firstSlot,
                                  SDL_GPUBuffer *const *b, Uint32 n) {
    for (Uint32 i = 0; i < n; i++) cb->stages[stage].storage_buffers[firstSlot + i] = (WG_Buffer *)b[i];
    WG_DirtyAll(cb);
}

static void WEBGPU_BindVertexSamplers(SDL_GPUCommandBuffer *c, Uint32 f,
                                      const SDL_GPUTextureSamplerBinding *b, Uint32 n) {
    WG_BindSamplers((WG_CommandBuffer *)c, WG_VERTEX, f, b, n);
}
static void WEBGPU_BindVertexStorageTextures(SDL_GPUCommandBuffer *c, Uint32 f, SDL_GPUTexture *const *t,
                                             Uint32 n) {
    WG_BindStorageTextures((WG_CommandBuffer *)c, WG_VERTEX, f, t, n);
}
static void WEBGPU_BindVertexStorageBuffers(SDL_GPUCommandBuffer *c, Uint32 f, SDL_GPUBuffer *const *b,
                                            Uint32 n) {
    WG_BindStorageBuffers((WG_CommandBuffer *)c, WG_VERTEX, f, b, n);
}
static void WEBGPU_BindFragmentSamplers(SDL_GPUCommandBuffer *c, Uint32 f,
                                        const SDL_GPUTextureSamplerBinding *b, Uint32 n) {
    WG_BindSamplers((WG_CommandBuffer *)c, WG_FRAGMENT, f, b, n);
}
static void WEBGPU_BindFragmentStorageTextures(SDL_GPUCommandBuffer *c, Uint32 f,
                                               SDL_GPUTexture *const *t, Uint32 n) {
    WG_BindStorageTextures((WG_CommandBuffer *)c, WG_FRAGMENT, f, t, n);
}
static void WEBGPU_BindFragmentStorageBuffers(SDL_GPUCommandBuffer *c, Uint32 f, SDL_GPUBuffer *const *b,
                                              Uint32 n) {
    WG_BindStorageBuffers((WG_CommandBuffer *)c, WG_FRAGMENT, f, b, n);
}
static void WEBGPU_BindComputeSamplers(SDL_GPUCommandBuffer *c, Uint32 f,
                                       const SDL_GPUTextureSamplerBinding *b, Uint32 n) {
    WG_BindSamplers((WG_CommandBuffer *)c, WG_COMPUTE, f, b, n);
}
static void WEBGPU_BindComputeStorageTextures(SDL_GPUCommandBuffer *c, Uint32 f,
                                              SDL_GPUTexture *const *t, Uint32 n) {
    WG_BindStorageTextures((WG_CommandBuffer *)c, WG_COMPUTE, f, t, n);
}
static void WEBGPU_BindComputeStorageBuffers(SDL_GPUCommandBuffer *c, Uint32 f, SDL_GPUBuffer *const *b,
                                             Uint32 n) {
    WG_BindStorageBuffers((WG_CommandBuffer *)c, WG_COMPUTE, f, b, n);
}

static void WG_PushUniforms(WG_CommandBuffer *cb, int stage, Uint32 slot, const void *data, Uint32 len) {
    if (slot >= MAX_UNIFORM_BUFFERS_PER_STAGE) return;
    cb->stages[stage].uniform_offsets[slot] = wg_uniform(data, len);
    /* The uniform group of the stage: its offsets change. */
    int g = stage == WG_VERTEX ? 1 : stage == WG_FRAGMENT ? 3 : 2;
    cb->dirty[g] = true;
}

static void WEBGPU_PushVertexUniformData(SDL_GPUCommandBuffer *c, Uint32 s, const void *d, Uint32 n) {
    WG_PushUniforms((WG_CommandBuffer *)c, WG_VERTEX, s, d, n);
}
static void WEBGPU_PushFragmentUniformData(SDL_GPUCommandBuffer *c, Uint32 s, const void *d, Uint32 n) {
    WG_PushUniforms((WG_CommandBuffer *)c, WG_FRAGMENT, s, d, n);
}
static void WEBGPU_PushComputeUniformData(SDL_GPUCommandBuffer *c, Uint32 s, const void *d, Uint32 n) {
    WG_PushUniforms((WG_CommandBuffer *)c, WG_COMPUTE, s, d, n);
}

/* Every group whose bindings or uniforms changed, bound for the next draw or
   dispatch: a bind group made for what is bound now, the uniform groups' at
   the offsets of the latest pushes. */
static void WG_FlushGroups(WG_CommandBuffer *cb, bool compute, int pass) {
    Uint32 ngroups = compute ? cb->compute->ngroups : cb->graphics->ngroups;
    WG_Group *groups = compute ? cb->compute->groups : cb->graphics->groups;
    int pipe = compute ? cb->compute->id : cb->graphics->id;
    for (Uint32 g = 0; g < ngroups; g++) {
        if (!cb->dirty[g]) continue;
        cb->dirty[g] = false;
        WG_Group *grp = &groups[g];
        WG_Stage *st = &cb->stages[WG_GroupStage(compute, (int)g)];
        bool rw = compute && g == 1;
        Uint32 words[WG_MAX_BINDINGS * 5], offs[MAX_UNIFORM_BUFFERS_PER_STAGE];
        int noffs = 0;
        for (Uint32 i = 0; i < grp->n; i++) {
            const WG_Binding *b = &grp->b[i];
            Uint32 *w = &words[i * 5];
            Uint32 slot = b->slot;
            w[0] = b->binding;
            w[1] = b->kind;
            w[2] = 0;
            w[3] = b->dim;
            w[4] = 0;
            switch (b->kind) {
            case WG_SAMPLED:
                if (slot < MAX_TEXTURE_SAMPLERS_PER_STAGE && st->sampler_textures[slot])
                    w[2] = (Uint32)st->sampler_textures[slot]->id;
                break;
            case WG_SAMPLER:
                if (slot < MAX_TEXTURE_SAMPLERS_PER_STAGE && st->samplers[slot])
                    w[2] = (Uint32)st->samplers[slot]->id;
                break;
            case WG_STORAGE_TEXTURE:
                if (rw) {
                    if (slot < MAX_COMPUTE_WRITE_TEXTURES && cb->rw_textures[slot]) {
                        w[2] = (Uint32)cb->rw_textures[slot]->id;
                        w[4] = cb->rw_texture_mips[slot] + 1;
                    }
                } else {
                    slot -= grp->nsamplers;
                    if (slot < MAX_STORAGE_TEXTURES_PER_STAGE && st->storage_textures[slot])
                        w[2] = (Uint32)st->storage_textures[slot]->id;
                }
                break;
            case WG_STORAGE_BUFFER:
                if (rw) {
                    slot -= grp->nstorage_textures;
                    if (slot < MAX_COMPUTE_WRITE_BUFFERS && cb->rw_buffers[slot])
                        w[2] = (Uint32)cb->rw_buffers[slot]->id;
                } else {
                    slot -= grp->nsamplers + grp->nstorage_textures;
                    if (slot < MAX_STORAGE_BUFFERS_PER_STAGE && st->storage_buffers[slot])
                        w[2] = (Uint32)st->storage_buffers[slot]->id;
                }
                break;
            case WG_UNIFORM:
                if (noffs < MAX_UNIFORM_BUFFERS_PER_STAGE)
                    offs[noffs++] = slot < MAX_UNIFORM_BUFFERS_PER_STAGE ? st->uniform_offsets[slot] : 0;
                break;
            }
        }
        /* A uniform group's bind group stays; only its offsets move. */
        if (cb->groups[g] < 0 || !grp->uniforms)
            cb->groups[g] = wg_bind_group(cb->enc, pipe, (int)g, (int)grp->n, words);
        wg_set_bind_group(pass, cb->enc, (int)g, cb->groups[g], noffs, offs);
    }
}

static void WEBGPU_DrawPrimitives(SDL_GPUCommandBuffer *commandBuffer, Uint32 numVertices,
                                  Uint32 numInstances, Uint32 firstVertex, Uint32 firstInstance) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_FlushGroups(cb, false, cb->pass);
    wg_draw(cb->pass, numVertices, numInstances, firstVertex, firstInstance);
}

static void WEBGPU_DrawIndexedPrimitives(SDL_GPUCommandBuffer *commandBuffer, Uint32 numIndices,
                                         Uint32 numInstances, Uint32 firstIndex, Sint32 vertexOffset,
                                         Uint32 firstInstance) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_FlushGroups(cb, false, cb->pass);
    wg_draw_indexed(cb->pass, numIndices, numInstances, firstIndex, vertexOffset, firstInstance);
}

static void WEBGPU_DrawPrimitivesIndirect(SDL_GPUCommandBuffer *commandBuffer, SDL_GPUBuffer *buffer,
                                          Uint32 offset, Uint32 drawCount) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_FlushGroups(cb, false, cb->pass);
    for (Uint32 i = 0; i < drawCount; i++)
        wg_draw_indirect(cb->pass, ((WG_Buffer *)buffer)->id, offset + i * 16, 0);
}

static void WEBGPU_DrawIndexedPrimitivesIndirect(SDL_GPUCommandBuffer *commandBuffer, SDL_GPUBuffer *buffer,
                                                 Uint32 offset, Uint32 drawCount) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_FlushGroups(cb, false, cb->pass);
    for (Uint32 i = 0; i < drawCount; i++)
        wg_draw_indirect(cb->pass, ((WG_Buffer *)buffer)->id, offset + i * 20, 1);
}

/* --- compute passes ---------------------------------------------------------------------- */

static void WEBGPU_BeginComputePass(SDL_GPUCommandBuffer *commandBuffer,
                                    const SDL_GPUStorageTextureReadWriteBinding *textures, Uint32 ntextures,
                                    const SDL_GPUStorageBufferReadWriteBinding *buffers, Uint32 nbuffers) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    SDL_zeroa(cb->rw_textures);
    SDL_zeroa(cb->rw_buffers);
    for (Uint32 i = 0; i < ntextures && i < MAX_COMPUTE_WRITE_TEXTURES; i++) {
        cb->rw_textures[i] = (WG_Texture *)textures[i].texture;
        cb->rw_texture_mips[i] = textures[i].mip_level;
    }
    for (Uint32 i = 0; i < nbuffers && i < MAX_COMPUTE_WRITE_BUFFERS; i++)
        cb->rw_buffers[i] = (WG_Buffer *)buffers[i].buffer;
    cb->cpass = wg_compute_pass(cb->enc);
    cb->compute = NULL;
}

static void WEBGPU_BindComputePipeline(SDL_GPUCommandBuffer *commandBuffer,
                                       SDL_GPUComputePipeline *computePipeline) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    cb->compute = (WG_ComputePipeline *)computePipeline;
    wg_set_pipeline(cb->cpass, cb->compute->id);
    WG_DirtyAll(cb);
}

static void WEBGPU_DispatchCompute(SDL_GPUCommandBuffer *commandBuffer, Uint32 x, Uint32 y, Uint32 z) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_FlushGroups(cb, true, cb->cpass);
    wg_dispatch(cb->cpass, x, y, z);
}

static void WEBGPU_DispatchComputeIndirect(SDL_GPUCommandBuffer *commandBuffer, SDL_GPUBuffer *buffer,
                                           Uint32 offset) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_FlushGroups(cb, true, cb->cpass);
    wg_dispatch_indirect(cb->cpass, ((WG_Buffer *)buffer)->id, offset);
}

static void WEBGPU_EndComputePass(SDL_GPUCommandBuffer *commandBuffer) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_pass_end(cb->cpass);
    cb->cpass = 0;
    cb->compute = NULL;
}

/* --- copies ------------------------------------------------------------------------------- */

static void WEBGPU_BeginCopyPass(SDL_GPUCommandBuffer *commandBuffer) { (void)commandBuffer; }
static void WEBGPU_EndCopyPass(SDL_GPUCommandBuffer *commandBuffer) { (void)commandBuffer; }

static void WEBGPU_UploadToBuffer(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUTransferBufferLocation *src,
                                  const SDL_GPUBufferRegion *dst, bool cycle) {
    (void)cycle;
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_TransferBuffer *t = (WG_TransferBuffer *)src->transfer_buffer;
    wg_upload_buffer(cb->enc, ((WG_Buffer *)dst->buffer)->id, dst->offset, t->mem + src->offset, dst->size);
}

/* The layout of a texture region in a transfer buffer: bytes per row of
   blocks, rows of blocks per layer. */
static void WG_TransferLayout(const SDL_GPUTextureTransferInfo *ti, const SDL_GPUTextureRegion *r,
                              Uint32 *pitch, Uint32 *row_bytes, Uint32 *rows) {
    SDL_GPUTextureFormat f = ((WG_Texture *)r->texture)->header.info.format;
    Uint32 block = SDL_GPUTextureFormatTexelBlockSize(f);
    Uint32 ppr = ti->pixels_per_row ? ti->pixels_per_row : r->w;
    Uint32 rpl = ti->rows_per_layer ? ti->rows_per_layer : r->h;
    *pitch = ppr * block;
    *row_bytes = r->w * block;
    *rows = rpl;
}

static void WEBGPU_UploadToTexture(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUTextureTransferInfo *src,
                                   const SDL_GPUTextureRegion *dst, bool cycle) {
    (void)cycle;
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_TransferBuffer *t = (WG_TransferBuffer *)src->transfer_buffer;
    Uint32 pitch, row_bytes, rows;
    WG_TransferLayout(src, dst, &pitch, &row_bytes, &rows);
    WG_Texture *tex = (WG_Texture *)dst->texture;
    bool is3d = tex->header.info.type == SDL_GPU_TEXTURETYPE_3D;
    wg_upload_texture(cb->enc, tex->id, dst->mip_level, dst->x, dst->y, is3d ? dst->z : dst->layer, dst->w,
                      dst->h, dst->d ? dst->d : 1, t->mem + src->offset, pitch, row_bytes, rows);
}

static void WEBGPU_CopyBufferToBuffer(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUBufferLocation *src,
                                      const SDL_GPUBufferLocation *dst, Uint32 size, bool cycle) {
    (void)cycle;
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_copy_buffer(cb->enc, ((WG_Buffer *)src->buffer)->id, src->offset, ((WG_Buffer *)dst->buffer)->id,
                   dst->offset, size);
}

static void WEBGPU_CopyTextureToTexture(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUTextureLocation *src,
                                        const SDL_GPUTextureLocation *dst, Uint32 w, Uint32 h, Uint32 d,
                                        bool cycle) {
    (void)cycle;
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_Texture *s = (WG_Texture *)src->texture, *t = (WG_Texture *)dst->texture;
    bool s3 = s->header.info.type == SDL_GPU_TEXTURETYPE_3D, t3 = t->header.info.type == SDL_GPU_TEXTURETYPE_3D;
    wg_copy_texture(cb->enc, s->id, src->mip_level, src->x, src->y, s3 ? src->z : src->layer, t->id,
                    dst->mip_level, dst->x, dst->y, t3 ? dst->z : dst->layer, w, h, d ? d : 1);
}

static void WEBGPU_DownloadFromBuffer(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUBufferRegion *src,
                                      const SDL_GPUTransferBufferLocation *dst) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_TransferBuffer *t = (WG_TransferBuffer *)dst->transfer_buffer;
    wg_download_buffer(cb->enc, ((WG_Buffer *)src->buffer)->id, src->offset, src->size, t->mem + dst->offset);
}

static void WEBGPU_DownloadFromTexture(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUTextureRegion *src,
                                       const SDL_GPUTextureTransferInfo *dst) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_TransferBuffer *t = (WG_TransferBuffer *)dst->transfer_buffer;
    Uint32 pitch, row_bytes, rows;
    WG_TransferLayout(dst, src, &pitch, &row_bytes, &rows);
    WG_Texture *tex = (WG_Texture *)src->texture;
    bool is3d = tex->header.info.type == SDL_GPU_TEXTURETYPE_3D;
    wg_download_texture(cb->enc, tex->id, src->mip_level, src->x, src->y, is3d ? src->z : src->layer, src->w,
                        src->h, src->d ? src->d : 1, t->mem + dst->offset, pitch, row_bytes, rows);
}

static void WEBGPU_GenerateMipmaps(SDL_GPUCommandBuffer *commandBuffer, SDL_GPUTexture *texture) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    wg_mipmaps(cb->enc, ((WG_Texture *)texture)->id);
}

static void WEBGPU_Blit(SDL_GPUCommandBuffer *commandBuffer, const SDL_GPUBlitInfo *info) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    const SDL_GPUBlitRegion *s = &info->source, *d = &info->destination;
    int flip = 0;
    if (info->flip_mode & SDL_FLIP_HORIZONTAL) flip |= 1;
    if (info->flip_mode & SDL_FLIP_VERTICAL) flip |= 2;
    WG_Text t = { 0 };
    WG_Put(&t, "{\"src\":%d,\"smip\":%u,\"slayer\":%u,\"sx\":%u,\"sy\":%u,\"sw\":%u,\"sh\":%u,"
               "\"dst\":%d,\"dmip\":%u,\"dlayer\":%u,\"dx\":%u,\"dy\":%u,\"dw\":%u,\"dh\":%u,"
               "\"flip\":%d,\"linear\":%s,\"load\":\"%s\",\"clear\":[%g,%g,%g,%g]}",
           ((WG_Texture *)s->texture)->id, s->mip_level, s->layer_or_depth_plane, s->x, s->y, s->w, s->h,
           ((WG_Texture *)d->texture)->id, d->mip_level, d->layer_or_depth_plane, d->x, d->y, d->w, d->h,
           flip, info->filter == SDL_GPU_FILTER_LINEAR ? "true" : "false",
           info->load_op == SDL_GPU_LOADOP_LOAD ? "load" : "clear", (double)info->clear_color.r,
           (double)info->clear_color.g, (double)info->clear_color.b, (double)info->clear_color.a);
    wg_blit(cb->enc, t.s);
    SDL_free(t.s);
}

/* --- windows ----------------------------------------------------------------------------- */

static WG_Window *WG_FindWindow(WG_Renderer *r, SDL_Window *window) {
    for (int i = 0; i < r->nwindows; i++)
        if (r->windows[i]->window == window) return r->windows[i];
    return NULL;
}

static SDL_GPUTextureFormat WG_SwapchainFormat(WG_Renderer *r) {
    return r->rgba_canvas ? SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM : SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM;
}

static bool WEBGPU_ClaimWindow(SDL_GPURenderer *driverData, SDL_Window *window) {
    WG_Renderer *r = (WG_Renderer *)driverData;
    if (WG_FindWindow(r, window)) return SDL_SetError("WebGPU: the window is claimed already");
    const char *selector = window->internal ? window->internal->canvas_id : NULL;
    int canvas = wg_canvas(selector ? selector : "#canvas");
    if (!canvas) return SDL_SetError("WebGPU: the page has no canvas for the window");
    WG_Window *w = (WG_Window *)SDL_calloc(1, sizeof *w);
    w->window = window;
    w->canvas = canvas;
    w->texture.id = canvas;
    w->texture.swapchain = true;
    w->texture.header.info.type = SDL_GPU_TEXTURETYPE_2D;
    w->texture.header.info.format = WG_SwapchainFormat(r);
    w->texture.header.info.usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET;
    w->texture.header.info.layer_count_or_depth = 1;
    w->texture.header.info.num_levels = 1;
    w->texture.header.info.sample_count = SDL_GPU_SAMPLECOUNT_1;
    if (r->nwindows == r->windows_cap) {
        r->windows_cap = r->windows_cap ? r->windows_cap * 2 : 4;
        r->windows = (WG_Window **)SDL_realloc(r->windows, sizeof(WG_Window *) * (size_t)r->windows_cap);
    }
    r->windows[r->nwindows++] = w;
    return true;
}

static void WEBGPU_ReleaseWindow(SDL_GPURenderer *driverData, SDL_Window *window) {
    WG_Renderer *r = (WG_Renderer *)driverData;
    for (int i = 0; i < r->nwindows; i++)
        if (r->windows[i]->window == window) {
            wg_release(r->windows[i]->canvas);
            SDL_free(r->windows[i]);
            r->windows[i] = r->windows[--r->nwindows];
            return;
        }
}

static bool WG_Acquire(SDL_GPUCommandBuffer *commandBuffer, SDL_Window *window, SDL_GPUTexture **texture,
                       Uint32 *width, Uint32 *height, bool wait) {
    WG_CommandBuffer *cb = (WG_CommandBuffer *)commandBuffer;
    WG_Window *w = WG_FindWindow(cb->renderer, window);
    *texture = NULL;
    if (!w) return SDL_SetError("WebGPU: the window was not claimed");
    Uint32 size[2] = { 0, 0 };
    wg_acquire(w->canvas, wait, size);
    w->texture.header.info.width = size[0];
    w->texture.header.info.height = size[1];
    *texture = (SDL_GPUTexture *)&w->texture;
    if (width) *width = size[0];
    if (height) *height = size[1];
    return true;
}

static bool WEBGPU_AcquireSwapchainTexture(SDL_GPUCommandBuffer *c, SDL_Window *w, SDL_GPUTexture **t,
                                           Uint32 *width, Uint32 *height) {
    return WG_Acquire(c, w, t, width, height, false);
}

static bool WEBGPU_WaitAndAcquireSwapchainTexture(SDL_GPUCommandBuffer *c, SDL_Window *w, SDL_GPUTexture **t,
                                                  Uint32 *width, Uint32 *height) {
    return WG_Acquire(c, w, t, width, height, true);
}

static bool WEBGPU_WaitForSwapchain(SDL_GPURenderer *driverData, SDL_Window *window) {
    (void)driverData;
    (void)window;
    return true;
}

static bool WEBGPU_SupportsSwapchainComposition(SDL_GPURenderer *d, SDL_Window *w,
                                                SDL_GPUSwapchainComposition c) {
    (void)d;
    (void)w;
    return c == SDL_GPU_SWAPCHAINCOMPOSITION_SDR;
}

/* A page draws at the display's pace, when the browser asks for a frame. */
static bool WEBGPU_SupportsPresentMode(SDL_GPURenderer *d, SDL_Window *w, SDL_GPUPresentMode m) {
    (void)d;
    (void)w;
    return m == SDL_GPU_PRESENTMODE_VSYNC;
}

static bool WEBGPU_SetSwapchainParameters(SDL_GPURenderer *d, SDL_Window *w, SDL_GPUSwapchainComposition c,
                                          SDL_GPUPresentMode m) {
    (void)d;
    (void)w;
    return c == SDL_GPU_SWAPCHAINCOMPOSITION_SDR && m == SDL_GPU_PRESENTMODE_VSYNC;
}

static bool WEBGPU_SetAllowedFramesInFlight(SDL_GPURenderer *d, Uint32 n) {
    (void)d;
    (void)n;
    return true;
}

static SDL_GPUTextureFormat WEBGPU_GetSwapchainTextureFormat(SDL_GPURenderer *driverData, SDL_Window *window) {
    (void)window;
    return WG_SwapchainFormat((WG_Renderer *)driverData);
}

static bool WEBGPU_SupportsTextureFormat(SDL_GPURenderer *driverData, SDL_GPUTextureFormat format,
                                         SDL_GPUTextureType type, SDL_GPUTextureUsageFlags usage) {
    (void)driverData;
    (void)type;
    const char *f = WG_TextureFormat(format);
    if (!f) return false;
    /* What WebGPU's core lets a format be written as storage. */
    if (usage & (SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ |
                 SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ |
                 SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE)) {
        static const char *storage[] = { "rgba8unorm", "rgba8snorm", "rgba8uint", "rgba8sint", "rgba16uint",
                                         "rgba16sint", "rgba16float", "r32uint", "r32sint", "r32float",
                                         "rg32uint", "rg32sint", "rg32float", "rgba32uint", "rgba32sint",
                                         "rgba32float", NULL };
        bool ok = false;
        for (int i = 0; storage[i]; i++) ok |= !SDL_strcmp(storage[i], f);
        if (!ok) return false;
    }
    return true;
}

static bool WEBGPU_SupportsSampleCount(SDL_GPURenderer *driverData, SDL_GPUTextureFormat format,
                                       SDL_GPUSampleCount count) {
    (void)driverData;
    (void)format;
    return count == SDL_GPU_SAMPLECOUNT_1 || count == SDL_GPU_SAMPLECOUNT_4;
}

/* --- the driver ---------------------------------------------------------------------------- */

static bool WEBGPU_PrepareDriver(SDL_VideoDevice *_this, SDL_PropertiesID props) {
    (void)_this;
    (void)props;
    return wg_available() != 0;
}

static SDL_GPUDevice *WEBGPU_CreateDevice(bool debug, bool preferLowPower, SDL_PropertiesID props) {
    (void)props;
    if (!wg_init(preferLowPower)) {
        SDL_SetError("WebGPU: this browser gave no GPU adapter or device");
        return NULL;
    }
    WG_Renderer *r = (WG_Renderer *)SDL_calloc(1, sizeof *r);
    r->rgba_canvas = wg_canvas_format() != 0;
    SDL_GPUDevice *result = (SDL_GPUDevice *)SDL_calloc(1, sizeof *result);
    ASSIGN_DRIVER(WEBGPU)
    result->driverData = (SDL_GPURenderer *)r;
    result->backend = "webgpu";
    /* The payload a web build's blobs carry where the SPIR-V goes. */
    result->shader_formats = SDL_GPU_SHADERFORMAT_SPIRV;
    result->debug_mode = debug;
    r->device = result;
    return result;
}

SDL_GPUBootstrap PrivateGPUDriver = {
    "webgpu",
    WEBGPU_PrepareDriver,
    WEBGPU_CreateDevice
};
