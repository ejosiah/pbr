#pragma once
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

struct Camera_t {
	glm::mat4 cameraToWorld =  glm::mat4(1);
	glm::mat4 cameraToScreen = glm::mat4(1);
	glm::mat4 rasterToCamera = glm::mat4(1);
	glm::mat4 screenToRaster = glm::mat4(1);
	glm::mat4 rasterToScreen = glm::mat4(1);
	float shutterOpen = 0.f;
	float shutterClose = 1.f;
	float lensRadius = 0.f;
	float focalDistance = 1000000;
};

glm::mat4 rasterToScreen(float w, float h) {
	glm::mat4 mat = glm::translate(glm::mat4(1), glm::vec3(-1, -1, 0));
	mat = scale(mat, { 2 / w, 2 / h, 1 });
	return mat;
}

void configure(Camera_t& camera, glm::mat4 projection, glm::mat4 view, float w, float h) {
	camera.rasterToScreen = rasterToScreen(w, h);
	camera.screenToRaster = glm::inverse(camera.rasterToCamera);
	camera.cameraToScreen = projection;
	camera.rasterToCamera = inverse(projection) * camera.rasterToScreen;
	camera.cameraToWorld = inverse(view);
}