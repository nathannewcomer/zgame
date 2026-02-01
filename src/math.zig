const std = @import("std");
const expect = @import("std").testing.expect;
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

pub const Point = struct { x: f32, y: f32, z: f32 };

pub const Triangle = struct { a: Point, b: Point, c: Point };

pub const Matrix4x4 = [4][4]f32;

pub fn create_projection(aspect_ratio: f32, fov_rad: f32, near: f32, far: f32) Matrix4x4 {
    var proj_matrix: Matrix4x4 = std.mem.zeroes(Matrix4x4);

    proj_matrix[0][0] = fov_rad / aspect_ratio;
    proj_matrix[1][1] = fov_rad;
    proj_matrix[2][2] = far / (far - near);
    proj_matrix[3][2] = (-far * near) / (far - near);
    proj_matrix[2][3] = 1.0;
    proj_matrix[3][3] = 0.0;

    return proj_matrix;
}

pub fn multiply_matrix_vector(i: Point, o: *Point, m: Matrix4x4) void {
    // 1. Multiply the point (with implicit w = 1.0) by the matrix
    const x = i.x * m[0][0] + i.y * m[1][0] + i.z * m[2][0] + 1.0 * m[3][0];
    const y = i.x * m[0][1] + i.y * m[1][1] + i.z * m[2][1] + 1.0 * m[3][1];
    const z = i.x * m[0][2] + i.y * m[1][2] + i.z * m[2][2] + 1.0 * m[3][2];
    const w = i.x * m[0][3] + i.y * m[1][3] + i.z * m[2][3] + 1.0 * m[3][3];

    // 2. Perspective Divide
    // If w is 0, we avoid division by zero (point is usually at the camera origin)
    if (w != 0.0) {
        o.x = x / w;
        o.y = y / w;
        o.z = z / w;
    } else {
        o.x = x;
        o.y = y;
        o.z = z;
    }
}

test "multiply_matrix_vector: identity matrix" {
    const input = Point{ .x = 1.0, .y = 2.0, .z = 3.0 };
    var output = Point{ .x = 0, .y = 0, .z = 0 };

    // Identity matrix: No change to the input
    const identity = [4][4]f32{
        [_]f32{ 1, 0, 0, 0 },
        [_]f32{ 0, 1, 0, 0 },
        [_]f32{ 0, 0, 1, 0 },
        [_]f32{ 0, 0, 0, 1 },
    };

    multiply_matrix_vector(input, &output, identity);

    try expect(output.x == 1.0);
    try expect(output.y == 2.0);
    try expect(output.z == 3.0);
}

test "multiply_matrix_vector: translation" {
    const input = Point{ .x = 10, .y = 10, .z = 10 };
    var output = Point{ .x = 0, .y = 0, .z = 0 };

    // Translation matrix: move by x+5, y-2, z+0
    // (Assuming column-major or row-major logic; typically [3][0,1,2] for translation)
    const translation = [4][4]f32{
        [_]f32{ 1, 0, 0, 5 },
        [_]f32{ 0, 1, 0, -2 },
        [_]f32{ 0, 0, 1, 0 },
        [_]f32{ 0, 0, 0, 1 },
    };

    multiply_matrix_vector(input, &output, translation);

    try expect(output.x == 15.0);
    try expect(output.y == 8.0);
    try expect(output.z == 10.0);
}

test "multiply_matrix_vector: scaling" {
    const input = Point{ .x = 2, .y = 4, .z = 6 };
    var output = Point{ .x = 0, .y = 0, .z = 0 };

    // Scaling matrix: double everything
    const scale = [4][4]f32{
        [_]f32{ 2, 0, 0, 0 },
        [_]f32{ 0, 2, 0, 0 },
        [_]f32{ 0, 0, 2, 0 },
        [_]f32{ 0, 0, 0, 1 },
    };

    multiply_matrix_vector(input, &output, scale);

    try expect(output.x == 4.0);
    try expect(output.y == 8.0);
    try expect(output.z == 12.0);
}
