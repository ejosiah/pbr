#pragma ignore(on)
struct Plane {
	vec3 n;
	float d;
	int id;
	int matId;
};

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
	int objId;
	int objType;
};

struct HitInfo {
	float t;
	int shape;
	int id;
	vec4 extras;
};


#pragma ignore(off)

vec3 computePrimaryTexDir(vec3 n, vec3 p) {
	vec3 a = cross(n, vec3(1, 0, 0));
	vec3 b = cross(n, vec3(0, 0, 1));

	vec3 max_ab = dot(a, a) < dot(b, b) ? b : a;

	vec3 c = cross(n, vec3(0, 1, 0));

	return normalize(dot(max_ab, max_ab) < dot(c, c) ? c : max_ab);
}

bool intersectPlane(Ray ray, Plane p, out HitInfo hit) {

	float t = p.d - dot(p.n, ray.o);
	t /= dot(p.n, ray.d);

	if (t < 0 || t > ray.tMax) {
		return false;
	}
	hit.t = t;
	hit.id = p.id;
	hit.shape = PLANE;
	return true;
}