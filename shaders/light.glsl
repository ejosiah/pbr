#pragma ignore(on)
struct LightSource {
	vec3 power;
};
#pragma ignore(off)

/*

vec3 E(vec3 p, vec3 n); // irradiance

vec3 Li(vec3 p, vec3 w, LightSource light);	// incoming radiance

vec3 Lo(vec3 p, vec3 w, LightSource light); // outgoing radiance
*/

vec4 shade(vec3 p, vec3 n, vec3 l, vec3 pColor, int lightModel) {
	vec3 light = vec3(1);
	vec3 gAmb = vec3(0.3);

	vec3 L = l - p;
	vec3 color = gAmb * pColor;
	color += max(0, dot(L, n)) * light * pColor;

	return vec4(color, 1);
}