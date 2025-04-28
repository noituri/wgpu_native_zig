//
// The callback mode controls how a callback for an asynchronous operation may be fired.
//
pub const CallbackMode = enum(u32) {
    //
    //`0x00000001`.
    // Callbacks created with `wait_any_only`:
    // - fire when the asynchronous operation's future is passed to a call to `::wgpuInstanceWaitAny`
    //   AND the operation has already completed or it completes inside the call to `::wgpuInstanceWaitAny`.
    //
    wait_any_only        = 0x00000001,
    //
    // `0x00000002`.
    // Callbacks created with `allow_process_events`:
    // - fire for the same reasons as callbacks created with `wait_any_only`
    // - fire inside a call to `::wgpuInstanceProcessEvents` if the asynchronous operation is complete.
    //
    allow_process_events = 0x00000002,
    //
    // `0x00000003`.
    // Callbacks created with `allow_spontaneous`:
    // - fire for the same reasons as callbacks created with `allow_process_events`
    // - **may** fire spontaneously on an arbitrary or application thread, when the WebGPU implementations discovers that the asynchronous operation is complete.
    //
    //   Implementations _should_ fire spontaneous callbacks as soon as possible.
    //
    // Because spontaneous callbacks may fire at an arbitrary time on an arbitrary thread, applications should take extra care when acquiring locks or mutating state inside the callback.
    // It undefined behavior to re-entrantly call into the webgpu.h API if the callback fires while inside the callstack of another webgpu.h function that is not `wgpuInstanceWaitAny` or `wgpuInstanceProcessEvents`.
    //
    allow_spontaneous    = 0x00000003,
};

//
// Opaque handle to an asynchronous operation.
//
pub const Future = extern struct {
    //
    // Opaque id of the Future
    //
    id: u64,
};
