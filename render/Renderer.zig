const std = @import("std");
const gl = @import("zgl");
const glfw = @import("mach-glfw");
const Vector3 = @import("common").Vector3;

vao: gl.VertexArray,
program: gl.Program,
sections: std.AutoHashMap(Vector3(i32), SectionRenderInfo),

pub fn init(allocator: std.mem.Allocator) !@This() {
    const program = try createProgram(.{@embedFile("./triangle.glsl.vert")}, .{@embedFile("./triangle.glsl.frag")});
    program.use();

    const vao = gl.VertexArray.create();
    vao.bind();

    vao.enableVertexAttribute(0);
    vao.attribFormat(0, 3, .float, false, 0);
    vao.attribBinding(0, 0);

    return .{
        .vao = vao,
        .program = program,
        .sections = std.AutoHashMap(Vector3(i32), SectionRenderInfo).init(allocator),
    };
}

pub const SectionRenderInfo = struct {
    buffer: gl.Buffer,
    vertices: usize,
};

pub fn createProgram(vertex_shader_source: [1][]const u8, frag_shader_source: [1][]const u8) !gl.Program {
    const vertex_shader = gl.Shader.create(.vertex);
    vertex_shader.source(1, &vertex_shader_source);

    const frag_shader = gl.Shader.create(.fragment);
    frag_shader.source(1, &frag_shader_source);

    const program = gl.Program.create();
    program.attach(vertex_shader);
    program.attach(frag_shader);
    program.link();

    var log_buffer: [8192]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&log_buffer);
    std.debug.print("{s}", .{try program.getCompileLog(fba.allocator())});

    return program;
}
