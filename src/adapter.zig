const _chained_struct = @import("chained_struct.zig");
const ChainedStruct = _chained_struct.ChainedStruct;
const ChainedStructOut = _chained_struct.ChainedStructOut;

const _misc = @import("misc.zig");
const WGPUBool = _misc.WGPUBool;
const FeatureName = _misc.FeatureName;

const SupportedLimits = @import("limits.zig").SupportedLimits;

const Surface = @import("surface.zig").Surface;

const _device = @import("device.zig");
const Device = _device.Device;
const DeviceDescriptor = _device.DeviceDescriptor;
const AdapterRequestDeviceCallback = _device.AdapterRequestDeviceCallback;
const RequestDeviceStatus = _device.RequestDeviceStatus;
const RequestDeviceResponse = _device.RequestDeviceResponse;

pub const PowerPreference = enum(u32) {
    @"undefined"        = 0x00000000, // No preference.
    low_power           = 0x00000001,
    high_performance    = 0x00000002,
};

pub const AdapterType = enum(u32) {
    discrete_gpu   = 0x00000001,
    integrated_gpu = 0x00000002,
    cpu            = 0x00000003,
    unknown        = 0x00000004,
};

pub const BackendType = enum(u32) {
    @"undefined" = 0x00000000, // Indicates no value is passed for this argument
    null         = 0x00000001,
    webgpu       = 0x00000002,
    d3d11        = 0x00000003,
    d3d12        = 0x00000004,
    metal        = 0x00000005,
    vulkan       = 0x00000006,
    opengl       = 0x00000007,
    opengl_es    = 0x00000008,
};

pub const FeatureLevel = enum(u32) {
    compatibility = 0x00000001, // "Compatibility" profile which can be supported on OpenGL ES 3.1.
    core          = 0x00000002, // "Core" profile which can be supported on Vulkan/Metal/D3D12.
};

pub const RequestAdapterOptions = extern struct {
    next_in_chain: ?*const ChainedStruct = null,
    compatible_surface: ?*Surface = null,
    power_preference: PowerPreference = PowerPreference.@"undefined",
    backend_type: BackendType = BackendType.@"undefined",
    force_fallback_adapter: WGPUBool = @intFromBool(false),
};

pub const RequestAdapterStatus = enum(u32) {
    success          = 0x00000001,
    instance_dropped = 0x00000002,
    unavailable      = 0x00000003,
    @"error"         = 0x00000004,
    unknown          = 0x00000005,
};

// TODO: This should maybe be relocated to instance.zig; it is only used there.
pub const InstanceRequestAdapterCallback = *const fn(status: RequestAdapterStatus, adapter: ?*Adapter, message: ?[*:0]const u8, userdata: ?*anyopaque) callconv(.C) void;

pub const RequestAdapterResponse = struct {
    status: RequestAdapterStatus,
    message: ?[*:0]const u8,
    adapter: ?*Adapter,
};

pub const AdapterInfoProcs = struct {
    pub const FreeMembers = *const fn(AdapterInfo) callconv(.C) void;
};

extern fn wgpuAdapterInfoFreeMembers(adapter_info: AdapterInfo) void;

pub const AdapterInfo = extern struct {
    next_in_chain: ?*ChainedStructOut = null,
    vendor: [*:0]const u8,
    architecture: [*:0]const u8,
    device: [*:0]const u8,
    description: [*:0]const u8,
    backend_type: BackendType,
    adapter_type: AdapterType,
    vendor_id: u32,
    device_id: u32,

    pub inline fn freeMembers(self: AdapterInfo) void {
        wgpuAdapterInfoFreeMembers(self);
    }
};

pub const AdapterProcs = struct {
    pub const EnumerateFeatures = *const fn(Adapter, ?[*]FeatureName) callconv(.C) usize;
    pub const GetLimits = *const fn(Adapter, *SupportedLimits) callconv(.C) WGPUBool;
    pub const GetInfo = *const fn(Adapter, *AdapterInfo) callconv(.C) void;
    pub const HasFeature = *const fn(Adapter, FeatureName) callconv(.C) WGPUBool;
    pub const RequestDevice = *const fn(Adapter, ?*const DeviceDescriptor, AdapterRequestDeviceCallback, ?*anyopaque) callconv(.C) void;
    pub const AddRef = *const fn(Adapter) callconv(.C) void;
    pub const Release = *const fn(Adapter) callconv(.C) void;
};

extern fn wgpuAdapterEnumerateFeatures(adapter: *Adapter, features: ?[*]FeatureName) usize;
extern fn wgpuAdapterGetLimits(adapter: *Adapter, limits: *SupportedLimits) WGPUBool;
extern fn wgpuAdapterGetInfo(adapter: *Adapter, info: *AdapterInfo) void;
extern fn wgpuAdapterHasFeature(adapter: *Adapter, feature: FeatureName) WGPUBool;
extern fn wgpuAdapterRequestDevice(adapter: *Adapter, descriptor: ?*const DeviceDescriptor, callback: AdapterRequestDeviceCallback, userdata: ?*anyopaque) void;
extern fn wgpuAdapterAddRef(adapter: *Adapter) void;
extern fn wgpuAdapterRelease(adapter: *Adapter) void;

pub const Adapter = opaque{
    pub inline fn enumerateFeatures(self: *Adapter, features: ?[*]FeatureName) usize {
        return wgpuAdapterEnumerateFeatures(self, features);
    }
    pub inline fn getLimits(self: *Adapter, limits: *SupportedLimits) bool {
        return wgpuAdapterGetLimits(self, limits) != 0;
    }
    pub inline fn getInfo(self: *Adapter, info: *AdapterInfo) void {
        wgpuAdapterGetInfo(self, info);
    }
    pub inline fn hasFeature(self: *Adapter, feature: FeatureName) bool {
        return wgpuAdapterHasFeature(self, feature) != 0;
    }

    fn defaultDeviceCallback(status: RequestDeviceStatus, device: ?*Device, message: ?[*:0]const u8, userdata: ?*anyopaque) callconv(.C) void {
        const ud_response: *RequestDeviceResponse = @ptrCast(@alignCast(userdata));
        ud_response.* = RequestDeviceResponse {
            .status = status,
            .message = message,
            .device = device,
        };
    }
    pub fn requestDeviceSync(self: *Adapter, descriptor: ?*const DeviceDescriptor) RequestDeviceResponse {
        var response: RequestDeviceResponse = undefined;
        wgpuAdapterRequestDevice(self, descriptor, defaultDeviceCallback, @ptrCast(&response));
        return response;
    }
    pub inline fn requestDevice(self: *Adapter, descriptor: ?*const DeviceDescriptor, callback: AdapterRequestDeviceCallback, userdata: ?*anyopaque) void {
        wgpuAdapterRequestDevice(self, descriptor, callback, userdata);
    }
    pub inline fn addRef(self: *Adapter) void {
        wgpuAdapterAddRef(self);
    }
    pub inline fn release(self: *Adapter) void {
        wgpuAdapterRelease(self);
    }
};

test "can request device" {
    const testing = @import("std").testing;

    const Instance = @import("instance.zig").Instance;
    const instance = Instance.create(null);
    const adapter_response = instance.?.requestAdapterSync(null);
    const adapter: ?*Adapter = switch(adapter_response.status) {
        .success => adapter_response.adapter,
        else => null,
    };
    const device_response = adapter.?.requestDeviceSync(null);
    const device: ?*Device = switch(device_response.status) {
        .success => device_response.device,
        else => null
    };
    try testing.expect(device != null);
}