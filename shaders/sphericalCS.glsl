vec3 sphericalDirection(float sinTheta, float cosTheta, float phi, mat3 basis) {
	vec3 d = vec3(sinTheta * sin(phi), cosTheta, sinTheta * cos(phi));
	return basis * d;
}

float sphericalTheta(vec3 v) {
	return acos(clamp(v.y, -1, 1));
}

float sphericalPhi(vec3 v) {
	float phi = atan(v.x / v.z);
	return phi < 0 ? (phi + TWO_PI) : phi;
}