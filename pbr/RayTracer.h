#pragma once
#include <ncl/gl/compute.h>
#include <ncl/gl/Scene.h>
#include <ncl/gl/SkyBox.h>
#include <ncl/gl/shader_binding.h>
#include <string>
#include <vector>
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtc/matrix_access.hpp>
#include "camera.h"
#include "Objects.h"

using namespace std;
using namespace ncl;
using namespace ncl;
using namespace gl;
using namespace glm;

class RayTracer : public Compute {
public:
	RayTracer(Scene& scene, obj::SceneObjects& objs)
		: Compute(vec3{ scene.width() / 32.0f, scene.height() / 32.0f, 1.0f }
			, vector<Image2D>{ Image2D(scene.width(), scene.height(), GL_RGBA32F, "image", 0) }
			, &scene.shader("ray_tracer")), scene{ scene }, sceneObjects(objs) {
		vector<string> faces = vector<string>{
			"right.jpg", "left.jpg",
			"top.jpg", "bottom.jpg",
			"front.jpg", "back.jpg"
		};
		string root = "C:\\Users\\Josiah\\OneDrive\\media\\textures\\skybox\\001\\";
		transform(faces.begin(), faces.end(), faces.begin(), [&root](string path) {
			return root + path;
		});

		auto& activeCamera = scene.activeCamera();
		activeCamera.lookAt({ 0, 0, 5 }, vec3(0), { 0, 1, 0 });
		activeCamera.perspective(60.0f, float(scene.width()) / scene.height(), 0.01, 1000.0f);

		skybox = SkyBox::create(faces, 7, scene, 1);
		cam.view = lookAt({ 0, 0, 5}, vec3(0), { 0, 1, 0 });
		cam.projection = perspective(radians(60.f), float(scene.width()) / scene.height(), 0.01f, 1000.f);

	//	configure(camera, cam.projection, cam.view, scene.width(), scene.height());
		configure(camera, activeCamera.getProjectionMatrix(), activeCamera.getViewMatrix(), scene.width(), scene.height());

		glGenBuffers(1, &camera_ssbo_id);
		glBindBuffer(GL_SHADER_STORAGE_BUFFER, camera_ssbo_id);
		glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(camera), NULL, GL_DYNAMIC_DRAW);
		glBindBufferBase(GL_SHADER_STORAGE_BUFFER, 0, camera_ssbo_id);

		checkerboard = new CheckerBoard_gpu(255, 255, WHITE, BLACK, 1, "checker");
		checkerboard->compute();
		checkerboard->images().front().renderMode();
	}

	virtual void preCompute() override {
		configure(camera, scene.activeCamera().getProjectionMatrix(), scene.activeCamera().getViewMatrix(), scene.width(), scene.height());
		glBindBuffer(GL_SHADER_STORAGE_BUFFER, camera_ssbo_id);
		glBufferData(GL_SHADER_STORAGE_BUFFER, sizeof(camera), &camera.cameraToWorld[0], GL_DYNAMIC_DRAW);
		
		sceneObjects.preCompute();

		auto& img = checkerboard->images().front();
		glBindTextureUnit(1, img.buffer());

		skybox->bind();
	}

private:
	Scene & scene;
	obj::SceneObjects& sceneObjects;
	SkyBox* skybox;
	GlmCam cam;
	Camera_t camera;
	GLuint camera_ssbo_id;
	CheckerBoard_gpu* checkerboard;

};