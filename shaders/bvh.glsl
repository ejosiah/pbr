#pragma ignore(on)

struct Plane {
	vec3 n;
	float d;
	int id;
};

struct Box {
	vec3 min;
	vec3 max;
};

struct Sphere {
	vec3 c;
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
	int id;	
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
};

struct HitInfo {
	float t;
	int shape;
	int id;
	vec4 extras;
};

struct BVHNode {
	Box box;
	int primitiveType;
	int id;
	int offset;
	int size;
	int isLeaf;
	int child[2];
};

#pragma ignore(off)

bool intersectBVH(Ray ray, out HitInfo hit) {
	return false;
}
