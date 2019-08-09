#pragma ignore(on)
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

#pragma ignore(off)


bool intersectSphere(Ray ray, Sphere s, out HitInfo hit) {
	float t0 = -1;
	float t1 = t0;

	Ray r = transform(s.worldToObject, ray);

	vec3 m = r.o - s.c;
	float a = dot(r.d, r.d);
	float b = dot(m, ray.d);
	float c = dot(m, m) - s.r * s.r;

	if (c > 0.0f && b > 0.0f) return false;

	float discr = b * b - a * c;

	if (discr < 0.0) return false;
	float sqrtDiscr = sqrt(discr);

	t0 = (-b - sqrtDiscr) / a;
	t1 = (-b + sqrtDiscr) / a;
	if (t0 > t1) swap(t0, t1);

	float tHit = t0;
	if (tHit <= 0) tHit = t1;
	if (tHit > r.tMax) return false;

	vec3 p = r.o + r.d * tHit;
	p *= s.r / distance(p, s.c);
	if (p.x == 0 && p.z == 0) p.x = 1E-5 * s.r;
	float phi = atan(p.z, p.x);
	if (phi < 0) phi += TWO_PI;

	if ((s.yMin > -s.r && p.y < s.yMin) || (s.yMax < s.r && p.y > s.yMax) || phi > s.phiMax) {
		if (tHit == t1) return false;
		if (t1 > ray.tMax) return false;

		tHit = t1;
		p = r.o + r.d * tHit;
		p *= s.r / distance(p, s.c);
		if (p.x == 0 && p.z == 0) p.x = 1E-5 * s.r;
		float phi = atan(p.z, p.x);
		if (phi < 0) phi += TWO_PI;

		if ((s.yMin > -s.r && p.y < s.yMin)
			|| (s.yMax < s.r && p.y > s.yMax)
			|| phi > s.phiMax) return false;
	}

	hit.t = tHit;
	hit.shape = SPHERE_SHAPE;
	hit.id = s.id;
	hit.extras.x = phi;
	return true;
}