bool intersectCylinder(Ray ray, Cylinder cylin, out HitInfo hit) {
	Ray r = transform(cylin.worldToObject, ray);

	vec2 d = r.d.xz;
	vec2 o = r.o.xz;

	float a = dot(d, d);
	float b = 2 * dot(o, d);
	float c = dot(o, o) - cylin.r * cylin.r;

	float t0; float t1;
	if (!isQuadratic(a, b, c, t0, t1)) return false;
	if (t0 > r.tMax || t1 <= 0) return false;
	float tHit = t0;
	if (tHit <= 0) {
		tHit = t1;
		if (tHit > ray.tMax) return false;
	}

	vec3 p = r.o + r.d * tHit;
	float hitRad = length(p.xz);
	p.x *= cylin.r / hitRad;
	p.z *= cylin.r / hitRad;

	float phi = atan(p.z, p.x);
	if (phi < 0) phi += TWO_PI;

	if (p.y < cylin.yMin || p.y > cylin.yMax || phi > cylin.phiMax) {
		if (tHit == t1) return false;
		tHit = t1;
		if (tHit > r.tMax) return false;

		vec3 p = r.o + r.d * tHit;
		float hitRad = length(p.xz);
		p.x *= cylin.r / hitRad;
		p.z *= cylin.r / hitRad;
		float phi = atan(p.z, p.x);
		if (phi < 0) phi += TWO_PI;

		if (p.y < cylin.yMin || p.y > cylin.yMax || phi > cylin.phiMax) return false;
	}

	hit.t = tHit;
	hit.shape = CYLINDER;
	hit.id = cylin.id;
	hit.extras.x = phi;

	return true;
}