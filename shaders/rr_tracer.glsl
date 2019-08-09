#pragma ignore(on)
const int SPHERE_SHAPE = 0;
const int CYLINDER = 1;
const int BOX = 2;
const int TRIANGLE = 3;
const int PLANE = 4;

struct Plane {
	vec3 n;
	float d;
	int id;
};

struct Box {
	vec3 min;
	vec3 max;
};

struct Material {
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	float shine;
	float ior;
};

struct Sphere {
	vec3 c;
	vec3 color;
	mat4 objectToWorld;
	mat4 worldToObject;
	float r;
	float yMin;
	float yMax;
	float thetaMin;
	float thetaMax;
	float phiMax;
	int id;
};

struct Cylinder {
	mat4 objectToWorld;
	mat4 worldToObject;
	float r;
	float yMin;
	float yMax;
	float phiMax;
	int id;
};

struct Triangle {
	int id;	// TODO fix offset issue
	int objectToWorldId;
	int worldToObjectId;
	vec3 a;
	vec3 b;
	vec3 c;
};

struct Shading {
	vec3 n0;
	vec3 n1;
	vec3 n2;
	vec3 t0;
	vec3 t1;
	vec3 t2;
	vec3 bi0;
	vec3 bi1;
	vec3 bi2;
	vec2 uv0;
	vec2 uv1;
	vec2 uv2;
	int id;
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

//struct Medium;

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

struct SurfaceInteration {
	vec3 n;
	vec3 p;
	vec2 uv;
	vec3 dpdu;
	vec3 dpdv;
	int matId;
};

struct HitInfo {
	float t;
	int shape;
	int id;
	vec4 extras;
};

struct BVHNode {
	Box box;
	int splitAxis;
	int id;
	int offset;
	int size;
	int isLeaf;
	int child[2];
};

float rng(vec2 st) {
	return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}


void swap(inout float a, inout float b) {
	float temp = a;
	a = b;
	b = temp;
}

float surfaceArea(Sphere s) {
	return s.phiMax * s.r * (s.yMax - s.yMin);
}

Ray spawnRay(vec3 p0, vec3 p1);

Ray createRay(vec3 o, vec3 d, float tMax, float time) {
	Ray ray;
	ray.o = o;
	ray.d = d;
	ray.tMax = tMax;
	ray.time = time;
	return ray;
}

Ray transform(mat4 m, Ray ray) {
	Ray r;
	r.o = (m * vec4(ray.o, 1)).xyz;
	r.d = mat3(m) * ray.d;
	r.tMax = ray.tMax;
	return r;
}

#pragma ignore(off)


vec3 sphericalDirection(float sinTheta, float cosTheta, float phi);

bool isQuadratic(float a, float b, float c, out float t0, out float t1);

void fetchShading(int id, out Triangle tri, out Shading s);

bool intersectBVH(Ray ray, out HitInfo hit);

void fetchTriangle(int id, out Triangle tri);

bool intersectSphere(Ray ray, Sphere s, out HitInfo hit);

bool intersectsTriangle(Ray ray, out HitInfo hit);

bool triangleRayIntersect(Ray ray, Triangle tri, out float t, out float u, out float v, out float w);

bool intersectPlane(Ray ray, Plane p, out HitInfo hit);

bool intersectCylinder(Ray ray, Cylinder cylin, out HitInfo hit);

void intialize(HitInfo hit, Ray ray, out SurfaceInteration interact);

vec3 sphericalDirection(float sinTheta, float cosTheta, float phi, mat3 basis);

float sphericalTheta(vec3 v);

float sphericalPhi(vec3 v);

vec4 shade(vec3 p, vec3 n, vec3 l, vec3 pColor, int lightModel);

vec4 shade(SurfaceInteration interact, int depth);

bool hasNoVolume(Box box);

vec2 getUV(Ray ray, HitInfo hit);

vec3 getNormal(Ray ray, HitInfo hit);

vec3 getPosition(Ray ray, HitInfo hit);

float ro(float n);

float fresnel(float n, float cos0);

const int numSpheres = 1;

bool intersectScene(Ray ray, out HitInfo hit) {
	hit.t = ray.tMax;
	HitInfo local_hit;
	local_hit.t = hit.t;
	bool aHit = false;
	for (int i = 0; i < numSpheres; i++) {
		Sphere s = sphere[i];
		if (intersectSphere(ray, s, local_hit)) {
			aHit = true;
			if (local_hit.t < hit.t) {
				hit = local_hit;
			}
		}
	}
	
	local_hit.t = hit.t;
	if (intersectsTriangle(ray, local_hit)) {
		aHit = true;
		if (local_hit.t < hit.t) {
			hit = local_hit;
		}
	}

	return aHit;
}

bool intersectCube(Ray ray, Box box, out HitInfo hit) {
	if (hasNoVolume(box)) return false;
	vec3   tMin = (box.min - ray.o) / ray.d;
	vec3   tMax = (box.max - ray.o) / ray.d;
	vec3     t1 = min(tMin, tMax);
	vec3     t2 = max(tMin, tMax);
	float tn = max(max(t1.x, t1.y), t1.z);
	float tf = min(min(t2.x, t2.y), t2.z);

	if (tn > ray.tMax) return false;

	//	if(tn < tf){
	//		if(!testOnly){
	//			interation.p = ray.o + ray.d * tn;
	//			interation.n = -sign(ray.d) * step(t1.yzx, t1.xyz) * step(t1.zxy, t1.xyz);
	//		}
	//		return true;
	//	}

	hit.t = tn;
	hit.extras = vec4(t1, tf);
	hit.shape = BOX;

	return tn < tf;
}

const int MAX_DEPTH = 5;

struct Reflect_t {
	float kr;
	int id;
};

Reflect_t reflect_t[64];


vec4 trace(Ray ray, int depth) {
	if (depth >= MAX_DEPTH) return vec4(0);
	//Box box;
	//box.min = vec3(-1, 2, -1);
	//box.max = vec3(1, 4, 1);
	//Sphere s = sphere[0];
	//Cylinder c = cylinder[0];
	//c.objectToWorld = c.worldToObject = mat4(1);
	//c.id = 0;
	//c.r = 1;
	//c.yMax = 1;
	//c.yMin = -1;
	//c.phiMax = TWO_PI;
	//	s.c = vec3(0, 3, 0);
	//	s.r = 1;
	//	s.thetaMin = 0;
	//	s.thetaMax = PI;
	//	s.phiMax = TWO_PI;
	//	s.yMin = -1;
	//	s.yMax = 1;

	
		//if(intersectCube(ray, box, false, hit)){
		//	vec3 n = getNormal(ray, hit);
		//	color = vec4(abs(n), 1.0);
		//}

		//if(intersectSphere(ray, s, hit)){
		//	SurfaceInteration interact;
		//	intialize(hit, ray, interact);
		//	color = texture(checker, interact.uv);
		//}

		//if(intersectCylinder(ray, c, hit)){
		//	SurfaceInteration interact;
		//	intialize(hit, ray, interact);
		//	color = texture(checker, interact.uv);
		//}
		
		//else{
		//	color = texture(skybox, ray.d);
		//}
	//if (intersectsTriangle(ray, hit)) {
	//	vec3 p = ray.o + ray.d * hit.t;
	//	vec3 n = getNormal(ray, hit);
	//	vec2 uv = getUV(ray, hit);

	//	//	float t = p.z/maxDepth;
	//	//	t = 1 - 1/(1 + exp(-t));
	//	vec3 pColor = vec3(0.1, 0.1, 0.1);
	//	//	pColor = texture(checker, uv).xyz;
	//	vec4 lPos = camera.cameraToWorld * vec4(0, 0, 0, 1);
	//	color = shade(p, n, lPos.xyz, pColor, 0);
	//	color = vec4(n, 1);
	//	//	color = texture(checker, interact.uv);
	//	//	color = mix(vec4(0), vec4(1), t);
	//}
	//else {
	//	color = texture(skybox, ray.d);
	//}

	//Plane plane;
	//plane.n = vec3(0, 1, 0);
	//plane.d = 0;

	//if(intersectPlane(ray, plane, hit)){
	//	color = vec4(1, 0, 0, 0);
	//	vec3 p = ray.o + ray.d * hit.t;
	//	vec4 l = camera.cameraToWorld * vec4(0, 0, 0, 1);
	//	color = shade(p, plane.n, l.xyz, vec3(1, 0, 0), 0);
	//}else{
	//	color = texture(skybox, ray.d);
	//}
	HitInfo hit;
	vec4 color = vec4(0);

	if (intersectScene(ray, hit)) {
		SurfaceInteration interact;
		intialize(hit, ray, interact);

		float eta = 1 / 1.77;
		Ray reflectRay;
		reflectRay.o = interact.p;
		reflectRay.d = normalize( refract(ray.d, interact.n, eta) );

		color = mix(shade(interact, depth), texture(skybox, reflectRay.d), 0.6);
	//	color =  texture(skybox, reflectRay.d);
	}
	else {
		color = texture(skybox, ray.d);
	}
	return color;
}

vec4 shade(SurfaceInteration interact, int depth) {
	vec3 p = interact.p;
	vec3 n = interact.n;
	vec3 I = vec3(1);
	vec4 l = sphere[0].objectToWorld * vec4(sphere[0].c, 1.0);
	vec3 wi = l.xyz - p;
	vec3 wo = (camera.cameraToWorld * vec4(0, 0, 0, 1)).xyz;
	vec3 h = normalize(wi + wo);
	Material mat = material[interact.matId];
	vec3 ka = mat.ambient.xyz;
	vec3 kd = mat.diffuse.xyz;
	vec3 ks = mat.specular.xyz;
	float f = mat.shine;

	vec3 Li = ka * vec3(0.3) + I * (max(0, dot(wi, n)) * kd + max(0, pow(dot(h, n), f)) * ks);
	return vec4(Li, 1);
}

float ro(float n) {
	return ((n - 1) * (n - 1)) / ((n + 1) * (n + 1));
}

float fresnel(float n, float cos0) {
	float R0 = ro(n);
	return R0 + (1 - R0) * pow((1 - cos0), 5);
}


#pragma include("quadratic.glsl")
#pragma include("sphere.glsl")
#pragma include("cylinder.glsl")
#pragma include("plane.glsl")
#pragma include("ray_triangle.glsl")
#pragma include("interaction.glsl")
#pragma include("light.glsl")
#pragma include("sphericalCS.glsl")