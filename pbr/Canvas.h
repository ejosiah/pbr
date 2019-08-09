#pragma once

#include <ncl/gl/Scene.h>
#include <ncl/gl/shader_binding.h>
#include "RayTracer.h"

using namespace std;
using namespace ncl;
using namespace ncl;
using namespace gl;

class Canvas : public ProvidedMesh {
public:
	Canvas(RayTracer& raytracer, Scene& scene) :
		ProvidedMesh(create()), raytracer{ raytracer }, scene{ scene } {}

	static Mesh create() {
		Mesh mesh;
		mesh.positions = {
			{ -1.0f, -1.0f, 0.0f },
		{ 1.0f, -1.0f, 0.0f },
		{ 1.0f,  1.0f, 0.0f },
		{ -1.0f,  1.0f, 0.0f }
		};
		mesh.uvs[0] = {
			{ 0, 0 },
		{ 1, 0 },
		{ 1, 1 },
		{ 0, 1 }
		};
		mesh.indices = { 0,1,2,0,2,3 };
		return mesh;
	}

	void render() {
		scene.shader("render")([&] {
			auto img = raytracer.images().front();
			img.renderMode();
			send(&img);
			shade(this);
		});
	}

private:
	RayTracer& raytracer;
	Scene& scene;
};