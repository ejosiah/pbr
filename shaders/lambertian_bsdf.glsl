#pragma once


#pragma ignore(on)

#extension GL_EXT_gpu_shader4 : enable
#define INV_PI				  0.31830988618379067153776752674503

struct SurfaceInteration{
	vec3 n;
	vec3 p;
	vec2 uv;
	vec3 dpdu;
	vec3 dpdv;
	vec4 color;
	int matId;
	int shape;
	int shapeId;
};

struct Material {
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	vec4 kr;
	vec4 kt;
	float shine;
	float ior;
	int bsdf[16];
};


Material material[10];

vec3 fresnel(vec3 ni, vec3 nt, vec3 k, float cos0i, int type);

const int BSDF_REFLECTION = 1 << 0;
const int BSDF_TRANSMISSION = 1 << 1;
const int BSDF_DIFFUSE = 1 << 2;
const int BSDF_GLOSSY = 1 << 3;
const int BSDF_SPECULAR = 1 << 4;
const int BSDF_ALL = BSDF_DIFFUSE | BSDF_GLOSSY | BSDF_SPECULAR | BSDF_REFLECTION | BSDF_TRANSMISSION;

const int FRESNEL_NOOP = 1 << 0;
const int FRESNEL_DIELECTRIC  = 1 << 1;
const int FRESNEL_CONDOCTOR = 1 << 2;

vec3 cosineSampleHemisphere(vec2 u);
float absCosTheta(vec3 w);


#pragma ignore(off)

/*
	bool matchFlags(int type);
	vec3 f(vec3 wo, vec3 wi);
	vec3 sample_f(vec3 wo, out vec3 wi, vec2 u, out float pdf, int type);
	vec3 rho(vec3 wo, int nSamples);
	vec3 rho1(int nSamples);
	float Pdf(vec3 wi, vec3 wo);
*/

float LambertianReflection_Pdf(vec3 wi, vec3 wo){
	return dot(wi, wo) > 0.0 ? absCosTheta(wi) * INV_PI : 0.0;
}

vec3 LambertianReflection_f(vec3 wo, vec3 wi, SurfaceInteration interact) {
	vec3 R = material[interact.matId].kr.xyz;
	return R * INV_PI;
}

vec3 LambertianReflection_Sample_f(vec3 wo, out vec3 wi, vec2 u, out float pdf, SurfaceInteration interact) {
	
	wi = cosineSampleHemisphere(u);
	if(wo.z < 0.0) wi.y *= -1.0;
	pdf = LambertianReflection_Pdf(wo, wi);

	return LambertianReflection_f(wo, wi, interact);
}
