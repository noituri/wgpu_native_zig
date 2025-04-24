pub const WGPU_WHOLE_SIZE = @as(u64, 0xffffffffffffffff);

pub const WGPUBool = u32;
pub const WGPUFlags = u32;

// Used by both device and adapter
// FeatureName, Limits, and SupportedLimits are clearly related
// but idk if they should go in device.zig, adapter.zig, or their own separate file.
// So they're going in the "miscellaneous" pile for now.
pub const FeatureName = enum(u32) {
    @"undefined"                                                  = 0x00000000,
    depth_clip_control                                            = 0x00000001,
    depth32_float_stencil8                                        = 0x00000002,
    timestamp_query                                               = 0x00000003,
    texture_compression_bc                                        = 0x00000004,
    texture_compression_etc2                                      = 0x00000005,
    texture_compression_astc                                      = 0x00000006,
    indirect_first_instance                                       = 0x00000007,
    shader_f16                                                    = 0x00000008,
    rg11b10_ufloat_renderable                                     = 0x00000009,
    bgra8_unorm_storage                                           = 0x0000000A,
    float32_filterable                                            = 0x0000000B,

    // wgpu-native extras
    push_constants                                                = 0x00030001,
    texture_adapter_specific_format_features                      = 0x00030002,
    multi_draw_indirect                                           = 0x00030003,
    multi_draw_indirect_count                                     = 0x00030004,
    vertex_writable_storage                                       = 0x00030005,
    texture_binding_array                                         = 0x00030006,
    sampled_texture_and_storage_buffer_array_non_uniform_indexing = 0x00030007,
    pipeline_statistics_query                                     = 0x00030008,
    storage_resource_binding_array                                = 0x00030009,
    partially_bound_binding_array                                 = 0x0003000A,
    texture_format_16bit_norm                                     = 0x0003000B,
    texture_compression_astc_hdr                                  = 0x0003000C,
    mappable_primary_buffers                                      = 0x0003000E,
    buffer_binding_array                                          = 0x0003000F,
    uniform_buffer_and_storage_texture_array_non_uniform_indexing = 0x00030010,
    vertex_attribute_64bit                                        = 0x00030019,
    texture_format_nv12                                           = 0x0003001A,
    ray_tracing_acceleration_structure                            = 0x0003001B,
    ray_query                                                     = 0x0003001C,
    shader_f64                                                    = 0x0003001D,
    shader_i16                                                    = 0x0003001E,
    shader_primitive_index                                        = 0x0003001F,
    shader_early_depth_test                                       = 0x00030020,
    subgroup                                                      = 0x00030021,
    subgroup_vertex                                               = 0x00030022,
    subgroup_barrier                                              = 0x00030023,
    timestamp_query_inside_encoders                               = 0x00030024,
    timestamp_query_inside_passes                                 = 0x00030025,
    feature_force32                                               = 0x7FFFFFFF,
};

pub const IndexFormat = enum(u32) {
    @"undefined" = 0x00000000,
    uint16       = 0x00000001,
    uint32       = 0x00000002,
};

pub const CompareFunction = enum(u32) {
    @"undefined"  = 0x00000000,
    never         = 0x00000001,
    less          = 0x00000002,
    less_equal    = 0x00000003,
    greater       = 0x00000004,
    greater_equal = 0x00000005,
    equal         = 0x00000006,
    not_equal     = 0x00000007,
    always        = 0x00000008,
};

extern fn wgpuGetVersion() u32;
pub inline fn getVersion() u32 {
    return wgpuGetVersion();
}