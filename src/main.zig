const std = @import("std");
const zgame = @import("zgame");
const math = @import("math.zig");
const geometry = @import("geometry.zig");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {
    const screen_width: c_int = 640;
    const screen_height: c_int = 480;

    const near: f32 = 0.1;
    const far: f32 = 1000.0;
    const aspect_ratio = @as(f32, @floatFromInt(screen_width)) / @as(f32, @floatFromInt(screen_height));
    const fov: f32 = 90.0;
    const fov_rad: f32 = 1.0 / @tan(fov * 0.5 / 180.0 * sdl.SDL_PI_F);

    const proj_matrix = math.createProjection(aspect_ratio, fov_rad, near, far);

    var window: ?*sdl.SDL_Window = null;
    var renderer: ?*sdl.SDL_Renderer = null;

    // Unit cube
    const cube_mesh = [_]geometry.Triangle{
        // South
        .{ .p = .{ .{ 0.0, 0.0, 0.0, 1.0 }, .{ 0.0, 1.0, 0.0, 1.0 }, .{ 1.0, 1.0, 0.0, 1.0 } } },
        .{ .p = .{ .{ 0.0, 0.0, 0.0, 1.0 }, .{ 1.0, 1.0, 0.0, 1.0 }, .{ 1.0, 0.0, 0.0, 1.0 } } },

        // East
        .{ .p = .{ .{ 1.0, 0.0, 0.0, 1.0 }, .{ 1.0, 1.0, 0.0, 1.0 }, .{ 1.0, 1.0, 1.0, 1.0 } } },
        .{ .p = .{ .{ 1.0, 0.0, 0.0, 1.0 }, .{ 1.0, 1.0, 1.0, 1.0 }, .{ 1.0, 0.0, 1.0, 1.0 } } },

        // Noth
        .{ .p = .{ .{ 1.0, 0.0, 1.0, 1.0 }, .{ 1.0, 1.0, 1.0, 1.0 }, .{ 0.0, 1.0, 1.0, 1.0 } } },
        .{ .p = .{ .{ 1.0, 0.0, 1.0, 1.0 }, .{ 0.0, 1.0, 1.0, 1.0 }, .{ 0.0, 0.0, 1.0, 1.0 } } },

        // West
        .{ .p = .{ .{ 0.0, 0.0, 1.0, 1.0 }, .{ 0.0, 1.0, 1.0, 1.0 }, .{ 0.0, 1.0, 0.0, 1.0 } } },
        .{ .p = .{ .{ 0.0, 0.0, 1.0, 1.0 }, .{ 0.0, 1.0, 0.0, 1.0 }, .{ 0.0, 0.0, 0.0, 1.0 } } },

        // Top
        .{ .p = .{ .{ 0.0, 1.0, 0.0, 1.0 }, .{ 0.0, 1.0, 1.0, 1.0 }, .{ 1.0, 1.0, 1.0, 1.0 } } },
        .{ .p = .{ .{ 0.0, 1.0, 0.0, 1.0 }, .{ 1.0, 1.0, 1.0, 1.0 }, .{ 1.0, 1.0, 0.0, 1.0 } } },

        // Bottom
        .{ .p = .{ .{ 1.0, 0.0, 1.0, 1.0 }, .{ 0.0, 0.0, 1.0, 1.0 }, .{ 0.0, 0.0, 0.0, 1.0 } } },
        .{ .p = .{ .{ 1.0, 0.0, 1.0, 1.0 }, .{ 0.0, 0.0, 0.0, 1.0 }, .{ 1.0, 0.0, 0.0, 1.0 } } },
    };

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        const err = sdl.SDL_GetError();
        std.debug.print("SDL could not initialize! SDL_error {s}\n", .{err});
        return;
    }

    // Create window and renderer
    if (!sdl.SDL_CreateWindowAndRenderer("examples/renderer/primitives", screen_width, screen_height, sdl.SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        sdl.SDL_Log("Couldn't create window/renderer: %s", sdl.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer sdl.SDL_DestroyWindow(window);
    defer sdl.SDL_DestroyRenderer(renderer);

    _ = sdl.SDL_SetRenderLogicalPresentation(renderer, screen_width, screen_height, sdl.SDL_LOGICAL_PRESENTATION_LETTERBOX);

    var last_time: u64 = sdl.SDL_GetTicks();
    var f_theta: f32 = 0;
    var e: sdl.SDL_Event = undefined;
    var quit: bool = false;

    // Main loop
    while (!quit) {
        // Calculate delta time
        const current_time = sdl.SDL_GetTicks();
        const delta_time = @as(f32, @floatFromInt(current_time - last_time)) / 1000.0;
        last_time = current_time;

        // Handle events
        while (sdl.SDL_PollEvent(&e)) {
            if (e.type == sdl.SDL_EVENT_QUIT) {
                quit = true;
            }
        }

        // Clear screen
        _ = sdl.SDL_SetRenderDrawColor(renderer, 0, 0, 0, sdl.SDL_ALPHA_OPAQUE);
        _ = sdl.SDL_RenderClear(renderer);

        // Draw lines
        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);

        // rotation matricies
        f_theta += 1.0 * delta_time;
        var rot_z_matrix: math.Matrix4x4 = std.mem.zeroes(math.Matrix4x4);
        rot_z_matrix.cols[0][0] = @cos(f_theta);
        rot_z_matrix.cols[1][0] = @sin(f_theta);
        rot_z_matrix.cols[0][1] = -@sin(f_theta);
        rot_z_matrix.cols[1][1] = @cos(f_theta);
        rot_z_matrix.cols[2][2] = 1.0;
        rot_z_matrix.cols[3][3] = 1.0;

        var rot_x_matrix: math.Matrix4x4 = std.mem.zeroes(math.Matrix4x4);
        rot_x_matrix.cols[0][0] = 1;
        rot_x_matrix.cols[1][1] = @cos(f_theta * 0.5);
        rot_x_matrix.cols[2][1] = @sin(f_theta * 0.5);
        rot_x_matrix.cols[1][2] = -@sin(f_theta * 0.5);
        rot_x_matrix.cols[2][2] = @cos(f_theta * 0.5);
        rot_x_matrix.cols[3][3] = 1.0;

        for (cube_mesh) |tri| {
            // Rotate in Z axis
            const tri_rotated_z = tri.matrixMultiply(rot_z_matrix);

            // Rotate in X axis
            var tri_rotated_xz = tri_rotated_z.matrixMultiply(rot_x_matrix);

            //std.debug.print("Before ({d}, {d}, {d})\n", .{ tri_rotated_xz.p[0][0], tri_rotated_xz.p[0][1], tri_rotated_xz.p[0][2] });
            // Translate triangles
            tri_rotated_xz.translate(0.0, 0.0, 3.0);
            //std.debug.print("After ({d}, {d}, {d})\n", .{ tri_rotated_xz.p[0][0], tri_rotated_xz.p[0][1], tri_rotated_xz.p[0][2] });

            const normal = tri_rotated_xz.calculateNormal();

            if (normal[2] < 0.0) {
                // Project triangles in 3D space
                var tri_projected = tri_rotated_xz.matrixMultiply(proj_matrix);

                // Normalize coords
                tri_projected.normalizeCoordinates();

                // Scale into view
                tri_projected.translate(1, 1, 0);
                tri_projected.multiply(0.5 * @as(f32, screen_width), 0.5 * @as(f32, screen_height), 1.0);

                // Draw projected triangles
                _ = sdl.SDL_RenderLine(renderer, tri_projected.p[0][0], tri_projected.p[0][1], tri_projected.p[1][0], tri_projected.p[1][1]);
                _ = sdl.SDL_RenderLine(renderer, tri_projected.p[1][0], tri_projected.p[1][1], tri_projected.p[2][0], tri_projected.p[2][1]);
                _ = sdl.SDL_RenderLine(renderer, tri_projected.p[2][0], tri_projected.p[2][1], tri_projected.p[0][0], tri_projected.p[0][1]);
            }
        }

        // Render to screen
        _ = sdl.SDL_RenderPresent(renderer);
    }

    sdl.SDL_Quit();
}
