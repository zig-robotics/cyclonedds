# Zig package for Cyclone dds

This provides a zig package for the Cyclonedds project.
This particular build is intended to be used with ROS2 and its features and configuration match that as of ROS2 Jazzy.
With that said it should work fine stand alone.
This currently targets zig 0.13 and Cyclone 0.10.5.

## Windows support

Windows specific source files have been added, but issues were encountered when trying to cross compile.
Cyclonedds uses the capitalized "Windows.h" and "VersionHelpers.h", while mingw provides all headers with lower case names.
It is possible to get windows builds to cross compile if you either specify a clang vfs as outlined in this closed issue: https://github.com/ziglang/zig/issues/6486
or creating symbolic links locally in `zig-linux-x86_64-0.13.0/lib/libc/include/any-windows-any/versionhelpers.h` and `zig-linux-x86_64-0.13.0/lib/libc/include/any-windows-any/windows.h`.
Note that while this does build, it encounters linker errors that have not been sorted out.

## TODO
 - Windows support
 - Mac support
 - LWIP
 - SSL
 - Shared Memory (Iceoryx)

https://github.com/eclipse-cyclonedds/cyclonedds/tree/releases/0.10.x
