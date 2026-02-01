const math = @import("math.zig");

pub const Triangle = struct {
    p: [3]math.Vec4,

    // Multiplies
    pub fn matrixMultiply(self: Triangle, m: math.Matrix4x4) Triangle {
        const a = m.multiplyVect(self.p[0]);
        const b = m.multiplyVect(self.p[1]);
        const c = m.multiplyVect(self.p[2]);

        return Triangle{ .p = [3]math.Vec4{ a, b, c } };
    }

    pub fn translate(self: *Triangle, x: f32, y: f32, z: f32) void {
        for (&(self.p)) |*vec| {
            vec[0] += x;
            vec[1] += y;
            vec[2] += z;
        }
    }

    pub fn multiply(self: *Triangle, x: f32, y: f32, z: f32) void {
        for (&(self.p)) |*vec| {
            vec[0] *= x;
            vec[1] *= y;
            vec[2] *= z;
        }
    }
};

pub const Mesh = struct { triangles: []Triangle };
