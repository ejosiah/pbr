#pragma once

#include <ncl/gl/Scene.h>
#include <ncl/gl/SkyBox.h>
#include <ncl/gl/compute.h>
#include "RayTracer.h"
#include "Canvas.h"
#include "Objects.h"

using namespace std;
using namespace ncl;
using namespace gl;

class PbrScene : public ncl::gl::Scene {
public:
	PbrScene(int w, int h):Scene("PBR Scene", w, h) {
		camInfoOn = true;
		_requireMouse = true;
		_vsync = true;
		useImplictShaderLoad(true);
	}

	void init() override {
		sceneObjs = new obj::SceneObjects;
		sceneObjs->init();
		raytracer = new RayTracer(*this, *sceneObjs);
		canvas = new Canvas(*raytracer, *this);
		activeCamera().setAcceleration({ 5, 5, 5 });
	}

	void display() override {
		canvas->render();
		sFont->render("fps: " + to_string(int(fps)), width() - 50, 10);

		auto stats = sceneObjs->stats;
		
		sbr << "Triangle stats:" << endl;
		sbr << "\tfetch method: ";
		sbr << (fetchFromTexture ? "texture" : "buffer") << endl;
		sbr << "\nBVH statisitics" << endl;
		sbr << "\theight: " << stats.height << endl;
		sbr << "\tno of nodes: " << stats.nodes << endl;
		sbr << "\tavg triangles per node: " << stats.size << endl;
		sFont->render(sbr.str(), 10, 60);
		sbr.clear();
		sbr.str("");
	}

	void update(float dt) override {
		raytracer->compute();
	}

	void resized() override {
	}

	void processInput(const ncl::gl::Key& key) override {
		if (key.value() == 'f' && key.pressed()) {
			fetchFromTexture = !fetchFromTexture;
			shader("ray_tracer")([=] { send("fetchFromTexture", fetchFromTexture); });
		}
	}
private:
	RayTracer * raytracer;
	Canvas* canvas;
	GLuint scene_img;
	SkyBox* skybox;
	ProvidedMesh* quad;
	obj::SceneObjects* sceneObjs;
	bool fetchFromTexture = false;
};