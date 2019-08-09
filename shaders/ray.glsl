#pragma ignore(on)

struct Ray {
	vec3 o;
	vec3 d;
	float tMax;
	float time;
	//	Medium medium;

		// Ray differentials
	bool hasDefferntials;
	vec3 rxo, ryo;
	vec3 rxd, ryd;

};

struct Camera {
	mat4 cameraToWorld;
	mat4 cameraToScreen;
	mat4 rasterToCamera;
	mat4 screenToRaster;
	mat4 rasterToScreen;
	float shutterOpen;
	float shutterClose;
	float lensRadius;
	float focalDistance;
};

struct CameraSample {
	vec2 pFilm;
	vec2 pLens;
	float time;
};


#pragma ignore(off)

Ray spawnRay(vec3 p0, p1) {
	return createRay(p0, normalize(p1 - p0), 10000, 1);
}

Ray createRay(vec3 o, vec3 d, float tMax, float time) {
	Ray ray;
	ray.o = o;
	ray.d = d;
	ray.tMax = tMax;
	ray.time = time;
	return ray;
}

void generateRay(in CameraSample csample, in Camera camera, out Ray ray) {
	vec3 p = (camera.rasterToCamera * vec4(csample.pFilm, 0, 1)).xyz;
	ray.o = vec3(0);
	ray.d = normalize(p);
	ray.tMax = far;

	ray.o = (camera.cameraToWorld * vec4(ray.o, 1)).xyz;
	ray.d = mat3(camera.cameraToWorld) * ray.d;
	ray.d = normalize(ray.d);
}


Ray transform(mat4 m, Ray ray) {
	Ray r;
	r.o = (m * vec4(ray.o, 1)).xyz;
	r.d = mat3(m) * ray.d;
	r.tMax = ray.tMax;
	return r;
}