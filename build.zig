const std = @import("std");
const ChildProcess = std.ChildProcess;
const HttpClient = std.net.http.client.Client;

const checkra1n_version = "0.1337.1";
const checkra1n_name = ""; // empty for all

//pub fn downloadFile(url: []const u8, output_path: []const u8) ?void {
//    const client = try HttpClient.init(std.heap.page_allocator, std.time.SystemClock.init());
//    defer client.deinit();
//
//    const request = try client.getRequest(@as_slice(url)) orelse return error.FileNotFound;
//
//    const response = try request.perform() orelse return error.DownloadingFileFailed;
//    defer response.deinit();
//
//    const status_code = try response.getStatusCode();
//    if (status_code != 200) {
//        return error.DownloadingFileFailed;
//    }
//
//    const output_file = try std.fs.cwd().createFile(output_path, .{});
//    defer output_file.close();
//
//    const output_stream = try output_file.writer();
//    defer output_stream.flush();
//
//    const input_stream = response.bodyReader();
//    defer input_stream.close();
//
//    var buffer: [4096]u8 = undefined;
//    while (input_stream.read(buffer) |read|) {
//        try output_stream.writeAll(buffer[0..read]);
//    }
//}

//fn dldeps(b: *Builder, step: *StepCallback) !void {
//    downloadFile(std.fmt("https://assets.checkra.in/downloads/preview/{}/{}", checkra1n_version, filename));
//}

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});

    const dlcdeps = try b.addSystemCommand(
        &[_][]const u8{
            "sh",
            "download_deps.sh",
        });

    const build_date = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "sh",
            "-c",
            "'LANG=C date'",
        },
    });

    const build_number = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "git",
            "rev-list",
            "--count",
            "HEAD",
        },
    });

    const build_tag = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "git,
            "describe",
            "--dirty",
            "--tags",
            "--abbrev=7",
        },
    });

    const build_whoami = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "whoami",
        },
    });
    const build_branch = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "git",
            "rev-parse",
            "--abbrev-ref",
            "HEAD",
        },
    });
    const build_commit = try ChildProcess.exec(.{
        .allocator = std.heap.page_allocator,
        .argv = &[_][]const u8{
            "git",
            "rev-parse",
            "HEAD",
        },
    });

    const flags = [_][]const u8{
        "-Wall",
        "-Wextra",
        "-Werror=return-type",
    };
    const cflags = flags ++ [_][]const u8{
        "-std=c99",
    };

    const cxxflags = cflags ++ [_][]const u8{
        "-std=c++17", "-fno-exceptions",
    };

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, ReleaseSmallSafe (custom) and ReleaseSmall.
    const mode = b.standardReleaseOptions() ++ {name: "ReleaseSmallSafe", is_release: true, is_small: true, is_safe: true, is_fast: false};

    const exe = b.addExecutable("palera1n", null);
    exe.addCSourceFile("src/main.c");
    exe.addCSourceFile("src/dfuhelper.c");
    exe.addCSourceFile("src/devhelper.c");
    exe.addCSourceFile("src/lockdown_helper.c");
    exe.addCSourceFile("src/optparse.c");
    exe.addCSourceFile("src/override_file.c");
    exe.addCSourceFile("src/log.c");
    exe.addCSourceFile("src/lock_vars.c");
    exe.addCSourceFile("src/credits.c");
    exe.addCSourceFile("src/fake_embedded.c");
    exe.addCSourceFile("src/exec_checkra1n.c");
    exe.addCSourceFile("src/pongo_helper.c");
    exe.addCSourceFile("src/boyermoore_memmem.c");

    exe.addCIncludeDir("include");



    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    if(checkra1n_name != ""){
        const dl_cmd = b.addSystemCommand(&[_][]const u8{
            "curl",
            "-LO",
            std.fmt("https://assets.checkra.in/downloads/preview/{}/{}", checkra1n_version, checkra1n_name)
        })
    }
    else {
        const dl_cmd = b.addSystemCommand(&[_][]const u8{
            "sh",
            "-c",
            std.fmt("'curl -LOOOOO https://assets.checkra.in/downloads/preview/{}/checkra1n-macos https://assets.checkra.in/downloads/preview/{}/checkra1n-linux-x86_64 https://assets.checkra.in/downloads/preview/{}/checkra1n-linux-x86 https://assets.checkra.in/downloads/preview/{}/checkra1n-armel https://assets.checkra.in/downloads/preview/{}/checkra1n-arm64 && chmod 755 checkra1n-*'", checkra1n_version, checkra1n_version, checkra1n_version, checkra1n_version, checkra1n_version)
        })
    }
    const dl_step = b.step("download-deps", "Download dependencies");
    dl_step.dependOn();

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}
