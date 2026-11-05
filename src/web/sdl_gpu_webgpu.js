/* Goose compiler: the JavaScript half of SDL_GPU's WebGPU backend for
   --target wasm64-web (docs/design/wasm.md §8, milestone 4), linked with
   --js-library into a page that uses the gfx package. SDL_gpu_webgpu.c, the
   C half, turns SDL_GPU's calls into these; this file turns them into
   navigator.gpu's. Objects live in a table and cross to C as small integer
   ids. What WebGPU does asynchronously (the device, a frame, reading back)
   suspends the program through JSPI (`__async`), so C sees ordinary
   blocking calls. Pointers arrive as BigInt (memory64), hence Number(). */

addToLibrary({
  $WG__deps: ['$UTF8ToString'],
  $WG: {
    objs: [null],
    free: [],
    device: null,
    queue: null,
    adapter: null,
    // The uniform ring: every SDL_GPU uniform push lands at its own
    // 256-byte aligned place, written to the GPU as its command buffer is
    // submitted. Queue order makes a place safe to reuse once the
    // submission that read it went before the write.
    ring: null,
    ringSize: 4 << 20,
    ringData: null,
    ringAt: 0,
    ringDirty: [],
    put(o) {
      const id = WG.free.length ? WG.free.pop() : WG.objs.length;
      WG.objs[id] = o;
      return id;
    },
    get(id) { return WG.objs[id]; },
    drop(id) {
      if (id > 0 && WG.objs[id] !== undefined && WG.objs[id] !== null) {
        WG.objs[id] = null;
        WG.free.push(id);
      }
    },
    str(p) { return UTF8ToString(Number(p)); },
    json(p) { return JSON.parse(UTF8ToString(Number(p))); },
    // A view of a texture, by dimension, cached on the texture.
    view(id, dim, mip, layer) {
      const t = WG.get(id);
      if (t.isSwap) return t.view;
      const key = dim + ':' + (mip ?? -1) + ':' + (layer ?? -1);
      t.views ||= {};
      if (!t.views[key]) {
        const d = { dimension: dim || (t.tex.dimension === '3d' ? '3d' : '2d') };
        if (mip !== undefined && mip >= 0) { d.baseMipLevel = mip; d.mipLevelCount = 1; }
        if (layer !== undefined && layer >= 0) { d.baseArrayLayer = layer; d.arrayLayerCount = 1; }
        if (d.dimension === 'cube') d.arrayLayerCount = 6;
        t.views[key] = t.tex.createView(d);
      }
      return t.views[key];
    },
    tex(id) { const t = WG.get(id); return t.isSwap ? t.cur : t.tex; },
    // The bind group layouts a pipeline was made with, from its shaders'
    // bindings: one per SDL_GPU set, uniforms with dynamic offsets.
    layoutEntry(b, vis) {
      const e = { binding: b.binding, visibility: vis };
      const dims = ['2d', 'cube', '3d', '2d-array'];
      if (b.kind === 0 || b.kind === 5) {
        e.texture = { viewDimension: dims[b.dim] || '2d',
                      sampleType: b.kind === 5 ? (b.st === 1 ? 'uint' : 'unfilterable-float')
                                 : b.st === 1 ? 'uint' : b.st === 2 ? 'depth' : 'float' };
      } else if (b.kind === 1) {
        e.sampler = { type: b.cmp ? 'comparison' : 'filtering' };
      } else if (b.kind === 2) {
        e.storageTexture = { access: ['read-only', 'write-only', 'read-write'][b.access],
                             format: b.format, viewDimension: dims[b.dim] || '2d' };
      } else if (b.kind === 3) {
        e.buffer = { type: b.access === 0 ? 'read-only-storage' : 'storage' };
      } else {
        e.buffer = { type: 'uniform', hasDynamicOffset: true };
      }
      return e;
    },
    makeLayouts(groups) {
      return groups.map(g => WG.device.createBindGroupLayout({
        entries: g.map(b => WG.layoutEntry(b, b.vis)) }));
    },
    // Blits and mipmaps: a triangle over the destination, sampling the
    // source region, one pipeline per destination format.
    blitShader: null,
    blitPipes: {},
    blitSamplers: {},
    blitPipe(format) {
      if (!WG.blitShader) {
        WG.blitShader = WG.device.createShaderModule({ code: `
struct U { rect: vec4f, lod: f32, layer: f32, flip: u32, pad: u32 };
@group(0) @binding(0) var src: texture_2d<f32>;
@group(0) @binding(1) var smp: sampler;
@group(0) @binding(2) var<uniform> u: U;
struct V { @builtin(position) pos: vec4f, @location(0) uv: vec2f };
@vertex fn vs(@builtin(vertex_index) i: u32) -> V {
  let p = vec2f(f32((i << 1u) & 2u), f32(i & 2u));
  var o: V;
  o.pos = vec4f(p * vec2f(2.0, -2.0) + vec2f(-1.0, 1.0), 0.0, 1.0);
  var t = p;
  if ((u.flip & 1u) != 0u) { t.x = 1.0 - t.x; }
  if ((u.flip & 2u) != 0u) { t.y = 1.0 - t.y; }
  o.uv = u.rect.xy + t * u.rect.zw;
  return o;
}
@fragment fn fs(v: V) -> @location(0) vec4f {
  return textureSampleLevel(src, smp, v.uv, u.lod);
}` });
      }
      if (!WG.blitPipes[format]) {
        WG.blitPipes[format] = WG.device.createRenderPipeline({
          layout: 'auto',
          vertex: { module: WG.blitShader, entryPoint: 'vs' },
          fragment: { module: WG.blitShader, entryPoint: 'fs', targets: [{ format }] },
          primitive: { topology: 'triangle-list' } });
      }
      return WG.blitPipes[format];
    },
    blitSampler(linear) {
      const k = linear ? 'l' : 'n';
      WG.blitSamplers[k] ||= WG.device.createSampler({
        magFilter: linear ? 'linear' : 'nearest', minFilter: linear ? 'linear' : 'nearest' });
      return WG.blitSamplers[k];
    },
    // One blit inside `enc`: the source view's region into the destination
    // view's, which load as `load`.
    blit(enc, srcView, dstView, dstFormat, rect, lod, flip, linear, dst, load, clear) {
      const ub = WG.device.createBuffer({ size: 32, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
      const data = new ArrayBuffer(32);
      new Float32Array(data, 0, 6).set([rect[0], rect[1], rect[2], rect[3], lod, 0]);
      new Uint32Array(data, 24, 1)[0] = flip;
      WG.queue.writeBuffer(ub, 0, data);
      const pipe = WG.blitPipe(dstFormat);
      const bg = WG.device.createBindGroup({ layout: pipe.getBindGroupLayout(0), entries: [
        { binding: 0, resource: srcView }, { binding: 1, resource: WG.blitSampler(linear) },
        { binding: 2, resource: { buffer: ub } }] });
      const pass = enc.beginRenderPass({ colorAttachments: [{ view: dstView, loadOp: load,
        clearValue: clear || [0, 0, 0, 0], storeOp: 'store' }] });
      pass.setPipeline(pipe);
      pass.setBindGroup(0, bg);
      if (dst) pass.setViewport(dst[0], dst[1], dst[2], dst[3], 0, 1);
      pass.draw(3);
      pass.end();
      enc._later.push(() => ub.destroy());
    },
    // Submissions not yet done: each settles its own downloads, mapping
    // their readback buffers and copying the rows into the transfer
    // buffers' memory, exactly once.
    inflight: new Set(),
    async settle(list) {
      for (const d of list) {
        await d.buf.mapAsync(GPUMapMode.READ);
        const src = new Uint8Array(d.buf.getMappedRange());
        for (let r = 0; r < d.rows; r++)
          HEAPU8.set(src.subarray(r * d.srcPitch, r * d.srcPitch + d.rowBytes), d.dst + r * d.dstPitch);
        d.buf.unmap();
        d.buf.destroy();
      }
    },
  },

  wg_available__deps: ['$WG'],
  wg_available: () => (typeof navigator !== 'undefined' && navigator.gpu) ? 1 : 0,

  // The adapter and device, once; 1 when there are both.
  wg_init__deps: ['$WG'],
  wg_init__async: true,
  wg_init: async (lowPower) => {
    if (WG.device) return 1;
    if (!navigator.gpu) return 0;
    WG.adapter = await navigator.gpu.requestAdapter({ powerPreference: lowPower ? 'low-power' : 'high-performance' });
    if (!WG.adapter) return 0;
    const want = ['depth32float-stencil8', 'float32-filterable', 'rg11b10ufloat-renderable'];
    const requiredFeatures = want.filter(f => WG.adapter.features.has(f));
    WG.device = await WG.adapter.requestDevice({ requiredFeatures });
    if (!WG.device) return 0;
    WG.queue = WG.device.queue;
    WG.device.onuncapturederror = e => err('WebGPU: ' + e.error.message);
    WG.ring = WG.device.createBuffer({ size: WG.ringSize, usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST });
    WG.ringData = new Uint8Array(WG.ringSize);
    return 1;
  },

  wg_has_feature__deps: ['$WG'],
  wg_has_feature: (name) => WG.device && WG.device.features.has(WG.str(name)) ? 1 : 0,

  wg_destroy__deps: ['$WG'],
  wg_destroy: () => {
    if (WG.device) WG.device.destroy();
    WG.device = WG.queue = WG.adapter = WG.ring = null;
    WG.objs = [null];
    WG.free = [];
    WG.blitShader = null;
    WG.blitPipes = {};
    WG.blitSamplers = {};
    WG.inflight = new Set();
  },

  wg_release__deps: ['$WG'],
  wg_release: (id) => {
    const o = WG.get(id);
    if (!o) return;
    if (o.tex && !o.isSwap) o.tex.destroy();
    if (o.buffer) o.buffer.destroy();
    WG.drop(id);
  },

  // --- objects ---------------------------------------------------------------

  wg_buffer__deps: ['$WG'],
  wg_buffer: (size, usage) => {
    const u = GPUBufferUsage;
    let flags = u.COPY_SRC | u.COPY_DST;
    if (usage & 1) flags |= u.VERTEX;
    if (usage & 2) flags |= u.INDEX;
    if (usage & 4) flags |= u.INDIRECT;
    if (usage & 0x38) flags |= u.STORAGE;
    // WebGPU sizes are multiples of 4; what lies past the program's own size
    // is never read.
    return WG.put({ buffer: WG.device.createBuffer({ size: Math.max(4, (size + 3) & ~3), usage: flags }) });
  },

  wg_texture__deps: ['$WG'],
  wg_texture: (desc) => {
    const d = WG.json(desc);
    const u = GPUTextureUsage;
    let usage = u.COPY_SRC | u.COPY_DST;
    if (d.sampled) usage |= u.TEXTURE_BINDING;
    if (d.target) usage |= u.RENDER_ATTACHMENT;
    if (d.storage) usage |= u.STORAGE_BINDING;
    const tex = WG.device.createTexture({ size: [d.w, d.h, d.layers], format: d.format,
      dimension: d.dim, mipLevelCount: d.mips, sampleCount: d.samples, usage });
    return WG.put({ tex, format: d.format, cube: d.cube });
  },

  wg_sampler__deps: ['$WG'],
  wg_sampler: (desc) => WG.put({ sampler: WG.device.createSampler(WG.json(desc)) }),

  wg_shader__deps: ['$WG'],
  wg_shader: (code) => {
    const module = WG.device.createShaderModule({ code: WG.str(code) });
    return WG.put({ module });
  },

  wg_render_pipeline__deps: ['$WG'],
  wg_render_pipeline: (desc) => {
    const d = WG.json(desc);
    const layouts = WG.makeLayouts(d.groups);
    d.pipe.layout = WG.device.createPipelineLayout({ bindGroupLayouts: layouts });
    d.pipe.vertex.module = WG.get(d.vs).module;
    if (d.pipe.fragment) d.pipe.fragment.module = WG.get(d.fs).module;
    return WG.put({ pipeline: WG.device.createRenderPipeline(d.pipe), layouts });
  },

  wg_compute_pipeline__deps: ['$WG'],
  wg_compute_pipeline: (code, groups) => {
    const g = WG.json(groups);
    const layouts = WG.makeLayouts(g);
    const module = WG.device.createShaderModule({ code: WG.str(code) });
    const pipeline = WG.device.createComputePipeline({
      layout: WG.device.createPipelineLayout({ bindGroupLayouts: layouts }),
      compute: { module, entryPoint: 'main' } });
    return WG.put({ pipeline, layouts });
  },

  // A bind group for group `g` of a pipeline, from `n` entries of five
  // 32-bit words each: binding, kind, object id, dimension, and the mip
  // level (+1, 0 for all) of a storage texture.
  wg_bind_group__deps: ['$WG'],
  wg_bind_group: (enc, pipe, g, n, words) => {
    const p = WG.get(pipe), w = Number(words) >> 2;
    const dims = ['2d', 'cube', '3d', '2d-array'];
    const entries = [];
    for (let i = 0; i < n; i++) {
      const binding = HEAPU32[w + i * 5], kind = HEAPU32[w + i * 5 + 1], id = HEAPU32[w + i * 5 + 2];
      const dim = HEAPU32[w + i * 5 + 3], mip = HEAPU32[w + i * 5 + 4];
      let resource;
      if (kind === 0 || kind === 5) resource = WG.view(id, dims[dim]);
      else if (kind === 1) resource = WG.get(id).sampler;
      else if (kind === 2) resource = WG.view(id, dims[dim], mip ? mip - 1 : undefined);
      else if (kind === 3) resource = { buffer: WG.get(id).buffer };
      else resource = { buffer: WG.ring, offset: 0, size: 32768 };
      entries.push({ binding, resource });
    }
    const bg = WG.device.createBindGroup({ layout: p.layouts[g], entries });
    const e = WG.get(enc);
    e._groups.push(bg);
    return e._groups.length - 1;
  },

  // --- the canvas --------------------------------------------------------------

  wg_canvas__deps: ['$WG'],
  wg_canvas: (selector) => {
    const sel = WG.str(selector);
    const canvas = (sel && document.querySelector(sel)) || Module['canvas'];
    if (!canvas) return 0;
    const ctx = canvas.getContext('webgpu');
    if (!ctx) return 0;
    const format = navigator.gpu.getPreferredCanvasFormat();
    ctx.configure({ device: WG.device, format, alphaMode: 'opaque',
                    usage: GPUTextureUsage.RENDER_ATTACHMENT | GPUTextureUsage.COPY_SRC | GPUTextureUsage.COPY_DST });
    return WG.put({ isSwap: true, canvas, ctx, format, cur: null, view: null });
  },

  wg_canvas_format__deps: ['$WG'],
  wg_canvas_format: () => navigator.gpu.getPreferredCanvasFormat() === 'rgba8unorm' ? 1 : 0,

  // The canvas's texture for the next frame, after the browser's next
  // animation frame: what paces a program to the display and lets the page
  // take its input. Its size into `size` (two 32-bit words).
  wg_acquire__deps: ['$WG'],
  wg_acquire__async: true,
  wg_acquire: async (id, wait, size) => {
    const s = WG.get(id);
    if (wait) await new Promise(r => requestAnimationFrame(r));
    s.cur = s.ctx.getCurrentTexture();
    s.view = s.cur.createView();
    const p = Number(size) >> 2;
    HEAPU32[p] = s.cur.width;
    HEAPU32[p + 1] = s.cur.height;
    return 1;
  },

  // --- command buffers -----------------------------------------------------------

  wg_encoder__deps: ['$WG'],
  wg_encoder: () => {
    const enc = WG.device.createCommandEncoder();
    enc._groups = [];
    enc._later = [];
    enc._downloads = [];
    return WG.put(enc);
  },

  // The command buffer's work to the queue, after the uniforms it pushed:
  // a fence id, whose promise settles when the GPU is done and every
  // download it holds is in its transfer buffer.
  wg_submit__deps: ['$WG'],
  wg_submit: (id, cancel) => {
    const enc = WG.get(id);
    WG.drop(id);
    if (WG.ringDirty.length) {
      for (const [a, b] of WG.ringDirty) WG.queue.writeBuffer(WG.ring, a, WG.ringData, a, b - a);
      WG.ringDirty = [];
    }
    if (!cancel) WG.queue.submit([enc.finish()]);
    for (const f of enc._later) f();
    const fence = { done: false };
    const downloads = cancel ? [] : enc._downloads;
    if (cancel) for (const d of enc._downloads) d.buf.destroy();
    fence.promise = WG.queue.onSubmittedWorkDone().then(() => WG.settle(downloads)).then(() => {
      fence.done = true;
      WG.inflight.delete(fence.promise);
    });
    WG.inflight.add(fence.promise);
    return WG.put(fence);
  },

  wg_fence_done__deps: ['$WG'],
  wg_fence_done: (id) => WG.get(id).done ? 1 : 0,

  wg_fence_wait__deps: ['$WG'],
  wg_fence_wait__async: true,
  wg_fence_wait: async (id) => { await WG.get(id).promise; return 1; },

  // Everything submitted done, and every download in its transfer buffer.
  wg_idle__deps: ['$WG'],
  wg_idle__async: true,
  wg_idle: async () => {
    if (!WG.queue) return 1;
    await WG.queue.onSubmittedWorkDone();
    await Promise.all([...WG.inflight]);
    return 1;
  },

  // A uniform push: its bytes at the ring's next place, which it returns.
  wg_uniform__deps: ['$WG'],
  wg_uniform: (data, len) => {
    if (WG.ringAt + 32768 > WG.ringSize) WG.ringAt = 0;
    const at = WG.ringAt;
    WG.ringData.set(HEAPU8.subarray(Number(data), Number(data) + len), at);
    WG.ringAt = (at + Math.max(len, 1) + 255) & ~255;
    const last = WG.ringDirty[WG.ringDirty.length - 1];
    if (last && last[1] === at) last[1] = at + len;
    else WG.ringDirty.push([at, at + len]);
    return at;
  },

  // --- render passes -------------------------------------------------------------

  wg_render_pass__deps: ['$WG'],
  wg_render_pass: (enc, desc) => {
    const d = WG.json(desc);
    const color = d.color.map(c => {
      const a = { view: WG.view(c.tex, c.dim, c.mip, c.layer), loadOp: c.load, storeOp: c.store,
                  clearValue: c.clear };
      if (c.depthSlice !== undefined) { a.view = WG.view(c.tex, '3d', c.mip); a.depthSlice = c.depthSlice; }
      if (c.resolve) a.resolveTarget = WG.view(c.resolve, '2d', c.rmip, c.rlayer);
      return a;
    });
    const desc2 = { colorAttachments: color };
    if (d.depth) {
      const t = WG.get(d.depth.tex);
      const a = { view: WG.view(d.depth.tex, '2d', d.depth.mip, d.depth.layer) };
      if (!t.format.startsWith('stencil')) {
        a.depthLoadOp = d.depth.load; a.depthStoreOp = d.depth.store; a.depthClearValue = d.depth.clear;
      }
      if (t.format.includes('stencil')) {
        a.stencilLoadOp = d.depth.sload; a.stencilStoreOp = d.depth.sstore;
        a.stencilClearValue = d.depth.sclear;
      }
      desc2.depthStencilAttachment = a;
    }
    const pass = WG.get(enc).beginRenderPass(desc2);
    pass._enc = enc;
    return WG.put(pass);
  },

  wg_pass_end__deps: ['$WG'],
  wg_pass_end: (id) => { WG.get(id).end(); WG.drop(id); },

  wg_set_pipeline__deps: ['$WG'],
  wg_set_pipeline: (pass, pipe) => WG.get(pass).setPipeline(WG.get(pipe).pipeline),

  wg_set_viewport__deps: ['$WG'],
  wg_set_viewport: (pass, x, y, w, h, mn, mx) => WG.get(pass).setViewport(x, y, w, h, mn, mx),

  wg_set_scissor__deps: ['$WG'],
  wg_set_scissor: (pass, x, y, w, h) => WG.get(pass).setScissorRect(x, y, w, h),

  wg_set_blend__deps: ['$WG'],
  wg_set_blend: (pass, r, g, b, a) => WG.get(pass).setBlendConstant([r, g, b, a]),

  wg_set_stencil__deps: ['$WG'],
  wg_set_stencil: (pass, ref) => WG.get(pass).setStencilReference(ref),

  wg_set_vertex_buffer__deps: ['$WG'],
  wg_set_vertex_buffer: (pass, slot, buf, offset) => WG.get(pass).setVertexBuffer(slot, WG.get(buf).buffer, offset),

  wg_set_index_buffer__deps: ['$WG'],
  wg_set_index_buffer: (pass, buf, wide, offset) =>
    WG.get(pass).setIndexBuffer(WG.get(buf).buffer, wide ? 'uint32' : 'uint16', offset),

  // Group `g` of the pass's pipeline: bind group `bg` of the pass's encoder
  // (wg_bind_group), with `n` dynamic offsets at `offs`.
  wg_set_bind_group__deps: ['$WG'],
  wg_set_bind_group: (pass, enc, g, bg, n, offs) => {
    const o = Number(offs) >> 2;
    const dyn = [];
    for (let i = 0; i < n; i++) dyn.push(HEAPU32[o + i]);
    WG.get(pass).setBindGroup(g, WG.get(enc)._groups[bg], dyn);
  },

  wg_draw__deps: ['$WG'],
  wg_draw: (pass, n, inst, first, firstInst) => WG.get(pass).draw(n, inst, first, firstInst),

  wg_draw_indexed__deps: ['$WG'],
  wg_draw_indexed: (pass, n, inst, first, base, firstInst) =>
    WG.get(pass).drawIndexed(n, inst, first, base, firstInst),

  wg_draw_indirect__deps: ['$WG'],
  wg_draw_indirect: (pass, buf, offset, indexed) => {
    const p = WG.get(pass), b = WG.get(buf).buffer;
    if (indexed) p.drawIndexedIndirect(b, offset); else p.drawIndirect(b, offset);
  },

  // --- compute passes ---------------------------------------------------------------

  wg_compute_pass__deps: ['$WG'],
  wg_compute_pass: (enc) => {
    const pass = WG.get(enc).beginComputePass();
    return WG.put(pass);
  },

  wg_dispatch__deps: ['$WG'],
  wg_dispatch: (pass, x, y, z) => WG.get(pass).dispatchWorkgroups(x, y, z),

  wg_dispatch_indirect__deps: ['$WG'],
  wg_dispatch_indirect: (pass, buf, offset) => WG.get(pass).dispatchWorkgroupsIndirect(WG.get(buf).buffer, offset),

  // --- copies -------------------------------------------------------------------------

  // `size` bytes at `src` (the program's memory) into a buffer, in order
  // with the encoder's other commands: through a staging buffer.
  wg_upload_buffer__deps: ['$WG'],
  wg_upload_buffer: (enc, dst, dstOff, src, size) => {
    const e = WG.get(enc);
    const n = (size + 3) & ~3;
    const st = WG.device.createBuffer({ size: n, usage: GPUBufferUsage.COPY_SRC, mappedAtCreation: true });
    new Uint8Array(st.getMappedRange()).set(HEAPU8.subarray(Number(src), Number(src) + size));
    st.unmap();
    e.copyBufferToBuffer(st, 0, WG.get(dst).buffer, dstOff, n);
    e._later.push(() => st.destroy());
  },

  // Rows of a texture region from the program's memory: `pitch` bytes
  // apart there, `rowBytes` of them each, `rows` rows per layer.
  wg_upload_texture__deps: ['$WG'],
  wg_upload_texture: (enc, dst, mip, x, y, z, w, h, d, src, pitch, rowBytes, rows) => {
    const e = WG.get(enc);
    const padded = (rowBytes + 255) & ~255;
    const total = padded * rows * d;
    const st = WG.device.createBuffer({ size: Math.max(4, total), usage: GPUBufferUsage.COPY_SRC, mappedAtCreation: true });
    const out = new Uint8Array(st.getMappedRange());
    const s = Number(src);
    for (let k = 0; k < rows * d; k++) out.set(HEAPU8.subarray(s + k * pitch, s + k * pitch + rowBytes), k * padded);
    st.unmap();
    e.copyBufferToTexture({ buffer: st, bytesPerRow: padded, rowsPerImage: rows },
                          { texture: WG.tex(dst), mipLevel: mip, origin: [x, y, z] }, [w, h, d]);
    e._later.push(() => st.destroy());
  },

  wg_copy_buffer__deps: ['$WG'],
  wg_copy_buffer: (enc, src, so, dst, dOff, size) =>
    WG.get(enc).copyBufferToBuffer(WG.get(src).buffer, so, WG.get(dst).buffer, dOff, size),

  wg_copy_texture__deps: ['$WG'],
  wg_copy_texture: (enc, src, smip, sx, sy, sz, dst, dmip, dx, dy, dz, w, h, d) =>
    WG.get(enc).copyTextureToTexture({ texture: WG.tex(src), mipLevel: smip, origin: [sx, sy, sz] },
                                     { texture: WG.tex(dst), mipLevel: dmip, origin: [dx, dy, dz] }, [w, h, d]),

  // Reads back into the program's memory at `dst` once the command buffer
  // is submitted and done (wg_submit, wg_fence_wait, wg_idle).
  wg_download_buffer__deps: ['$WG'],
  wg_download_buffer: (enc, src, so, size, dst) => {
    const e = WG.get(enc);
    const n = (size + 3) & ~3;
    const buf = WG.device.createBuffer({ size: n, usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
    e.copyBufferToBuffer(WG.get(src).buffer, so, buf, 0, n);
    e._downloads.push({ buf, rows: 1, rowBytes: size, srcPitch: n, dstPitch: size, dst: Number(dst) });
  },

  wg_download_texture__deps: ['$WG'],
  wg_download_texture: (enc, src, mip, x, y, z, w, h, d, dst, pitch, rowBytes, rows) => {
    const e = WG.get(enc);
    const padded = (rowBytes + 255) & ~255;
    const buf = WG.device.createBuffer({ size: Math.max(4, padded * rows * d),
                                         usage: GPUBufferUsage.COPY_DST | GPUBufferUsage.MAP_READ });
    e.copyTextureToBuffer({ texture: WG.tex(src), mipLevel: mip, origin: [x, y, z] },
                          { buffer: buf, bytesPerRow: padded, rowsPerImage: rows }, [w, h, d]);
    e._downloads.push({ buf, rows: rows * d, rowBytes, srcPitch: padded, dstPitch: pitch, dst: Number(dst) });
  },

  // SDL_BlitGPUTexture: `desc` names both regions, the filter, the flip and
  // the destination's load op.
  wg_blit__deps: ['$WG'],
  wg_blit: (enc, desc) => {
    const d = WG.json(desc);
    const e = WG.get(enc);
    const s = WG.get(d.src), t = WG.get(d.dst);
    const srcView = WG.view(d.src, '2d', d.smip, d.slayer);
    const dstView = t.isSwap ? t.view : WG.view(d.dst, '2d', d.dmip, d.dlayer);
    const sw = Math.max(1, s.tex.width >> d.smip), sh = Math.max(1, s.tex.height >> d.smip);
    const rect = [d.sx / sw, d.sy / sh, d.sw / sw, d.sh / sh];
    WG.blit(e, srcView, dstView, t.isSwap ? t.format : t.format, rect, 0, d.flip, d.linear,
            [d.dx, d.dy, d.dw, d.dh], d.load, d.clear);
  },

  // Every mip level of a texture from the one above it.
  wg_mipmaps__deps: ['$WG'],
  wg_mipmaps: (enc, id) => {
    const e = WG.get(enc), t = WG.get(id);
    const layers = t.tex.depthOrArrayLayers;
    for (let layer = 0; layer < layers; layer++)
      for (let m = 1; m < t.tex.mipLevelCount; m++)
        WG.blit(e, WG.view(id, '2d', m - 1, layer), WG.view(id, '2d', m, layer), t.format,
                [0, 0, 1, 1], 0, 0, true, null, 'clear', null);
  },
});
