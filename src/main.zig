const std = @import("std");
const zgame = @import("zgame");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {
    const screen_width: c_int = 640;
    const screen_height: c_int = 480;

    var window: ?*sdl.SDL_Window = undefined;

    var screen_surface: *sdl.SDL_Surface = undefined;

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        const err = sdl.SDL_GetError();
        std.debug.print("SDL could not initialize! SDL_error {s}\n", .{err});
    } else {
        // Create window
        window = sdl.SDL_CreateWindow("SDL Tutorial", screen_width, screen_height, sdl.SDL_EVENT_WINDOW_SHOWN);

        if (window == null) {
            const err = sdl.SDL_GetError();
            std.debug.print("Window could not be created. SDL_Error: {s}\n", .{err});
        } else {
            screen_surface = sdl.SDL_GetWindowSurface(window);

            const pixel_format_details = sdl.SDL_GetPixelFormatDetails(screen_surface.*.format);
            _ = sdl.SDL_FillSurfaceRect(screen_surface, null, sdl.SDL_MapRGB(pixel_format_details, null, 0xFF, 0xFF, 0xFF));
            _ = sdl.SDL_UpdateWindowSurface(window);

            var e: sdl.SDL_Event = undefined;
            var quit: bool = false;

            while (!quit) {
                while (sdl.SDL_PollEvent(&e)) {
                    if (e.type == sdl.SDL_EVENT_QUIT) {
                        quit = true;
                    }
                }
            }
        }
    }

    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}
