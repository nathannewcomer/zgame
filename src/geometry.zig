const math = @import("math.zig");
const std = @import("std");

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

pub const Mesh = struct {
    triangles: std.ArrayList(Triangle),

    pub fn init(allocator: std.mem.Allocator) Mesh {
        return .{
            .triangles = std.ArrayList(Triangle).init(allocator),
        };
    }

    pub fn deinit(self: Mesh) void {
        self.triangles.deinit();
    }
};

// Read mesh from file
pub fn loadMesh(allocator: std.mem.Allocator) !Mesh {
    const cwd = std.fs.cwd();
    var file: std.fs.File = try cwd.openFile("cube.obj", .{ .mode = .read_only });
    defer file.close();

    // var read_buffer: [1024]u8 = undefined;
    // var fr = file.reader(&read_buffer);
    // var reader = &fr.interface;

    var read_buffer: [1024]u8 = undefined;
    var file_reader = file.reader(&read_buffer);
    const reader: *std.io.Reader = &file_reader.interface;

    var vertexList: std.ArrayList(math.Vec4) = .empty;
    var faceList: std.ArrayList([3]u32) = .empty;

    errdefer vertexList.deinit(allocator);
    errdefer faceList.deinit(allocator);

    // Iterate over lines
    while (reader.takeDelimiter('\n')) |line| {
        if (line == null) {
            break;
        }

        std.debug.print("Reading line {s}\n", .{line.?});
        var it = std.mem.splitSequence(u8, line.?, " ");

        const prefix = it.next().?;

        if (std.mem.eql(u8, prefix, "v")) {
            // vertex a.k.a point/vector
            const x = it.next().?;
            const y = it.next().?;
            const z = it.next().?;
            const w = it.next().?;
            std.debug.print("line: {s} {s} {s} {s} {s}", .{ prefix, x, y, z, w });
            const vec: math.Vec4 = .{ try std.fmt.parseFloat(f32, x), try std.fmt.parseFloat(f32, y), try std.fmt.parseFloat(f32, z), try std.fmt.parseFloat(f32, w) };
            try vertexList.append(allocator, vec);
        } else if (std.mem.eql(u8, prefix, "f")) {
            // face a.k.a. triangle
            var faceVertices: [3]u32 = undefined;
            const a = try std.fmt.parseInt(u32, it.next().?, 10);
            const b = try std.fmt.parseInt(u32, it.next().?, 10);
            const c = try std.fmt.parseInt(u32, it.next().?, 10);
            faceVertices[0] = a;
            faceVertices[1] = b;
            faceVertices[2] = c;
            try faceList.append(allocator, faceVertices);
        }
    } else |err| switch (err) {
        error.StreamTooLong, // line could not fit in buffer
        error.ReadFailed, // caller can check reader implementation for diagnostics
        => |err_other| return err_other,
    }

    var triangles: std.ArrayList(Triangle) = .empty;
    const vertexes = vertexList.items;

    // Create triangles from vertex and face lists
    for (faceList.items) |face| {
        const vec1 = vertexes[face[0] - 1];
        const vec2 = vertexes[face[1] - 1];
        const vec3 = vertexes[face[2] - 1];
        const triangle: Triangle = .{ .p = .{ vec1, vec2, vec3 } };
        try triangles.append(allocator, triangle);
    }

    const mesh: Mesh = .{ .triangles = triangles };

    return mesh;
}
