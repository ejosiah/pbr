#pragma ignore(on)
struct Triangle {
	vec3 a;
	vec3 b;
	vec3 c;
	int objectToWorldId;
	int worldToObjectId;
	int id;
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
	vec4 color;
	vec4 matId;
	int shape;
	int shapeId;
};

struct HitInfo {
	float t;
	int shape;
	int id;
	vec4 extras;
};

#pragma ignore(off)

void intialize(HitInfo hit, Ray ray, out SurfaceInteration interact) {

	switch (hit.shape) {
	case SPHERE_SHAPE: {
		Sphere s = sphere[hit.id];
		Ray r = transform(s.worldToObject, ray);
		vec3 p = r.o + r.d * hit.t;
		p *= s.r / distance(p, s.c);
		vec3 n = p - s.c;
		float phi = atan(p.z, p.x);
		float u = phi / s.phiMax;
		float theta = acos(clamp(p.y / s.r, -1, 1));
		float v = (theta - s.thetaMin) / (s.thetaMax - s.thetaMin);
		mat4 otw = s.objectToWorld;

		interact.p = (otw * vec4(p, 1)).xyz;
		interact.n = normalize( mat3(otw) * n);
		interact.uv = vec2(u, v);
		interact.color = vec4(0, 1, 0, 1);
		interact.matId = s.matId;
		interact.shape = SPHERE_SHAPE;

		// calculate shading data
		float yRadius = length(p.xz);
		float invYRaduis = 1.0/yRadius;
		float cosPhi = p.x * invYRaduis;
		float sinPhi = p.y * invYRaduis;

		vec3 dpdu = vec3(-s.phiMax * p.z, 0, s.phiMax * p.x);
		vec3 dpdv = (s.thetaMax - s.thetaMin) * vec3(p.y * cosPhi, s.r * sin(theta), p.y * sinPhi);

		vec3 d2Pduu = -s.phiMax * s.phiMax * vec3(p.x, 0, p.z);
		vec3 d2Pduv = (s.thetaMax - s.thetaMin) * p.y * s.phiMax * vec3(-sinPhi, 0, cosPhi);
		vec3 d2Pdvv = -(s.thetaMax - s.thetaMin) * (s.thetaMax - s.thetaMin) * p;

		float E = dot(dpdu, dpdu);
		float F = dot(dpdu, dpdv);
		float G = dot(dpdv, dpdv);

		vec3 N = normalize(cross(dpdu, dpdv));
		float e = dot(n, d2Pduu);
		float f = dot(n, d2Pduv);
		float g = dot(n, d2Pdvv);
		
		float invEGF2 = 1.0/(E * G - F * F);
		vec3 dndu = vec3((f * F - e * G) * invEGF2 * dpdu + (e * F - f * E) * invEGF2 * dpdv);
		vec3 dndv = vec3((g * F - f * G) * invEGF2 * dpdu + (f * F - g * E) * invEGF2 * dpdv);

		break;
	}
	case CYLINDER: {
		Cylinder c = cylinder[0];
		c.objectToWorld = c.worldToObject = mat4(1);
		c.id = 0;
		c.r = 1;
		c.yMax = 1;
		c.yMin = -1;
		c.phiMax = TWO_PI;

		Ray r = transform(c.worldToObject, ray);
		vec3 p = r.o + r.d * hit.t;
		float hitRad = length(p.xz);
		p.x *= c.r / hitRad;
		p.z *= c.r / hitRad;

		float phi = hit.extras.x;
		float u = phi / c.phiMax;
		float v = (p.y - c.yMin) / (c.yMax - c.yMin);

		vec3 dpdu = vec3(-c.phiMax * p.y, 0, c.phiMax * p.x);
		vec3 dpdv = vec3(0, c.yMax - c.yMin, 0);
		vec3 n = normalize(cross(dpdu, dpdv));

		interact.p = p; //(c.objectToWorld * vec4(p, 1)).xyz;
		interact.n = n;
		interact.uv = vec2(u, v);
		interact.dpdu = dpdu;
		interact.dpdv = dpdv;
		interact.shape = CYLINDER;
		break;
	}
	case TRIANGLE: {
		Triangle tri;
		Shading s;
		fetchShading(hit.id, tri, s);
		float u = hit.extras.x;
		float v = hit.extras.y;
		float w = hit.extras.z;
		vec3 p = ray.o + ray.d * hit.t;
		vec2 uv = s.uv0 * u + s.uv1 * v + s.uv2 * w;
		vec3 n = s.n0 * u + s.n1 * v + s.n2 * w;

		interact.p = p;
		interact.n = n;
		interact.uv = uv;
		interact.color = vec4(0.1, 0.1, 0.1, 1);
		interact.matId = tri.matId;
		interact.shape = TRIANGLE;
		break;
	}
	case BOX: {
		interact.p = ray.o + ray.d * hit.t;
		break;
	}
	case PLANE: {
		Plane pl = plane[hit.id];
		interact.p = ray.o + ray.d * hit.t;
		interact.n = pl.n;
		interact.color = vec4(0.3, 0.3, 0.3, 1);
		interact.matId = pl.matId;
		interact.shape = PLANE;
		interact.shapeId = hit.id;

	
		vec3 p = interact.p;
		interact.uv = vec2(p.x / 100, p.z / 100);
		break;
	}
	}
}

vec2 getUV(Ray ray, HitInfo hit) {
	switch (hit.shape) {
	case TRIANGLE:
		Triangle tri;
		Shading s;
		fetchShading(hit.id, tri, s);
		float u = hit.extras.x;
		float v = hit.extras.y;
		float w = hit.extras.z;
		return s.uv0 * u + s.uv1 * v + s.uv2 * w;
	default:
		return vec2(0);
	}
}

vec3 getNormal(Ray ray, HitInfo hit) {
	switch (hit.shape) {
	case TRIANGLE:
		Triangle tri;
		Shading s;
		fetchShading(hit.id, tri, s);
		float u = hit.extras.x;
		float v = hit.extras.y;
		float w = hit.extras.z;
		return s.n0 * u + s.n1 * v + s.n2 * w;
	default:
		return vec3(0);
	}
}

