struct Camera {
	vec3 up;
	vec3 right;
	vec3 forward;
	vec3 position;
	float shutterOpen;
	float shutterClose;
	float lensRadius, 
	float focalDistance
};

struct CameraSample {
	vec2 pFilm;
	vec2 pLens;
	float time;
};