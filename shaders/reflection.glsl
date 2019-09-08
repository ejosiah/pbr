int BSDF_REFLECTION = 1 << 0;
int BSDF_TRANSMISSION = 1 << 1;
int BSDF_DIFFUSE = 1 << 2;
int BSDF_GLOSSY = 1 << 3;
int BSDF_SPECULAR = 1 << 4;
int BSDF_ALL = BSDF_DIFFUSE | BSDF_GLOSSY | BSDF_SPECULAR | BSDF_REFLECTION | BSDF_TRANSMISSION;

struct SpecularReflection {
	vec3 r;
	int type = BSDF_REFLECTION | BSDF_SPECULAR;
};

vec3 SpecularReflection_f(vec3 wo, vec3 wi) {
	return vec3(0);
}

vec3 SpecularReflection_Sample_f(vec3 wo, out vec3 wi, vec2 u, out float pdf) {
	wi.x = -wo.x;
	wi.z = -wo.z;
	wi.y = wo.y;
	pdf = 0;
}

vec3 f(vec3 wo, vec3 wi, int type);

vec3 Sample_f(vec3 wo, out vec3 wi, vec2 u, out float pdf, int type);

float Pdf(vec3 wo, vec3 wi, int type);