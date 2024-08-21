const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(std.builtin.LinkMode, "linkage", "Specify static or dynamic linkage") orelse .dynamic;
    const upstream = b.dependency("cyclonedds", .{});
    var lib = std.Build.Step.Compile.create(b, .{
        .root_module = .{
            .target = target,
            .optimize = optimize,
        },
        .name = "cyclonedds",
        .kind = .lib,
        .linkage = linkage,
    });

    lib.linkLibC();

    // These config headers are taken from the ROS Jazzy install wherever possible
    const features = b.addConfigHeader(
        .{
            .style = .{ .cmake = upstream.path("src/ddsrt/include/dds/features.h.in") },
            .include_path = "dds/features.h",
        },
        .{
            .DDS_HAS_SECURITY = 1,
            .DDS_HAS_LIFESPAN = 1,
            .DDS_HAS_DEADLINE_MISSED = 1,
            .DDS_HAS_NETWORK_PARTITIONS = 1,
            .DDS_HAS_SSM = 1,
            .DDS_HAS_SSL = 0, // TODO this is on in ROS but I don't have a build for ssl yet
            .DDS_HAS_TYPE_DISCOVERY = 1,
            .DDS_HAS_TOPIC_DISCOVERY = 1,
            .DDS_HAS_SHM = 0, // TODO this is on in ROS but we don't build iceoryx yet.
        },
    );
    lib.addConfigHeader(features);
    lib.installConfigHeader(features);

    const version = b.addConfigHeader(
        .{
            .style = .{ .cmake = upstream.path("src/ddsrt/include/dds/version.h.in") },
            .include_path = "dds/version.h",
        },
        .{
            .DDS_VERSION = "0.10.5",
            .DDS_VERSION_MAJOR = 0,
            .DDS_VERSION_MINOR = 10,
            .DDS_VERSION_PATCH = 5,
            .DDS_VERSION_TWEAK = "",
            .DDS_PROJECT_NAME = "CycloneDDS",
            .DDS_HOST_NAME = "Linux",
            .DDS_TARGET_NAME = "Linux",
        },
    );
    lib.addConfigHeader(version);
    lib.installConfigHeader(version);

    const config = b.addConfigHeader(
        .{
            .style = .{ .cmake = upstream.path("src/ddsrt/include/dds/config.h.in") },
            .include_path = "dds/config.h",
        },
        .{
            .DDSRT_HAVE_DYNLIB = 1,
            .DDSRT_HAVE_FILESYSTEM = 1,
            .DDSRT_HAVE_NETSTAT = 1,
            .DDSRT_HAVE_RUSAGE = 1,
            .DDSRT_HAVE_IPV6 = 1,
            .DDSRT_HAVE_DNS = 1,
            .DDSRT_HAVE_GETADDRINFO = 1,
            .DDSRT_HAVE_GETHOSTBYNAME_R = 1,
            .DDSRT_HAVE_GETHOSTNAME = 1,
            .DDSRT_HAVE_INET_NTOP = 1,
            .DDSRT_HAVE_INET_PTON = 1,
        },
    );
    lib.addConfigHeader(config);
    lib.installConfigHeader(config);

    // For export.h, taken from the ROS Jazzy install
    lib.addIncludePath(b.path("include"));
    lib.installHeader(b.path("include/dds/export.h"), "dds/export.h");

    lib.addIncludePath(upstream.path("src/ddsrt/include"));
    lib.installHeadersDirectory(upstream.path("src/ddsrt/include"), "", .{});
    lib.addIncludePath(upstream.path("src/ddsrt/src")); // For internal stuff
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &ddsrt_sources_common,
    });

    // TODO finish windows support, currently this doesn't work.
    if (target.result.os.tag == .windows) {
        lib.addCSourceFiles(.{
            .root = upstream.path(""),
            .files = &ddsrt_sources_windows,
        });
    } else {
        lib.addCSourceFiles(.{
            .root = upstream.path(""),
            .files = &ddsrt_sources_linux,
        });
    } // TODO MacOS support, freertos support?

    lib.addIncludePath(upstream.path("src/core/ddsc/include"));
    lib.installHeadersDirectory(upstream.path("src/core/ddsc/include"), "", .{});
    lib.addIncludePath(upstream.path("src/core/ddsc/src")); // For internal stuff
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &ddsc_sources,
    });

    lib.addIncludePath(upstream.path("src/core/ddsi/include"));
    lib.installHeadersDirectory(upstream.path("src/core/ddsi/include"), "", .{});
    lib.addIncludePath(upstream.path("src/core/ddsi/src")); // for internal stuff
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &ddsi_sources,
    });

    // For cyclonedds 0.11
    // lib.addIncludePath(upstream.path("cyclonedds/src/core/cdr/include"));
    // lib.addCSourceFiles(.{
    //     .files = &cyclonedds_cdr_sources,
    // });

    lib.addIncludePath(upstream.path("src/security/core/include"));
    lib.installHeadersDirectory(upstream.path("src/security/core/include"), "", .{});
    lib.addIncludePath(upstream.path("src/security/api/include"));
    lib.installHeadersDirectory(upstream.path("src/security/api/include"), "", .{});
    lib.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &cyclonedds_security_sources,
    });
    b.installArtifact(lib);
}

const cyclonedds_security_sources = [_][]const u8{
    "src/security/core/src/dds_security_fsm.c",
    "src/security/core/src/dds_security_plugins.c",
    "src/security/core/src/dds_security_serialize.c",
    "src/security/core/src/dds_security_timed_cb.c",
    "src/security/core/src/dds_security_utils.c",
    "src/security/core/src/shared_secret.c",
};
// Used in version 0.11, needed to go to 0.10 for ros support
// const cyclonedds_cdr_sources = [_][]const u8{
//     "src/core/cdr/src/dds_cdrstream.c",
//     // TODO these part files don't seem to compile on their own
//     // "src/core/cdr/src/dds_cdrstream_keys.part.c",
//     // "src/core/cdr/src/dds_cdrstream_write.part.c",
// };

const ddsi_sources = [_][]const u8{
    "src/core/ddsi/src/ddsi_acknack.c",
    "src/core/ddsi/src/ddsi_cdrstream.c",
    // TODO these part files don't seem to compile on their own
    // "src/core/ddsi/src/ddsi_cdrstream_keys.part.c",
    // "src/core/ddsi/src/ddsi_cdrstream_write.part.c",
    "src/core/ddsi/src/ddsi_config.c",
    "src/core/ddsi/src/ddsi_deadline.c",
    "src/core/ddsi/src/ddsi_deliver_locally.c",
    "src/core/ddsi/src/ddsi_endpoint.c",
    "src/core/ddsi/src/ddsi_entity.c",
    "src/core/ddsi/src/ddsi_entity_index.c",
    "src/core/ddsi/src/ddsi_entity_match.c",
    "src/core/ddsi/src/ddsi_eth.c",
    "src/core/ddsi/src/ddsi_handshake.c",
    "src/core/ddsi/src/ddsi_iid.c",
    "src/core/ddsi/src/ddsi_ipaddr.c",
    "src/core/ddsi/src/ddsi_lifespan.c",
    "src/core/ddsi/src/ddsi_list_genptr.c",
    "src/core/ddsi/src/ddsi_mcgroup.c",
    "src/core/ddsi/src/ddsi_ownip.c",
    "src/core/ddsi/src/ddsi_participant.c",
    "src/core/ddsi/src/ddsi_plist.c",
    "src/core/ddsi/src/ddsi_pmd.c",
    "src/core/ddsi/src/ddsi_portmapping.c",
    "src/core/ddsi/src/ddsi_proxy_endpoint.c",
    "src/core/ddsi/src/ddsi_proxy_participant.c",
    "src/core/ddsi/src/ddsi_raweth.c",
    "src/core/ddsi/src/ddsi_rhc.c",
    "src/core/ddsi/src/ddsi_security_exchange.c",
    "src/core/ddsi/src/ddsi_security_msg.c",
    "src/core/ddsi/src/ddsi_security_omg.c",
    "src/core/ddsi/src/ddsi_security_util.c",
    "src/core/ddsi/src/ddsi_serdata.c",
    "src/core/ddsi/src/ddsi_serdata_default.c",
    "src/core/ddsi/src/ddsi_serdata_plist.c",
    "src/core/ddsi/src/ddsi_serdata_pserop.c",
    "src/core/ddsi/src/ddsi_sertopic.c",
    "src/core/ddsi/src/ddsi_sertype.c",
    "src/core/ddsi/src/ddsi_sertype_default.c",
    "src/core/ddsi/src/ddsi_sertype_plist.c",
    "src/core/ddsi/src/ddsi_sertype_pserop.c",
    // "src/core/ddsi/src/ddsi_shm_transport.c", // No shared mem for now so we don't need to build iceoryx
    "src/core/ddsi/src/ddsi_ssl.c",
    "src/core/ddsi/src/ddsi_statistics.c",
    "src/core/ddsi/src/ddsi_tcp.c",
    "src/core/ddsi/src/ddsi_threadmon.c",
    "src/core/ddsi/src/ddsi_time.c",
    "src/core/ddsi/src/ddsi_tkmap.c",
    "src/core/ddsi/src/ddsi_topic.c",
    "src/core/ddsi/src/ddsi_tran.c",
    "src/core/ddsi/src/ddsi_typebuilder.c",
    "src/core/ddsi/src/ddsi_typelib.c",
    "src/core/ddsi/src/ddsi_typelookup.c",
    "src/core/ddsi/src/ddsi_typewrap.c",
    "src/core/ddsi/src/ddsi_udp.c",
    "src/core/ddsi/src/ddsi_vendor.c",
    "src/core/ddsi/src/ddsi_vnet.c",
    "src/core/ddsi/src/ddsi_wraddrset.c",
    "src/core/ddsi/src/ddsi_xt_typeinfo.c",
    "src/core/ddsi/src/ddsi_xt_typelookup.c",
    "src/core/ddsi/src/ddsi_xt_typemap.c",
    "src/core/ddsi/src/q_addrset.c",
    "src/core/ddsi/src/q_bitset_inlines.c",
    "src/core/ddsi/src/q_bswap.c",
    "src/core/ddsi/src/q_ddsi_discovery.c",
    "src/core/ddsi/src/q_debmon.c",
    "src/core/ddsi/src/q_freelist.c",
    "src/core/ddsi/src/q_gc.c",
    "src/core/ddsi/src/q_init.c",
    "src/core/ddsi/src/q_inverse_uint32_set.c",
    "src/core/ddsi/src/q_lat_estim.c",
    "src/core/ddsi/src/q_lease.c",
    "src/core/ddsi/src/q_misc.c",
    "src/core/ddsi/src/q_pcap.c",
    "src/core/ddsi/src/q_qosmatch.c",
    "src/core/ddsi/src/q_radmin.c",
    "src/core/ddsi/src/q_receive.c",
    "src/core/ddsi/src/q_sockwaitset.c",
    "src/core/ddsi/src/q_thread.c",
    "src/core/ddsi/src/q_transmit.c",
    "src/core/ddsi/src/q_whc.c",
    "src/core/ddsi/src/q_xevent.c",
    "src/core/ddsi/src/q_xmsg.c",
    "src/core/ddsi/src/sysdeps.c",
};
const ddsc_sources = [_][]const u8{
    "src/core/ddsc/src/dds_alloc.c",
    "src/core/ddsc/src/dds_builtin.c",
    "src/core/ddsc/src/dds_coherent.c",
    "src/core/ddsc/src/dds_data_allocator.c",
    "src/core/ddsc/src/dds_domain.c",
    "src/core/ddsc/src/dds_entity.c",
    "src/core/ddsc/src/dds_guardcond.c",
    "src/core/ddsc/src/dds_handles.c",
    "src/core/ddsc/src/dds_init.c",
    "src/core/ddsc/src/dds_instance.c",
    "src/core/ddsc/src/dds_listener.c",
    "src/core/ddsc/src/dds_loan.c",
    "src/core/ddsc/src/dds_matched.c",
    "src/core/ddsc/src/dds_participant.c",
    "src/core/ddsc/src/dds_publisher.c",
    "src/core/ddsc/src/dds_qos.c",
    "src/core/ddsc/src/dds_querycond.c",
    "src/core/ddsc/src/dds_read.c",
    "src/core/ddsc/src/dds_readcond.c",
    "src/core/ddsc/src/dds_reader.c",
    "src/core/ddsc/src/dds_rhc.c",
    "src/core/ddsc/src/dds_rhc_default.c",
    "src/core/ddsc/src/dds_serdata_builtintopic.c",
    "src/core/ddsc/src/dds_sertype_builtintopic.c",
    "src/core/ddsc/src/dds_statistics.c",
    "src/core/ddsc/src/dds_subscriber.c",
    "src/core/ddsc/src/dds_topic.c",
    "src/core/ddsc/src/dds_waitset.c",
    "src/core/ddsc/src/dds_whc_builtintopic.c",
    "src/core/ddsc/src/dds_whc.c",
    "src/core/ddsc/src/dds_write.c",
    "src/core/ddsc/src/dds_writer.c",
    // "src/core/ddsc/src/shm_monitor.c", // no shared mem for now so we don't need to build iceoryx
};

const ddsrt_sources_linux = [_][]const u8{
    "src/ddsrt/src/dynlib/posix/dynlib.c", // Required for security, which uses pluggins (shouldn't impact base static build?)
    "src/ddsrt/src/environ/posix/environ.c",
    "src/ddsrt/src/filesystem/posix/filesystem.c",
    "src/ddsrt/src/heap/posix/heap.c",
    "src/ddsrt/src/ifaddrs/posix/ifaddrs.c",
    "src/ddsrt/src/process/posix/process.c",
    "src/ddsrt/src/random/posix/random.c",
    "src/ddsrt/src/rusage/posix/rusage.c",
    "src/ddsrt/src/sockets/posix/gethostname.c",
    "src/ddsrt/src/sockets/posix/socket.c",
    "src/ddsrt/src/threads/posix/threads.c",
    "src/ddsrt/src/time/posix/time.c",
    "src/ddsrt/src/netstat/linux/netstat.c",
    "src/ddsrt/src/sync/posix/sync.c", // TODO make multi platform?
};

const ddsrt_sources_windows = [_][]const u8{
    "src/ddsrt/src/heap/posix/heap.c", // Windows seems to use the posix heap as well in the cyclone cmakelist
    "src/ddsrt/src/dynlib/windows/dynlib.c",
    "src/ddsrt/src/environ/windows/environ.c",
    "src/ddsrt/src/filesystem/windows/filesystem.c",
    "src/ddsrt/src/netstat/windows/netstat.c",
    "src/ddsrt/src/process/windows/process.c",
    "src/ddsrt/src/random/windows/random.c",
    "src/ddsrt/src/rusage/windows/rusage.c",
    "src/ddsrt/src/sync/windows/sync.c",
    "src/ddsrt/src/threads/windows/threads.c",
    "src/ddsrt/src/time/windows/time.c",
    "src/ddsrt/src/ifaddrs/windows/ifaddrs.c",
    "src/ddsrt/src/sockets/windows/socket.c",
    "src/ddsrt/src/sockets/windows/gethostname.c",
};

const ddsrt_sources_common = [_][]const u8{
    // TODO make multi platform
    "src/ddsrt/src/atomics.c",
    "src/ddsrt/src/avl.c",
    "src/ddsrt/src/bswap.c",
    "src/ddsrt/src/cdtors.c",
    "src/ddsrt/src/circlist.c",
    "src/ddsrt/src/environ.c",
    "src/ddsrt/src/expand_vars.c",
    "src/ddsrt/src/fibheap.c",
    "src/ddsrt/src/hopscotch.c",
    "src/ddsrt/src/ifaddrs.c",
    "src/ddsrt/src/io.c",
    "src/ddsrt/src/log.c",
    "src/ddsrt/src/md5.c",
    "src/ddsrt/src/mh3.c",
    "src/ddsrt/src/random.c",
    "src/ddsrt/src/retcode.c",
    "src/ddsrt/src/sockets.c",
    "src/ddsrt/src/string.c",
    "src/ddsrt/src/strtod.c",
    "src/ddsrt/src/strtol.c",
    "src/ddsrt/src/threads.c",
    "src/ddsrt/src/time.c",
    "src/ddsrt/src/xmlparser.c",
};
