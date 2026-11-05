/* The shader blob `embed_shader` produces: one shader stage, compiled from
   GLSL at compile time into every format SDL_GPU takes, plus the reflection
   that creating an SDL_GPU shader or pipeline needs. The compiler writes it
   (src/shaderc.c) and embeds it in the program as static data; the gfx
   package's layer reads it back from its own copy of this header
   (src/gfx/gfx_blob.h in github.com/aardappel/goose_gfx), which the version
   below keeps in step.
   Plain C, so both can read it.

   Layout, little-endian and unaligned (a blob sits in a byte array):

       gs_gfx_blob_header
       uint32_t uniform_sizes[num_uniform_buffers]   std140 size, by binding
       gs_gfx_blob_input inputs[num_inputs]          vertex stage, by location
       the SPIR-V words, the MSL text and the HLSL text, at the offsets the
       header gives; each text is followed by a NUL its size leaves out.

   Readers copy the header out with memcpy rather than casting a pointer to
   it: nothing aligns the array holding the blob. */

#ifndef GS_GFX_BLOB_H
#define GS_GFX_BLOB_H

#include <stdint.h>

#define GS_GFX_BLOB_MAGIC "GSHD"
#define GS_GFX_BLOB_VERSION 1

enum {
    GS_GFX_STAGE_VERTEX = 0,
    GS_GFX_STAGE_FRAGMENT = 1,
    GS_GFX_STAGE_COMPUTE = 2,
};

/* A vertex input's type, as cute_spirv reflects it (CSPV_DataType). */
enum {
    GS_GFX_INPUT_INT = 1, GS_GFX_INPUT_UINT = 2, GS_GFX_INPUT_FLOAT = 3,
    GS_GFX_INPUT_INT2 = 4, GS_GFX_INPUT_UINT2 = 5, GS_GFX_INPUT_FLOAT2 = 6,
    GS_GFX_INPUT_INT3 = 7, GS_GFX_INPUT_UINT3 = 8, GS_GFX_INPUT_FLOAT3 = 9,
    GS_GFX_INPUT_INT4 = 10, GS_GFX_INPUT_UINT4 = 11, GS_GFX_INPUT_FLOAT4 = 12,
    GS_GFX_INPUT_MAT4 = 13,
};

#pragma pack(push, 1)
typedef struct {
    char magic[4];
    uint16_t version;
    uint8_t stage;
    uint8_t num_inputs;
    uint32_t local_size[3];         /* compute only */
    /* In a graphics stage every storage resource is read-only. */
    uint16_t num_samplers, num_storage_textures_ro, num_storage_textures_rw,
             num_storage_buffers_ro, num_storage_buffers_rw, num_uniform_buffers;
    uint32_t spirv_offset, spirv_size;
    uint32_t msl_offset, msl_size;
    uint32_t hlsl_offset, hlsl_size;
} gs_gfx_blob_header;

typedef struct {
    uint8_t location;
    uint8_t type;                   /* GS_GFX_INPUT_* */
} gs_gfx_blob_input;

/* --target wasm64-web (docs/design/wasm.md §8, milestone 4): the browser
   runs WGSL, which no SPIR-V reader there takes, so a web build's blob
   holds in place of the SPIR-V a GSWG payload: this header, the bindings
   the WGSL declares, then the WGSL text and a NUL. The gfx package hands
   the "SPIR-V" bytes through SDL_GPU unchanged, and the WebGPU backend
   (src/web/SDL_gpu_webgpu.c) reads them. The MSL and HLSL are left empty.
   Native builds never see one. */
#define GS_GFX_WGSL_MAGIC "GSWG"
#define GS_GFX_WGSL_VERSION 1

/* What a binding is, as cute_spirv's CSPV_WgslBindingKind. */
enum {
    GS_GFX_WGSL_SAMPLED_TEXTURE = 0, GS_GFX_WGSL_SAMPLER = 1, GS_GFX_WGSL_STORAGE_TEXTURE = 2,
    GS_GFX_WGSL_STORAGE_BUFFER = 3, GS_GFX_WGSL_UNIFORM_BUFFER = 4,
    GS_GFX_WGSL_SPLIT_LOAD_TEXTURE = 5,
};

typedef struct {
    char magic[4];
    uint32_t version;
    uint32_t num_bindings;
    uint32_t wgsl_size;             /* without its NUL */
} gs_gfx_wgsl_header;

typedef struct {
    uint8_t group;                  /* @group: SDL_GPU's set */
    uint8_t binding;                /* @binding */
    uint8_t slot;                   /* the resource's binding in its set, in the GLSL */
    uint8_t kind;                   /* GS_GFX_WGSL_* */
    uint8_t dim;                    /* textures: 0 2d, 1 cube, 2 3d, 3 2d array */
    uint8_t sample_type;            /* textures: 0 float, 1 uint, 2 depth */
    uint8_t comparison;             /* samplers: a comparison sampler */
    uint8_t access;                 /* storage: 0 read, 1 write, 2 read_write */
    uint8_t store_binding;          /* split load textures: the storage texture's @binding */
    uint8_t pad[3];
    char format[20];                /* storage textures: the WGSL texel format */
} gs_gfx_wgsl_binding;
#pragma pack(pop)

#endif
