#extension GL_EXT_gpu_shader4 : enable

#pragma ignore(on)

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
};


Material material[10];
#pragma ignore(off)

/*
	Reflection computation are evaluated in the reflection coordinate systsem
	where the two tangent vectors and normal vector at t the point begin shaded
	are aligned with the x, y z axis, repectively that is 
	(t, n, b) -> (x, y, z)
*/

const int BSDF_REFLECTION = 1 << 0;
const int BSDF_TRANSMISSION = 1 << 1;
const int BSDF_DIFFUSE = 1 << 2;
const int BSDF_GLOSSY = 1 << 3;
const int BSDF_SPECULAR = 1 << 4;
const int BSDF_ALL = BSDF_DIFFUSE | BSDF_GLOSSY | BSDF_SPECULAR | BSDF_REFLECTION | BSDF_TRANSMISSION;

const int SPECIULAR_REFLECT = BSDF_REFLECTION | BSDF_SPECULAR;

const int FRESNEL_NOOP = 1 << 0;
const int FRESNEL_DIELECTRIC  = 1 << 1;
const int FRESNEL_CONDOCTOR = 1 << 2;

float cosTheta(vec3 w) { return w.y; }
float cos2Theta(vec3 w) { return w.y; }
float absCosTheta(vec3 w) { return abs(w.y); }
float sin2Theta(vec3 w) { return max(0.0, 1.0 - cos2Theta(w)); }
float sinTheta(vec3 w) { return sqrt(sin2Theta(w)); }
float tanTheta(vec3 w) { return sinTheta(w)/cosTheta(w); }
float tan2Theta(vec3 w) { return sin2Theta(w)/cos2Theta(w); }

bool sameHemisphere(vec3 w, vec3 wp){
	return w.y * wp.y > 0.0;
}

float cosPhi(vec3 w){ 
	float sin0 = sinTheta(w);
	return (sin0 == 0.0) ? 1.0 : clamp(w.x/sin0, -1.0, 1.0);
}

float sinPhi(vec3 w){ 
	float sin0 = sinTheta(w);
	return (sin0 == 0.0) ? 1.0 : clamp(w.z/sin0, -1.0, 1.0);
}

float cosDPhi(vec3 wa, vec3 wb){
	return dot(wa, wb)/(length(wa) * length(wb));
}

float cos2Phi(vec3 w){
	float cosPh = cosPhi(w);
	return cosPh * cosPh;
}

float sin2Phi(vec3 w){
	float sin2PhiW = sinPhi(w);
	return sin2PhiW * sin2PhiW;
}

void swap(inout float a, inout float b){
	float temp = a;
	a = b;
	b = temp;
}

vec3 frDielectric(float cos0i, float ni, float nt){
	cos0i = clamp(cos0i, -1.0, 1.0);

		bool entering = cos0i > 0.0;
	if(!entering){
		swap(ni, nt);
		cos0i = abs(cos0i);
	}

	float sin0i = sqrt(max(0.0, 1.0 - cos0i * cos0i));
	float sin0t = ni/(nt * sin0i);

	if(sin0t >= 1.0) return vec3(1.0); // total internal reflection

	float cos0t = sqrt(max(0.0, 1.0 - sin0t * sin0t));

	float rPar = (nt * cos0i - ni * cos0t) / (nt * cos0i + ni * cos0t);
	float rPerp = (ni * cos0i - nt * cos0t)/(ni * cos0i + nt * cos0t);

	return vec3(0.5 * (rPar * rPar + rPerp * rPerp));
}

vec3 FrConductor(float cos0i, vec3 ni, vec3 nt, vec3 k){
	cos0i = clamp(cos0i, -1.0, 1.0);

	vec3 n = nt / ni;
	vec3 nk = k / ni;

	float cos20i = cos0i * cos0i;
	float sin20i = 1.0 - cos20i;

	vec3 n2 = n * n;
	vec3 nk2 = nk * nk;

	vec3 t0 = n2 - nk2 - sin20i;
	vec3 a2plusb2 = sqrt(t0 * t0 + 4.0 * n2 * nk2);
	vec3 t1 = a2plusb2 + cos20i;
	vec3 a = sqrt(0.5 * (a2plusb2 + t0));
	vec3 t2 = 2.0 * cos0i * a;
	vec3 Rs = (t1 - t2)/(t1 + t2);

	vec3 t3 = cos20i * a2plusb2 + sin20i * sin20i;
	vec3 t4 = t2 * sin20i;
	vec3 Rp = Rs * (t3 - t4) / (t3 + t4);

	return 0.5 * (Rp + Rs);
}

vec3 fresnel(vec3 ni, vec3 nt, vec3 k, float cos0i, int type){
	switch(type){
		case FRESNEL_DIELECTRIC:
			return frDielectric(cos0i, ni.x, nt.x);
		case FRESNEL_CONDOCTOR:
			return FrConductor(cos0i, ni, nt, k);
		default:
			return vec3(1.0);
	}
}

vec3 bsdf_worldToLocal(vec3 v, SurfaceInteration intaract);

vec3 bsdf_localToWorld(vec3 v, SurfaceInteration intaract);


/*
	bool matchFlags(int type);
	vec3 f(vec3 wo, vec3 wi);
	vec3 sample_f(vec3 wo, out vec3 wi, vec2 u, out float pdf, int type, SurfaceInteration intaract);
	vec3 rho(vec3 wo, int nSamples);
	vec3 rho1(int nSamples);
	float Pdf(vec3 wi, vec3 wo);
*/

vec3 f(vec3 wo, vec3 wi, int type);

vec3 Sample_f(vec3 wo, out vec3 wi, vec2 u, out float pdf, SurfaceInteration intaract);

float Pdf(vec3 wo, vec3 wi, int type);