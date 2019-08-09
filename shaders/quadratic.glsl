bool isQuadratic(float a, float b, float c, out float t0, out float t1) {

	float discr = b * b - 4 * a * c;
	if (discr < 0) return false;
	float sqrtDiscr = sqrt(discr);
	t0 = (-b - sqrtDiscr) / (2 * a);
	t1 = (-b + sqrtDiscr) / (2 * a);

	if (t0 > t1) swap(t0, t1);

	return true;
}
