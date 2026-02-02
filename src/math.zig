const std = @import("std");
const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});
const expect = std.testing.expect;
const expectApproxEqAbs = std.testing.expectApproxEqAbs;

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

pub fn createProjection(aspect_ratio: f32, fov_rad: f32, near: f32, far: f32) Matrix4x4 {
    var proj_matrix = Matrix4x4{
        .cols = .{
            @splat(0.0),
            @splat(0.0),
            @splat(0.0),
            @splat(0.0),
        },
    };

    // f = cotangent(fov / 2)
    const f = 1.0 / @tan(fov_rad * 0.5);

    // Column 0
    proj_matrix.cols[0][0] = f / aspect_ratio;

    // Column 1
    proj_matrix.cols[1][1] = f;

    // Column 2 (Z-axis basis)
    // Maps Z to [0, 1] range
    proj_matrix.cols[2][2] = far / (far - near);
    proj_matrix.cols[2][3] = 1.0; // This is the 'W' divide coefficient

    // Column 3 (W/Translation basis)
    proj_matrix.cols[3][2] = -(far * near) / (far - near);
    proj_matrix.cols[3][3] = 0.0;

    return proj_matrix;
}

test "multiplyVect: identity matrix" {
    const identity = Matrix4x4{
        .cols = .{
            Vec4{ 1, 0, 0, 0 },
            Vec4{ 0, 1, 0, 0 },
            Vec4{ 0, 0, 1, 0 },
            Vec4{ 0, 0, 0, 1 },
        },
    };
    const v = Vec4{ 10, 20, 30, 40 };
    const result = identity.multiplyVect(v);

    try expectVectorApprox(v, result);
}

test "multiplyVect: scaling matrix" {
    const scale = Matrix4x4{
        .cols = .{
            Vec4{ 2, 0, 0, 0 },
            Vec4{ 0, 3, 0, 0 },
            Vec4{ 0, 0, 4, 0 },
            Vec4{ 0, 0, 0, 1 },
        },
    };
    const v = Vec4{ 1, 1, 1, 1 };
    const result = scale.multiplyVect(v);
    const expected = Vec4{ 2, 3, 4, 1 };

    try expectVectorApprox(expected, result);
}

test "multiplyVect: arbitrary values" {
    const mat = Matrix4x4{
        .cols = .{
            Vec4{ 1, 2, 3, 4 },
            Vec4{ 5, 6, 7, 8 },
            Vec4{ 9, 10, 11, 12 },
            Vec4{ 13, 14, 15, 16 },
        },
    };
    const v = Vec4{ 1, 0.5, 2, 0 };
    // Calculation:
    // 1*[1,2,3,4] + 0.5*[5,6,7,8] + 2*[9,10,11,12] + 0*[...]
    // = [1,2,3,4] + [2.5, 3, 3.5, 4] + [18, 20, 22, 24]
    // = [21.5, 25, 28.5, 32]

    const result = mat.multiplyVect(v);
    const expected = Vec4{ 21.5, 25, 28.5, 32 };

    try expectVectorApprox(expected, result);
}

/// Helper to compare vectors with a tolerance
fn expectVectorApprox(expected: Vec4, actual: Vec4) !void {
    const eps = 0.00001;
    var i: usize = 0;
    while (i < 4) : (i += 1) {
        try expectApproxEqAbs(expected[i], actual[i], eps);
    }
}
