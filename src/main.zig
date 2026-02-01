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
    const fov_rad: f32 = 1.0 / sdl.SDL_tanf(fov * 0.5 / 180.0 * sdl.SDL_PI_F);

    const proj_matrix = math.create_projection(aspect_ratio, fov_rad, near, far);

    var f_theta: f32 = 0;

    var window: ?*sdl.SDL_Window = null;
    var renderer: ?*sdl.SDL_Renderer = null;

    // Unit cube
    const cube_mesh = [_]geometry.Triangle{
        // South
        .{ .p = .{ .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 0.0, .y = 1.0, .z = 0.0 }, .{ .x = 1.0, .y = 1.0, .z = 0.0 } } },
        .{ .p = .{ .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 1.0, .y = 1.0, .z = 0.0 }, .{ .x = 1.0, .y = 0.0, .z = 0.0 } } },

        // East
        .{ .p = .{ .{ .x = 1.0, .y = 0.0, .z = 0.0 }, .{ .x = 1.0, .y = 1.0, .z = 0.0 }, .{ .x = 1.0, .y = 1.0, .z = 1.0 } } },
        .{ .p = .{ .{ .x = 1.0, .y = 0.0, .z = 0.0 }, .{ .x = 1.0, .y = 1.0, .z = 1.0 }, .{ .x = 1.0, .y = 0.0, .z = 1.0 } } },

        // Noth
        .{ .p = .{ .{ .x = 1.0, .y = 0.0, .z = 1.0 }, .{ .x = 1.0, .y = 1.0, .z = 1.0 }, .{ .x = 0.0, .y = 1.0, .z = 1.0 } } },
        .{ .p = .{ .{ .x = 1.0, .y = 0.0, .z = 1.0 }, .{ .x = 0.0, .y = 1.0, .z = 1.0 }, .{ .x = 0.0, .y = 0.0, .z = 1.0 } } },

        // West
        .{ .p = .{ .{ .x = 0.0, .y = 0.0, .z = 1.0 }, .{ .x = 0.0, .y = 1.0, .z = 1.0 }, .{ .x = 0.0, .y = 1.0, .z = 0.0 } } },
        .{ .p = .{ .{ .x = 0.0, .y = 0.0, .z = 1.0 }, .{ .x = 0.0, .y = 1.0, .z = 0.0 }, .{ .x = 0.0, .y = 0.0, .z = 0.0 } } },

        // Top
        .{ .p = .{ .{ .x = 0.0, .y = 1.0, .z = 0.0 }, .{ .x = 0.0, .y = 1.0, .z = 1.0 }, .{ .x = 1.0, .y = 1.0, .z = 1.0 } } },
        .{ .p = .{ .{ .x = 0.0, .y = 1.0, .z = 0.0 }, .{ .x = 1.0, .y = 1.0, .z = 1.0 }, .{ .x = 1.0, .y = 1.0, .z = 0.0 } } },

        // Bottom
        .{ .p = .{ .{ .x = 1.0, .y = 0.0, .z = 1.0 }, .{ .x = 0.0, .y = 0.0, .z = 1.0 }, .{ .x = 0.0, .y = 0.0, .z = 0.0 } } },
        .{ .p = .{ .{ .x = 1.0, .y = 0.0, .z = 1.0 }, .{ .x = 0.0, .y = 0.0, .z = 0.0 }, .{ .x = 1.0, .y = 0.0, .z = 0.0 } } },
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

    var e: sdl.SDL_Event = undefined;
    var quit: bool = false;

    // Main loop
    while (!quit) {
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
        //_ = sdl.SDL_RenderLine(renderer, 0, 0, 640, 480);
        //_ = sdl.SDL_RenderLine(renderer, 0, 480, 640, 0);

        // rotation matricies
        f_theta += 1.0 * (1.0 / 30000.0);
        var rot_z_matrix: math.Matrix4x4 = std.mem.zeroes(math.Matrix4x4);
        rot_z_matrix[0][0] = sdl.SDL_cosf(f_theta);
        rot_z_matrix[0][1] = sdl.SDL_sinf(f_theta);
        rot_z_matrix[1][0] = -sdl.SDL_sinf(f_theta);
        rot_z_matrix[1][1] = sdl.SDL_cosf(f_theta);
        rot_z_matrix[2][2] = 1.0;
        rot_z_matrix[3][3] = 1.0;

        var rot_x_matrix: math.Matrix4x4 = std.mem.zeroes(math.Matrix4x4);
        rot_x_matrix[0][0] = 1;
        rot_x_matrix[1][1] = sdl.SDL_cosf(f_theta * 0.5);
        rot_x_matrix[1][2] = sdl.SDL_sinf(f_theta * 0.5);
        rot_x_matrix[2][1] = -sdl.SDL_sinf(f_theta * 0.5);
        rot_x_matrix[2][2] = sdl.SDL_cosf(f_theta * 0.5);
        rot_x_matrix[3][3] = 1.0;

        for (cube_mesh) |tri| {
            // Rotate in Z axis
            const tri_rotated_z = geometry.Triangle{ .p = .{ math.multiply_matrix_vector(tri.p[0], rot_z_matrix), math.multiply_matrix_vector(tri.p[1], rot_z_matrix), math.multiply_matrix_vector(tri.p[2], rot_z_matrix) } };

            // Rotate in X axis
            const tri_rotated_xz: geometry.Triangle = .{ .p = .{ math.multiply_matrix_vector(tri_rotated_z.p[0], rot_x_matrix), math.multiply_matrix_vector(tri_rotated_z.p[1], rot_x_matrix), math.multiply_matrix_vector(tri_rotated_z.p[2], rot_x_matrix) } };

            // Translate triangles
            const tri_translated: geometry.Triangle = .{ .p = .{
                .{ .x = tri_rotated_xz.p[0].x, .y = tri_rotated_xz.p[0].y, .z = tri_rotated_xz.p[0].z + 3.0 },
                .{ .x = tri_rotated_xz.p[1].x, .y = tri_rotated_xz.p[1].y, .z = tri_rotated_xz.p[1].z + 3.0 },
                .{ .x = tri_rotated_xz.p[2].x, .y = tri_rotated_xz.p[2].y, .z = tri_rotated_xz.p[2].z + 3.0 },
            } };

            // Project triangles in 3D space
            var tri_projected: geometry.Triangle = .{ .p = .{ math.multiply_matrix_vector(tri_translated.p[0], proj_matrix), math.multiply_matrix_vector(tri_translated.p[1], proj_matrix), math.multiply_matrix_vector(tri_translated.p[2], proj_matrix) } };

            // Scale into view
            tri_projected.p[0].x += 1.0;
            tri_projected.p[0].y += 1.0;

            tri_projected.p[1].x += 1.0;
            tri_projected.p[1].y += 1.0;

            tri_projected.p[2].x += 1.0;
            tri_projected.p[2].y += 1.0;

            tri_projected.p[0].x *= 0.5 * @as(f32, screen_width);
            tri_projected.p[0].y *= 0.5 * @as(f32, screen_height);

            tri_projected.p[1].x *= 0.5 * @as(f32, screen_width);
            tri_projected.p[1].y *= 0.5 * @as(f32, screen_height);

            tri_projected.p[2].x *= 0.5 * @as(f32, screen_width);
            tri_projected.p[2].y *= 0.5 * @as(f32, screen_height);

            // Draw projected triangles
            _ = sdl.SDL_RenderLine(renderer, tri_projected.p[0].x, tri_projected.p[0].y, tri_projected.p[1].x, tri_projected.p[1].y);
            _ = sdl.SDL_RenderLine(renderer, tri_projected.p[1].x, tri_projected.p[1].y, tri_projected.p[2].x, tri_projected.p[2].y);
            _ = sdl.SDL_RenderLine(renderer, tri_projected.p[2].x, tri_projected.p[2].y, tri_projected.p[0].x, tri_projected.p[0].y);
        }

        // Render to screen
        _ = sdl.SDL_RenderPresent(renderer);
    }

    sdl.SDL_Quit();
}
