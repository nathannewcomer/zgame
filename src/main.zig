const std = @import("std");
const zgame = @import("zgame");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub fn main() !void {
    const screen_width: c_int = 640;
    const screen_height: c_int = 480;

    var window: ?*sdl.SDL_Window = null;
    var renderer: ?*sdl.SDL_Renderer = null;

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

    while (!quit) {
        while (sdl.SDL_PollEvent(&e)) {
            if (e.type == sdl.SDL_EVENT_QUIT) {
                quit = true;
            }
        }

        _ = sdl.SDL_SetRenderDrawColor(renderer, 255, 255, 255, sdl.SDL_ALPHA_OPAQUE);
        _ = sdl.SDL_RenderLine(renderer, 0, 0, 640, 480);
        _ = sdl.SDL_RenderLine(renderer, 0, 480, 640, 0);

        _ = sdl.SDL_RenderPresent(renderer);
    }

    sdl.SDL_Quit();
}
