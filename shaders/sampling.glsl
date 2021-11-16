#pragma ignore(on)

#define PI                    3.1415926535897932384626422832795028841971
#define TWO_PI				  6.2831853071795864769252867665590057683943

#pragma ignore(off)


vec3 uniformSampleHemisphere(vec2 u){
	float y = u[0];
	float r = sqrt(max(0.0, 1.0 - y * y));
	float phi = TWO_PI * u[1];
	return vec3(r * cos(phi), y, r * sin(phi));
}

vec2 uniformSampleDisk(vec2 u){
	float r = sqrt(u[0]);
	float theta = TWO_PI * u[1];
	return vec2(r * cos(theta), r * sin(theta));
}

vec2 concentricSampleDisk(vec2 u) {
	vec2 uOffset = 2.0 * u - vec2(1);

	if (uOffset.x == 0.0 && uOffset.y == 0.0) return vec2(0);

	float theta, r;
	if (abs(uOffset.x) > abs(uOffset.y)) {
		r = uOffset.x;
		theta = PI * 0.25 * (uOffset.y / uOffset.x);
	}
	else {
		r = uOffset.y;
		theta = PI * 0.5 - PI * 0.25 * (uOffset.x / uOffset.y);
	}
	return r * vec2(cos(theta), sin(theta));
}


vec3 cosineSampleHemisphere(vec2 u) {
	vec2 d = concentricSampleDisk(u);
	float y = sqrt(max(0.0, 1.0 - d.x * d.x - d.y * d.y));
	return vec3( d.x, y, d.y );
}