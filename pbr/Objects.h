#pragma once

#include <vector>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/constants.hpp>
#include <ncl/gl/Model.h>
#include <ncl/gl/MeshLoader.h>
#include <ncl/gl/MeshNormalizer.h>
#include <ncl/gl/mesh.h>
#include <ncl/geom/bvh2.h>
#include <ncl/geom/aabb2.h>
#include <ncl/data_structure/binary_tree.h>
#include <ncl/gl/textures.h>
#include <limits>

using namespace std;
using namespace glm;
using namespace ncl;
using namespace gl;

namespace obj {

#pragma pack(push, 1)
	struct Sphere {
		vec3 center;
		vec3 color;
		mat4 objectToWorld = mat4(1);
		mat4 worldToObject = mat4(1);
		float radius = 1;
		float yMin = -100;
		float yMax = 100;
		float thetaMin = 0;
		float thetaMax = glm::pi<float>();
		float phiMax = glm::two_pi<float>();
		int id;
		int matId;
	};
#pragma pack(pop)	

#pragma pack(push, 1)
	struct Cylinder {
		mat4 objectToWorld = mat4(1);
		mat4 worldToObject = mat4(1);
		float radius = 1;
		float yMin = 0;
		float yMax = 1;
		float maxPhi = glm::two_pi<float>();
	};
#pragma pack(pop)

#pragma pack(push, 1)
	struct Triangle {
		int id;
		int objectToWorldId;
		int worldToObjectId;
		int matId;
		vec4 a;
		vec4 b;
		vec4 c;
	};
#pragma pack(pop)

#pragma pack(push, 1)
	struct Plane {
		vec3 n;
		float d;
		int id;
		int matId;
	};
#pragma pack(pop)

#pragma pack(push, 1)
	struct Shading {
		vec4 n0;
		vec4 n1;
		vec4 n2;
		vec4 t0;
		vec4 t1;
		vec4 t2;
		vec4 bi0;
		vec4 bi1;
		vec4 bi2;
		vec2 uv0;
		vec2 uv1;
		vec2 uv2;
		int id;
	};
#pragma pack(pop)

#pragma pack(push, 1)
	struct Material {
		vec4 ambient;
		vec4 diffuse;
		vec4 specular;
		float shine;
		float ior;
	};
#pragma pack(pop)
	struct BVHStats {
		size_t height;
		size_t nodes;
		size_t size;
	};

	class SceneObjects {
	public:
		void init() {
			maxDepth = std::numeric_limits<float>::lowest();
			//	paths.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\werewolf.obj");
			paths.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\ChineseDragon.obj");
		//	paths.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\stanford-dragon\\stanford-dragon.obj");
		//	paths.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\lte-orb\\lte-orb.obj");
		//	paths.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\lte-orb\\ite-orb_no_sphere.obj");
			//	paths.push_back("C:\\Users\\Josiah\\OneDrive\\media\\models\\blocks\\blocks.obj");
			//	paths.push_back("C:\\Users\\Josiah\\OneDrive\\media\\models\\Armadillo.obj");

			//paths_lr.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\lte-orb\\lte-orb-005.obj");
			//paths_lr.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\stanford-dragon\\stanford-dragon-005.obj");
			paths_lr.push_back("C:\\Users\\" + username + "\\OneDrive\\media\\models\\ChineseDragon.obj");

			
			Material m;
		/*	m.ambient = { 1, 1, 1, 1 };
			m.diffuse = m.specular = vec4(1);
			m.shine = 128;
			m.ior = 0;
			materials.push_back(m);

			Sphere s;
			s.matId = materials.size() - 1;
			s.color = vec3(0, 1, 0);
			s.center = vec3(0, 0, 0);
			s.radius = 2;
			s.objectToWorld = translate(mat4(1), { 0, 3, 0 });
			s.worldToObject = inverse(s.objectToWorld);
			s.id = spheres.size();
			int sphereMatId = materials.size() - 1;


			spheres.push_back(s);*/
			
			initSpheres();

			initializeTriangles(paths, triangles);

		//	Material m;
			m.ambient = { 1, 1, 1, 1 };
			m.diffuse = m.specular = vec4(1);
			m.shine = 128;
			m.ior = 0;


			Plane plane;
			plane.n = { 0, 1, 0 };
			plane.d = dot(plane.n, min_point);
		//	plane.d = 0;
			plane.id = planes.size();
			planes.push_back(plane);
			plane.matId = materials.size();

			m.ambient = m.diffuse = vec4(0.3);
			m.ior = 0;
			materials.push_back(m);

			buildBVH(triangles, bvh_index, bvh_ssbo, true);


			int lowResStardId = triangles.size();
			lowResRoot = bvh_ssbo.nodes.size();
			Logger::get("Objects").info("low res root: " + to_string(lowResRoot));
			initializeTriangles(paths_lr, triangles);
			buildBVH(triangles, bvh_index, bvh_ssbo, false, lowResStardId, lowResRoot);
			
			initialize(sphereId, 1, sizeof(Sphere) * spheres.size());
			initialize(triangleBuffer, 2, sizeof(Triangle) * triangles.size());
			initialize(shadingsBuffer, 3, sizeof(Shading) * shadings.size());
			initialize(bvh_id, 4, sizeof(geom::bvh::LinearBVHNode) * bvh_ssbo.nodes.size());
			initialize(bvh_index_id, 5, sizeof(int) * bvh_index.data.size());
			initialize(materialId, 7, sizeof(Material) * materials.size());
			initialize(planeBuffer, 8, sizeof(Plane) * planes.size());
		}

		void initSpheres() {
			vec2 radius = { 0.3, 2 };
			float placementRadius = 20;
			auto rng = rngReal(0, 1);
			
			Material m;
			m.ambient = vec4(0);
			m.diffuse = { 0.4, 0.4, 0.4, 1.0 };
			m.specular = vec4(0.6);
			m.shine = 20;
			m.ior = 0;
			materials.push_back(m);

			int sphereMatId = materials.size() - 1;

			
			for (int i = 0; i < MaxSpheres; i++) {
				Sphere s;
				s.matId = sphereMatId;
				s.radius = radius.x + rng() * (radius.y - radius.x);
				vec2 u = vec2(cos(rng() * two_pi<float>()), sin(rng() * two_pi<float>())) * placementRadius;
				s.center = vec3(0);
				s.objectToWorld = translate(mat4(1), vec3{ u.x, s.radius, u.y });
				s.worldToObject = inverse(s.objectToWorld);


				for (auto other : spheres) {
					float minDist = s.radius + other.radius;
					vec3 aCenter = (s.objectToWorld * vec4(0, 0, 0, 1)).xyz;
					vec3 oCenter = (other.objectToWorld * vec4(0, 0, 0, 1)).xyz;
					vec3 d = aCenter - oCenter;
					if (dot(d, d) < minDist * minDist) goto outter;
				}
				s.id = spheres.size();
				spheres.push_back(s);

			outter:
				continue;
			}
		}

		void initializeTriangles(vector<string>& paths, vector<Triangle>& triangles) {
			min_point = vec3{ numeric_limits<float>::max() };
			for (auto path : paths) {
				vector<Mesh> meshes = loader.createMesh(path, 2, MeshLoader::DEFAULT_PROCESS_FLAGS, true);
				normalizer.normalize(meshes, 3);

				//vector<vec4> pos;
				vector<vec4> norms;
				vector<vec4> st;
				Material mat;

				mat.ambient = { 0.1745,	0.01175, 0.01175, 1.0 };
				mat.diffuse = { 0.61424, 0.04136, 0.04136, 1.0 };
				mat.specular = { 0.727811, 0.626959, 0.626959, 1.0 };
				mat.shine = 128;
				mat.ior = 1.76;
				mat.ior = 0;
				materials.push_back(mat);

				

				for (auto& mesh : meshes) {
					//Material mat;
					//mat.ambient = mesh.material.ambient * 0.1f;
					//mat.diffuse = mesh.material.diffuse;
					//mat.specular = mesh.material.specular;
					//mat.shine = mesh.material.shininess;
					//mat.ior = mesh.material.ior;
					//materials.push_back(mat);
					int matId = materials.size() - 1;

					if (mesh.hasIndices()) {
						size_t size = mesh.indices.size() / 3;
						for (size_t i = 0; i < size; i++) {
							Triangle t;
							Shading s;
							auto a = mesh.indices[i * 3];
							auto b = mesh.indices[i * 3 + 1];
							auto c = mesh.indices[i * 3 + 2];

							t.a = vec4(mesh.positions[a], 0);
							t.b = vec4(mesh.positions[b], 0);
							t.c = vec4(mesh.positions[c], 0);

							s.n0 = vec4(mesh.normals[a], 0);
							s.n1 = vec4(mesh.normals[b], 0);
							s.n2 = vec4(mesh.normals[c], 0);

							if (mesh.hasTangents()) {
								s.t0 = vec4(mesh.tangents[a], 0);
								s.t1 = vec4(mesh.tangents[b], 0);
								s.t2 = vec4(mesh.tangents[c], 0);

								s.bi0 = vec4(mesh.bitangents[a], 0);
								s.bi1 = vec4(mesh.bitangents[b], 0);
								s.bi2 = vec4(mesh.bitangents[c], 0);

							}

							if (mesh.hasTexCoords()) {
								s.uv0 = mesh.uvs[0][a];
								s.uv1 = mesh.uvs[0][b];
								s.uv2 = mesh.uvs[0][c];
							}
							t.id = triangles.size();
							s.id = t.id;
							t.matId = matId;
							triangles.push_back(t);
							shadings.push_back(s);

							vec3 point;
							min_point = glm::min(min_point, point = t.a.xyz);
							min_point = glm::min(min_point, point = t.b.xyz);
							min_point = glm::min(min_point, point = t.c.xyz);

							maxDepth = std::max(std::max(std::max(t.a.z, t.b.z), t.c.z), maxDepth);
						}
					}
					else {
						auto size = mesh.positions.size();
						for (int i = 0; i < size; i += 3) {
							Triangle t;
							Shading s;
							auto a = i;
							auto b = a + 1;
							auto c = b + 1;

							t.a = vec4(mesh.positions[a], 0);
							t.b = vec4(mesh.positions[b], 0);
							t.c = vec4(mesh.positions[c], 0);

							s.n0 = vec4(mesh.normals[a], 0);
							s.n1 = vec4(mesh.normals[b], 0);
							s.n2 = vec4(mesh.normals[c], 0);

							if (mesh.hasTangents()) {
								s.t0 = vec4(mesh.tangents[a], 0);
								s.t1 = vec4(mesh.tangents[b], 0);
								s.t2 = vec4(mesh.tangents[c], 0);

								s.bi0 = vec4(mesh.bitangents[a], 0);
								s.bi1 = vec4(mesh.bitangents[b], 0);
								s.bi2 = vec4(mesh.bitangents[c], 0);

							}

							if (mesh.hasTexCoords()) {
								s.uv0 = mesh.uvs[0][a];
								s.uv1 = mesh.uvs[0][b];
								s.uv2 = mesh.uvs[0][c];
							}
							t.id = triangles.size();
							s.id = t.id;
							triangles.push_back(t);
							shadings.push_back(s);

							vec3 point;
							min_point = glm::min(min_point, point = t.a.xyz);
							min_point = glm::min(min_point, point = t.b.xyz);
							min_point = glm::min(min_point, point = t.c.xyz);
						}
					}

				}
				for (auto& t : triangles) {
					pos.push_back(t.a);
					pos.push_back(t.b);
					pos.push_back(t.c);
				}
				for (auto& s : shadings) {
					norms.push_back(s.n0);
					norms.push_back(s.n1);
					norms.push_back(s.n1);

					st.push_back(vec4(s.uv0, 0, 0));
					st.push_back(vec4(s.uv1, 0, 0));
					st.push_back(vec4(s.uv2, 0, 0));
				}
				GLuint size = sizeof(vec4);
				//	pos[0] = vec4(1, 0, 0, 1);
				//	norms[0] = vec4(0, 1, 0, 1);
				//	st[0] = vec4(0, 0, 1, 1);
				vertices = new TextureBuffer("triangles", &pos[0], size * pos.size(), GL_RGBA32F, 0, 2);
				normals = new TextureBuffer("normals", &norms[0], size * norms.size(), GL_RGBA32F, 0, 3);
				uvs = new TextureBuffer("uvs", &st[0], size * st.size(), GL_RGBA32F, 0, 4);
			}
		}


		void initialize(GLuint& buffer, GLuint unit, GLuint size) {
			glGenBuffers(1, &buffer);
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, buffer);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, NULL, GL_DYNAMIC_DRAW);
			glBindBufferBase(GL_SHADER_STORAGE_BUFFER, unit, buffer);
		}

		void preCompute() {

			int size = sizeof(Sphere) * spheres.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, sphereId);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &spheres[0], GL_DYNAMIC_DRAW);
			//	glBufferSubData(GL_SHADER_STORAGE_BUFFER, 0, size, &spheres[0]);

			size = sizeof(Triangle) * triangles.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, triangleBuffer);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &triangles[0], GL_DYNAMIC_DRAW);

			size = sizeof(Shading) * shadings.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, shadingsBuffer);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &shadings[0], GL_DYNAMIC_DRAW);

			/*
				send_ssbo(bvh_id, 0, sizeof(geom::bvh::LinearBVHNode) * bvh_ssbo.nodes.size(), &bvh_ssbo.nodes[0]);
				send_ssbo(bvh_index_id, 1, sizeof(int) * bvh_index.data.size(), &bvh_index.data[0]);
			*/

			size = sizeof(geom::bvh::LinearBVHNode) * bvh_ssbo.nodes.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, bvh_id);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &bvh_ssbo.nodes[0], GL_DYNAMIC_DRAW);

			size = sizeof(int) * bvh_index.data.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, bvh_index_id);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &bvh_index.data[0], GL_DYNAMIC_DRAW);

			size = sizeof(Material) * materials.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, materialId);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &materials[0], GL_DYNAMIC_DRAW);

			size = sizeof(Plane) * planes.size();
			glBindBuffer(GL_SHADER_STORAGE_BUFFER, planeBuffer);
			glBufferData(GL_SHADER_STORAGE_BUFFER, size, &planes[0], GL_DYNAMIC_DRAW);

			send("maxDepth", maxDepth);
		//	send("numTriangles", int(triangles.size()));
			send("numTriangles", int(triangles.size()));
			send("numNodes", numNodes);
			send(vertices);
			send(normals);
			send(uvs);
			send("useLowPoly", true);
			send("lowPolyRoot", lowResRoot);
			send("numSpheres", int(spheres.size()));

		}

		void buildBVH(vector<Triangle>& triangles, geom::bvh::BVH_TRI_INDEX& bvh_index, geom::bvh::BVH_SSO& bvh_ssbo, bool updateStats = false, int startId = 0, int rootIdx = 0) {
			using namespace ncl::ds;
			vector<ncl::geom::bvh::Primitive> primitives;

			auto size = triangles.size();
			for (int i = startId; i < size; i++) {
				ncl::geom::bvh::Primitive p;
				Triangle t = triangles[i];
				p.id = i;
				p.bounds = ncl::geom::bvol::aabb::Union(p.bounds, t.a.xyz);
				p.bounds = ncl::geom::bvol::aabb::Union(p.bounds, t.b.xyz);
				p.bounds = ncl::geom::bvol::aabb::Union(p.bounds, t.c.xyz);
				primitives.push_back(p);
			}


			ncl::geom::bvh::BVHBuilder bvhBuilder{ primitives, 13 };

			auto root = bvhBuilder.root;
			bvhBuilder.buildLinearBVH(root, bvh_ssbo, bvh_index, rootIdx);
			BVH = bvhBuilder.root;


			if (updateStats) {
				stats.height = ds::tree::height(root);
				stats.nodes = 0;

				auto bvh_min = ds::tree::min(root);
				auto bvh_max = ds::tree::max(root);

				Mesh m;
				int total = 0;
				ds::tree::traverse(BVH, [&](geom::bvh::BVHBuildNode* n) {
				//	numNodes++;
					if (n->isLeaf()) {
						stats.nodes++;
						vec4 color = n->leftChild ? CYAN : MAGENTA;
						stats.size = (stats.size + n->nPrimitives);
						total++;
					}
					}, ds::tree::TraverseType::IN_ORDER);
				stats.size = stats.size / total;
			}

			numNodes += ds::tree::size(BVH);

		}

	private:
		TextureBuffer* vertices;
		TextureBuffer* normals;
		TextureBuffer* uvs;
		vector<string> paths;
		vector<string> paths_lr;
		vector<vec4> pos;
		vector<Triangle> triangles;
		vector<Shading> shadings;
		vector<Sphere> spheres;
		vector<Plane> planes;
		vector<Material> materials;
		GLuint sphereId;
		GLuint materialId;
		GLuint triangleBuffer;
		GLuint shadingsBuffer;
		GLuint planeBuffer;
		GLuint bvh_id;
		GLuint bvh_index_id;

		MeshLoader loader;
		MeshNormalizer normalizer;
		float maxDepth;
		int numNodes = 0;
		geom::bvh::BVHBuildNode* BVH;
		geom::bvh::BVH_SSO bvh_ssbo;
		geom::bvh::BVH_TRI_INDEX bvh_index;		
		vec3 min_point;
		int lowResRoot;
		const int MaxSpheres = 100;

	public:
		BVHStats stats;
	};
}