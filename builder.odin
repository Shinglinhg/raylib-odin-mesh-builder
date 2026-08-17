package meshbuilder

import rl "vendor:raylib"
import "core:math"

Vertex :: struct {
	position: rl.Vector3,
	uv: rl.Vector2,
	normal: rl.Vector3,
}

MeshBuilder :: struct {
	vertices: [dynamic]Vertex,
	indices:  [dynamic]u16,
}

destroy :: proc(b: ^MeshBuilder) {
	if b.vertices != nil { delete(b.vertices) }
	if b.indices != nil { delete(b.indices) }
	b^ = {}
}

face_normal :: proc(a, b, c: rl.Vector3) -> rl.Vector3 {
	return rl.Vector3Normalize(rl.Vector3CrossProduct(b - a, c - a))
}

make_vertex :: proc(position: rl.Vector3, uv: rl.Vector2, normal: rl.Vector3) -> Vertex {
	return Vertex{
		position = position,
		uv = uv,
		normal = normal,
	}
}

add_vertex :: proc(b: ^MeshBuilder, v: Vertex) -> u16 {
	assert(len(b.vertices) < 65536)
	append(&b.vertices, v)
	return u16(len(b.vertices) - 1)
}

add_triangle_indices :: proc(b: ^MeshBuilder, i0, i1, i2: u16) {
	append(&b.indices, i0, i1, i2)
}

add_triangle :: proc(b: ^MeshBuilder, v0, v1, v2: Vertex) {
	i0 := add_vertex(b, v0)
	i1 := add_vertex(b, v1)
	i2 := add_vertex(b, v2)
	add_triangle_indices(b, i0, i1, i2)
}

add_quad :: proc(b: ^MeshBuilder, v0, v1, v2, v3: Vertex) {
	i0 := add_vertex(b, v0)
	i1 := add_vertex(b, v1)
	i2 := add_vertex(b, v2)
	i3 := add_vertex(b, v3)

	append(&b.indices, i0, i1, i2)
	append(&b.indices, i0, i2, i3)
}

add_triangle_auto :: proc(
	b: ^MeshBuilder,
	p0, p1, p2: rl.Vector3,
	uv0, uv1, uv2: rl.Vector2,
) {
	n := face_normal(p0, p1, p2)
	add_triangle(
		b,
		make_vertex(p0, uv0, n),
		make_vertex(p1, uv1, n),
		make_vertex(p2, uv2, n),
	)
}

add_quad_auto :: proc(
	b: ^MeshBuilder,
	p0, p1, p2, p3: rl.Vector3,
	uv0, uv1, uv2, uv3: rl.Vector2,
) {
	n := face_normal(p0, p1, p2)
	add_quad(
		b,
		make_vertex(p0, uv0, n),
		make_vertex(p1, uv1, n),
		make_vertex(p2, uv2, n),
		make_vertex(p3, uv3, n),
	)
}

build :: proc(b: ^MeshBuilder, upload: bool = true) -> rl.Mesh {
	mesh: rl.Mesh

	vertex_count := len(b.vertices)
	index_count := len(b.indices)

	mesh.vertexCount = i32(vertex_count)
	mesh.triangleCount = i32(index_count / 3)

	if vertex_count > 0 {
		mesh.vertices = cast([^]f32)rl.MemAlloc(u32(vertex_count * 3 * size_of(f32)))
		mesh.texcoords = cast([^]f32)rl.MemAlloc(u32(vertex_count * 2 * size_of(f32)))
		mesh.normals = cast([^]f32)rl.MemAlloc(u32(vertex_count * 3 * size_of(f32)))

		for v, i in b.vertices {
			p := i * 3
			t := i * 2

			mesh.vertices[p + 0] = v.position[0]
			mesh.vertices[p + 1] = v.position[1]
			mesh.vertices[p + 2] = v.position[2]

			mesh.texcoords[t + 0] = v.uv[0]
			mesh.texcoords[t + 1] = v.uv[1]

			mesh.normals[p + 0] = v.normal[0]
			mesh.normals[p + 1] = v.normal[1]
			mesh.normals[p + 2] = v.normal[2]
		}
	}

	if index_count > 0 {
		mesh.indices = cast([^]u16)rl.MemAlloc(u32(index_count * size_of(u16)))
		for index, i in b.indices {
			mesh.indices[i] = index
		}
	}

	if upload { rl.UploadMesh(&mesh, false) }

	return mesh
}

reset :: proc(b: ^MeshBuilder) {
	clear(&b.vertices)
	clear(&b.indices)
}
