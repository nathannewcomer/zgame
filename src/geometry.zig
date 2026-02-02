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
        for (0..3) |i| {
            self.p[i][0] += x;
            self.p[i][1] += y;
            self.p[i][2] += z;
        }
    }

    pub fn multiply(self: *Triangle, x: f32, y: f32, z: f32) void {
        for (0..3) |i| {
            self.p[i][0] *= x;
            self.p[i][1] *= y;
            self.p[i][2] *= z;
        }
    }

    pub fn normalizeCoordinates(self: *Triangle) void {
        for (0..3) |i| {
            const w = self.p[i][3];
            self.p[i][0] /= w;
            self.p[i][1] /= w;
            self.p[i][2] /= w;
        }
    }

    pub fn calculateNormal(self: Triangle) math.Vec4 {
        // FIX: Use separate indices for the vertices
        const v1 = self.p[0];
        const v2 = self.p[1];
        const v3 = self.p[2];

        // Calculate edge vectors
        const edge1 = v2 - v1;
        const edge2 = v3 - v1;

        // Cross product using shuffling
        const mask1: @Vector(4, i32) = .{ 1, 2, 0, 3 };
        const mask2: @Vector(4, i32) = .{ 2, 0, 1, 3 };

        var res = @shuffle(f32, edge1, undefined, mask1) * @shuffle(f32, edge2, undefined, mask2) -
            @shuffle(f32, edge1, undefined, mask2) * @shuffle(f32, edge2, undefined, mask1);

        // Force the W component to 0 for a direction vector
        res[3] = 0;

        // Normalize
        const squared = res * res;
        const sum = squared[0] + squared[1] + squared[2];

        // FIX: Return using anonymous list literal or @splat
        if (sum < 1e-12) return .{ 0, 0, 0, 0 };

        const inv_len = 1.0 / @sqrt(sum);

        return res * @as(math.Vec4, @splat(inv_len));
    }
};

pub const Mesh = struct { triangles: []Triangle };
