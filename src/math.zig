const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});
const expect = @import("std").testing.expect;

pub const Vec4 = @Vector(4, f32);

pub const Matrix4x4 = struct {
    cols: [4]Vec4,

    pub fn multiplyVect(self: Matrix4x4, v: Vec4) Vec4 {
        // Spat each component of v into a vector
        const x = @as(Vec4, @splat(v[0]));
        const y = @as(Vec4, @splat(v[1]));
        const z = @as(Vec4, @splat(v[2]));
        const w = @as(Vec4, @splat(v[3]));

        // Multiply and add (Fused Multiply-Add will be used by the compiler if available)
        var res: Vec4 = x * self.cols[0];
        res += y * self.cols[1];
        res += z * self.cols[2];
        res += w * self.cols[3];

        return res;
    }
};

pub fn calculateNormalSIMD(v1: Vec4, v2: Vec4, v3: Vec4) Vec4 {
    // Calculate edge vectors
    const edge1 = v2 - v1;
    const edge2 = v3 - v1;

    // Cross product using shuffling
    // (a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x)
    const res = @shuffle(f32, edge1, undefined, .{ 1, 2, 0, 3 }) * @shuffle(f32, edge2, undefined, .{ 2, 0, 1, 3 }) -
        @shuffle(f32, edge1, undefined, .{ 2, 0, 1, 3 }) * @shuffle(f32, edge2, undefined, .{ 1, 2, 0, 3 });

    // Normalize
    const squared = res * res;
    const sum = squared[0] + squared[1] + squared[2];

    if (sum < 1e-12) return @Vector(4, f32){ 0, 0, 0, 0 };

    const inv_len = 1.0 / @sqrt(sum);

    // Splat to vector and multiply
    return res * @as(Vec4, @splat(inv_len));
}

pub fn createProjection(aspect_ratio: f32, fov_rad: f32, near: f32, far: f32) Matrix4x4 {
    var proj_matrix: Matrix4x4 = .{ .cols = std.mem.zeroes([4]Vec4) };

    proj_matrix.cols[0][0] = fov_rad / aspect_ratio;
    proj_matrix.cols[1][1] = fov_rad;
    proj_matrix.cols[2][2] = far / (far - near);
    proj_matrix.cols[2][3] = (-far * near) / (far - near);
    proj_matrix.cols[3][2] = 1.0;
    proj_matrix.cols[3][3] = 0.0;

    return proj_matrix;
}

// pub fn multiplyMatrixVector(i: Point, m: Matrix4x4) Point {
//     // 1. Multiply the point (with implicit w = 1.0) by the matrix
//     const x = i.x * m[0][0] + i.y * m[1][0] + i.z * m[2][0] + 1.0 * m[3][0];
//     const y = i.x * m[0][1] + i.y * m[1][1] + i.z * m[2][1] + 1.0 * m[3][1];
//     const z = i.x * m[0][2] + i.y * m[1][2] + i.z * m[2][2] + 1.0 * m[3][2];
//     const w = i.x * m[0][3] + i.y * m[1][3] + i.z * m[2][3] + 1.0 * m[3][3];

//     var o = Point{ .x = 0, .y = 0, .z = 0 };

//     // 2. Perspective Divide
//     // If w is 0, we avoid division by zero (point is usually at the camera origin)
//     if (w != 0.0) {
//         o.x = x / w;
//         o.y = y / w;
//         o.z = z / w;
//     } else {
//         o.x = x;
//         o.y = y;
//         o.z = z;
//     }

//     return o;
// }

// test "multiply_matrix_vector: identity matrix" {
//     const input = Point{ .x = 1.0, .y = 2.0, .z = 3.0 };
//     var output = Point{ .x = 0, .y = 0, .z = 0 };

//     // Identity matrix: No change to the input
//     const identity = [4][4]f32{
//         [_]f32{ 1, 0, 0, 0 },
//         [_]f32{ 0, 1, 0, 0 },
//         [_]f32{ 0, 0, 1, 0 },
//         [_]f32{ 0, 0, 0, 1 },
//     };

//     multiplyMatrixVector(input, &output, identity);

//     try expect(output.x == 1.0);
//     try expect(output.y == 2.0);
//     try expect(output.z == 3.0);
// }

// test "multiply_matrix_vector: translation" {
//     const input = Point{ .x = 10, .y = 10, .z = 10 };
//     var output = Point{ .x = 0, .y = 0, .z = 0 };

//     // Translation matrix: move by x+5, y-2, z+0
//     // (Assuming column-major or row-major logic; typically [3][0,1,2] for translation)
//     const translation = [4][4]f32{
//         [_]f32{ 1, 0, 0, 5 },
//         [_]f32{ 0, 1, 0, -2 },
//         [_]f32{ 0, 0, 1, 0 },
//         [_]f32{ 0, 0, 0, 1 },
//     };

//     multiplyMatrixVector(input, &output, translation);

//     try expect(output.x == 15.0);
//     try expect(output.y == 8.0);
//     try expect(output.z == 10.0);
// }

// test "multiply_matrix_vector: scaling" {
//     const input = Point{ .x = 2, .y = 4, .z = 6 };
//     var output = Point{ .x = 0, .y = 0, .z = 0 };

//     // Scaling matrix: double everything
//     const scale = [4][4]f32{
//         [_]f32{ 2, 0, 0, 0 },
//         [_]f32{ 0, 2, 0, 0 },
//         [_]f32{ 0, 0, 2, 0 },
//         [_]f32{ 0, 0, 0, 1 },
//     };

//     multiplyMatrixVector(input, &output, scale);

//     try expect(output.x == 4.0);
//     try expect(output.y == 8.0);
//     try expect(output.z == 12.0);
// }
