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

#pragma include("stack.glsl")
#pragma include("tree.glsl")


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

	//Plane plane;
	//plane.n = vec3(0, 1, 0);
	//plane.d = 0;
	//plane.id = 10;

	//local_hit.t = hit.t;
	//if(intersectPlane(ray, plane, local_hit)){
	//	aHit = true;
	//	if (local_hit.t < hit.t) {
	//		hit = local_hit;
	//	}
	//}

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

const int MAX_DEPTH = 1;



struct Params{
	vec3 color;
	float k;
	int depth;
	SurfaceInteration interact;
	Ray ray;
};

Params params[64];

bool isNull(int node){
	if(node < 0) return true;
	if (params[node].depth < 0 || params[node].depth >= MAX_DEPTH) return true;
	return false;
}

void doIntersect(inout Params pms){
	HitInfo hit;
	if(pms.depth == MAX_DEPTH){
		pms.color = vec3(0);
	}else if (intersectScene(pms.ray, hit)) {
		intialize(hit, pms.ray, pms.interact);

		pms.color = shade(pms.interact, 0).xyz;
	}
	else {
		pms.color = texture(skybox, pms.ray.d).xyz;
	}
}

vec4 trace(Ray ray, int depth) {
	if (depth >= MAX_DEPTH) return vec4(0);
	
	vec4 color = vec4(0);

	params[0].depth = 0;
	params[0].k = 1;
	params[0].ray = ray;
	doIntersect(params[0]);

	stack stack;
	init(stack);
	int root = 0;
	
	do {
		
		while (!isNull(root)) {

			float ior = material[params[root].interact.matId].ior;

			if (ior > 0) {
				SurfaceInteration interact = params[root].interact;
				vec4 l = sphere[0].objectToWorld * vec4(sphere[0].c, 1.0);
				vec3 wi = normalize(l.xyz - interact.p);
				vec3 wo = normalize((camera.cameraToWorld * vec4(0, 0, 0, 1)).xyz);
				vec3 h = normalize(wi + wo);
				float kr = fresnel(ior, dot(l.xyz, h));
				float kt = 1 - kr;


				int right_child = right(root);
				params[right_child].depth = params[root].depth + 1;
				params[right_child].k = kr;

				params[right_child].ray.o = interact.p;
				params[right_child].ray.d = normalize(reflect(params[root].ray.d, interact.n));
				params[right_child].ray.tMax = params[root].ray.tMax;
				doIntersect(params[right_child]);


				int left_child = left(root);
				params[left_child].depth = params[root].depth + 1;
				params[left_child].k = kt;

				params[left_child].ray.o = interact.p;
				params[left_child].ray.d = normalize(refract(params[root].ray.d, interact.n, 1 / ior));
				params[left_child].ray.tMax = params[root].ray.tMax;

				doIntersect(params[left_child]);
			}
			else {
				int right_child = right(root);
				int left_child = left(root);

				params[right_child].depth = -1;
				params[left_child].depth = -1;
			}
	
			if (!isNull(right(root))) {
				push(stack, right(root));
			}
			push(stack, root);
			root = left(root);
		}

		root = pop(stack);

		if (!isNull(right(root)) && peek(stack) == right(root)) {
			pop(stack);
			push(stack, root);
			root = right(root);
		}
		else {
			if(!isNull(right(root))){
				params[root].color += params[right(root)].color * params[right(root)].k;
			}
			if(!isNull(left(root))){
				params[root].color += params[left(root)].color * params[left(root)].k;
			}
			root = -1;
		}

	} while (!empty(stack));
	
	return  vec4(params[0].color, 1);
}

vec4 shade(SurfaceInteration interact, int depth) {
	vec3 p = interact.p;
	vec3 n = interact.n;
	vec3 I = vec3(1);
	vec4 l = sphere[0].objectToWorld * vec4(sphere[0].c, 1.0);
	vec3 wi = normalize( l.xyz - p);
	vec3 wo = normalize( (camera.cameraToWorld * vec4(0, 0, 0, 1)).xyz );
	vec3 h = normalize(wi + wo);

	vec3 ka = vec3(0);
	vec3 kd = interact.color.xyz;
	vec3 ks = I;
	float f = 5.0;

	if(interact.matId >= 0){
		Material mat = material[interact.matId];
		ka = mat.ambient.xyz;
		kd = mat.diffuse.xyz;
		ks = mat.specular.xyz;
		f = mat.shine;
	}

	vec3 Li = ka * vec3(0.3) + I * ka;
	Li += I * max(0, dot(wi, n)) * kd;
	Li += I * max(0, pow(dot(wo, h), f)) * ks;
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