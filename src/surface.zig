const _chained_struct = @import("chained_struct.zig");
const SType = _chained_struct.SType;
const ChainedStruct = _chained_struct.ChainedStruct;
const ChainedStructOut = _chained_struct.ChainedStructOut;

const _adapter = @import("adapter.zig");
const Adapter = _adapter.Adapter;

const _texture = @import("texture.zig");
const Texture = _texture.Texture;
const TextureFormat = _texture.TextureFormat;
const TextureUsageFlags = _texture.TextureUsageFlags;
const TextureUsage = _texture.TextureUsage;

const _device = @import("device.zig");
const Device = _device.Device;

const WGPUBool = @import("misc.zig").WGPUBool;

pub const SurfaceDescriptor = extern struct {
    next_in_chain: *const ChainedStruct,
    label: ?[*:0]const u8 = null,
};

pub const SurfaceDescriptorFromAndroidNativeWindow = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_android_native_window,
    },
    window: *anyopaque,
};
pub const MergedSurfaceDescriptorFromAndroidWindow = struct {
    label: ?[*:0]const u8 = null,
    window: *anyopaque,
};
pub inline fn surfaceDescriptorFromAndroidNativeWindow(descriptor: MergedSurfaceDescriptorFromAndroidWindow) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromAndroidNativeWindow {
            .window = descriptor.window,
        }),
        .label = descriptor.label,
    };
}

pub const SurfaceDescriptorFromCanvasHTMLSelector = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_canvas_html_selector,
    },
    selector: [*:0]const u8,
};
pub const MergedSurfaceDescriptorFromCanvasHTMLSelector = struct {
    label: ?[*:0]const u8 = null,
    selector: [*:0]const u8,
};
pub inline fn surfaceDescriptorFromCanvasHTMLSelector(descriptor: MergedSurfaceDescriptorFromCanvasHTMLSelector) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromCanvasHTMLSelector {
            .selector = descriptor.selector,
        }),
        .label = descriptor.label,
    };
}

pub const SurfaceDescriptorFromMetalLayer = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_metal_layer,
    },
    layer: *anyopaque,
};
pub const MergedSurfaceDescriptorFromMetalLayer = struct {
    label: ?[*:0]const u8 = null,
    layer: *anyopaque,
};
pub inline fn surfaceDescriptorFromMetalLayer(descriptor: MergedSurfaceDescriptorFromMetalLayer) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromMetalLayer {
            .layer = descriptor.layer,
        }),
        .label = descriptor.label,
    };
}

pub const SurfaceDescriptorFromWaylandSurface = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_wayland_surface,
    },
    display: *anyopaque,
    surface: *anyopaque,
};
pub const MergedSurfaceDescriptorFromWaylandSurface = struct {
    label: ?[*:0]const u8 = null,
    display: *anyopaque,
    surface: *anyopaque,
};
pub inline fn surfaceDescriptorFromWaylandSurface(descriptor: MergedSurfaceDescriptorFromWaylandSurface) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromWaylandSurface {
            .display = descriptor.display,
            .surface = descriptor.surface,
        }),
        .label = descriptor.label,
    };
}

pub const SurfaceDescriptorFromWindowsHWND = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_windows_hwnd,
    },
    hinstance: *anyopaque,
    hwnd: *anyopaque,
};
pub const MergedSurfaceDescriptorFromWindowsHWND = struct {
    label: ?[*:0]const u8 = null,
    hinstance: *anyopaque,
    hwnd: *anyopaque,
};
pub inline fn surfaceDescriptorFromWindowsHWND(descriptor: MergedSurfaceDescriptorFromWindowsHWND) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromWindowsHWND {
            .hinstance = descriptor.hinstance,
            .hwnd = descriptor.hwnd,
        }),
        .label = descriptor.label,
    };
}

pub const SurfaceDescriptorFromXcbWindow = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_xcb_window,
    },
    connection: *anyopaque,
    window: u32,
};
pub const MergedSurfaceDescriptorFromXcbWindow = struct {
    label: ?[*:0]const u8 = null,
    connection: *anyopaque,
    window: u32,
};
pub inline fn surfaceDescriptorFromXcbWindow(descriptor: MergedSurfaceDescriptorFromXcbWindow) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromXcbWindow {
            .connection = descriptor.connection,
            .window = descriptor.window,
        }),
        .label = descriptor.label,
    };
}

pub const SurfaceDescriptorFromXlibWindow = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_descriptor_from_xlib_window,
    },
    display: *anyopaque,
    window: u64,
};
pub const MergedSurfaceDescriptorFromXlibWindow = struct {
    label: ?[*:0]const u8 = null,
    connection: *anyopaque,
    window: u64,
};
pub inline fn surfaceDescriptorFromXlibWindow(descriptor: MergedSurfaceDescriptorFromXlibWindow) SurfaceDescriptor {
    return SurfaceDescriptor{
        .next_in_chain = @ptrCast(&SurfaceDescriptorFromXlibWindow {
            .display = descriptor.display,
            .window = descriptor.window,
        }),
        .label = descriptor.label,
    };
}

// Describes how frames are composited with other contents on the screen when `::wgpuSurfacePresent` is called
pub const CompositeAlphaMode = enum(u32) {
    // Lets the WebGPU implementation choose the best mode (supported, and with the best performance) between `@"opaque"` or `inherit`.
    auto            = 0x00000000,

    // The alpha component of the image is ignored and teated as if it is always 1.0.
    @"opaque"       = 0x00000001,

    // The alpha component is respected and non-alpha components are assumed to be already multiplied with the alpha component.
    // For example, (0.5, 0, 0, 0.5) is semi-transparent bright red.
    premultiplied   = 0x00000002,

    // The alpha component is respected and non-alpha components are assumed to NOT be already multiplied with the alpha component.
    // For example, (1.0, 0, 0, 0.5) is semi-transparent bright red.
    unpremultiplied = 0x00000003,

    // The handling of the alpha component is unknown to WebGPU and should be handled by the application using system-specific APIs.
    // This mode may be unavailable (for example on Wasm).
    inherit         = 0x00000004,
};
pub const PresentMode = enum(u32) {
    fifo         = 0x00000000,
    fifo_relaxed = 0x00000001,
    immediate    = 0x00000002,
    mailbox      = 0x00000003,
};

pub const SurfaceConfigurationExtras = extern struct {
    chain: ChainedStruct = ChainedStruct {
        .s_type = SType.surface_configuration_extras,
    },

    desired_maximum_frame_latency: u32,
};

pub const SurfaceConfiguration = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    device: *Device,
    format: TextureFormat,
    usage: TextureUsageFlags = TextureUsage.render_attachment,
    view_format_count: usize = 0,
    view_formats: [*]const TextureFormat = (&[_]TextureFormat{}).ptr,
    alpha_mode: CompositeAlphaMode = CompositeAlphaMode.auto,
    width: u32,
    height: u32,
    present_mode: PresentMode = PresentMode.fifo,

    pub inline fn withDesiredMaxFrameLatency(self: SurfaceConfiguration, desired_max_frame_latency: u32) SurfaceConfiguration {
        var sc = self;
        sc.next_in_chain = @ptrCast(&SurfaceConfigurationExtras {
            .desired_maximum_frame_latency = desired_max_frame_latency,
        });
        return sc;
    }
};

pub const SurfaceCapabilitiesProcs = struct {
    pub const FreeMembers = *const fn(SurfaceCapabilities) callconv(.C) void;
};
extern fn wgpuSurfaceCapabilitiesFreeMembers(surface_capabilities: SurfaceCapabilities) void;
pub const SurfaceCapabilities = extern struct {
    next_in_chain: ?*ChainedStructOut = null,
    usages: TextureUsageFlags,
    format_count: usize,
    formats: [*]const TextureFormat,
    present_mode_count: usize,
    present_modes: [*]const PresentMode,
    alpha_mode_count: usize,
    alpha_modes: [*]const CompositeAlphaMode,

    pub inline fn freeMembers(self: SurfaceCapabilities) void {
        wgpuSurfaceCapabilitiesFreeMembers(self);
    }
};

pub const GetCurrentTextureStatus = enum(u32) {
    success       = 0x00000000,
    timeout       = 0x00000001,
    outdated      = 0x00000002,
    lost          = 0x00000003,
    out_of_memory = 0x00000004,
    device_lost   = 0x00000005,
};

pub const SurfaceTexture = extern struct {
    texture: *Texture,
    suboptimal: WGPUBool,
    status: GetCurrentTextureStatus,
};

pub const SurfaceProcs = struct {
    pub const Configure = *const fn(*Surface, *const SurfaceConfiguration) callconv(.C) void;
    pub const GetCapabilities = *const fn(*Surface, *Adapter, *SurfaceCapabilities) callconv(.C) void;
    pub const GetCurrentTexture = *const fn(*Surface, *SurfaceTexture) callconv(.C) void;
    pub const Present = *const fn(*Surface) callconv(.C) void;
    pub const SetLabel = *const fn(*Surface, ?[*:0]const u8) void;
    pub const Unconfigure = *const fn(*Surface) callconv(.C) void;
    pub const AddRef = *const fn(*Surface) callconv(.C) void;
    pub const Release = *const fn(*Surface) callconv(.C) void;
};

extern fn wgpuSurfaceConfigure(surface: *Surface, config: *const SurfaceConfiguration) void;
extern fn wgpuSurfaceGetCapabilities(surface: *Surface, adapter: *Adapter, capabilities: *SurfaceCapabilities) void;
extern fn wgpuSurfaceGetCurrentTexture(surface: *Surface, surface_texture: *SurfaceTexture) void;
extern fn wgpuSurfacePresent(surface: *Surface) void;
extern fn wgpuSurfaceSetLabel(surface: *Surface, label: ?[*:0]const u8) void;
extern fn wgpuSurfaceUnconfigure(surface: *Surface) void;
extern fn wgpuSurfaceAddRef(surface: *Surface) void;
extern fn wgpuSurfaceRelease(surface: *Surface) void;

pub const Surface = opaque {
    pub inline fn configure(self: *Surface, config: *const SurfaceConfiguration) void {
        wgpuSurfaceConfigure(self, config);
    }
    pub inline fn getCapabilities(self: *Surface, adapter: *Adapter, capabilities: *SurfaceCapabilities) void {
        wgpuSurfaceGetCapabilities(self, adapter, capabilities);
    }
    pub inline fn getCurrentTexture(self: *Surface, surface_texture: *SurfaceTexture) void {
        wgpuSurfaceGetCurrentTexture(self, surface_texture);
    }
    pub inline fn present(self: *Surface) void {
        wgpuSurfacePresent(self);
    }
    pub inline fn setLabel(self: *Surface, label: ?[*:0]const u8) void {
        wgpuSurfaceSetLabel(self, label);
    }
    pub inline fn unconfigure(self: *Surface) void {
        wgpuSurfaceUnconfigure(self);
    }
    pub inline fn addRef(self: *Surface) void {
        wgpuSurfaceAddRef(self);
    }
    pub inline fn release(self: *Surface) void {
        wgpuSurfaceRelease(self);
    }
};