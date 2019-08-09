#version 450 core
#pragma debug(on)
#pragma optimize(off)
#pragma storeIntermediate(on)
const int MAX_LIGHT_SOURCES = 10;
const float PI = 3.14159265359;

struct LightSource{
	vec4 position;
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	vec4 spotDirection;
	float spotAngle;
	float spotExponent;
	float kc;
	float ki;
	float kq;
	bool transform;
	bool on;
};
struct LightModel {
	bool localViewer;
	bool twoSided;
	bool useObjectSpace;
	bool celShading;
	vec4 globalAmbience;
	bool colorMaterial;
};
struct Material{
	vec4 emission;
	vec4 ambient;
	vec4 diffuse;
	vec4 specular;
	float shininess;
	bool diffuseMap;
	bool specularMap;
	bool ambientMap;
	int bumpMap;
};
uniform LightSource light[MAX_LIGHT_SOURCES];
uniform LightModel lightModel;
uniform Material material[2];
uniform int numLights = 1;

in VERTEX{
	smooth vec3 position;
	smooth vec3 normal;
	smooth vec3 tangent;
    smooth vec3 bitangent;
	smooth vec2 texCoord;
	smooth vec4 color;
	smooth vec3 eyes;
	smooth vec4 lightDirection[MAX_LIGHT_SOURCES];
	smooth vec3 spotDirection[MAX_LIGHT_SOURCES];
} vertex_in;

layout(binding = 0) uniform sampler2D ambientMap;
layout(binding = 1) uniform sampler2D diffuseMap;
layout(binding = 2) uniform sampler2D specularMap;
layout(binding = 3) uniform sampler2D normalMap;
layout(binding = 4) uniform sampler2D displacementMap;
layout(binding = 5) uniform sampler2D reflectionMap;
layout(binding = 6) uniform sampler2D ambiantOcclusionMap;
vec4 getAmbience(Material m);
vec4 getDiffuse(Material m);
vec4 getSpecular(Material m);
vec4 diffuseContrib(vec3 L, vec3 N, LightSource light, Material m);
float daf(float dist, LightSource light){
	if (light.position.w == 0) return 1;
	return 1.0 / (light.kc + light.ki * dist + light.kq * dist * dist);
}
float saf(LightSource light, vec3 spotDirection, vec3 lightDirection, float h){
	if (light.position.w == 0) return 1;
	vec3 l = normalize(lightDirection);
	vec3 d =   normalize(spotDirection);
	
	if(light.spotAngle >= 180) 	return 1.0;
	if (light.spotAngle <= 0) return 0.0;
	
	float _LdotD = dot(-l, d);
	float inner = cos(radians(light.spotAngle - 5));
	float outter = cos(radians(light.spotAngle));
	
	float sl = smoothstep(outter, inner, _LdotD);
	return pow(sl, h); 
}
vec4 apply(LightSource light, vec3 spotDirection, vec4 direction, Material m){
	if(!light.on) return vec4(0);
	vec3 n = gl_FrontFacing ? normalize(vertex_in.normal) : normalize(-vertex_in.normal);
	vec3 N = lightModel.useObjectSpace ? (2.0 * texture(normalMap, vertex_in.texCoord) - 1.0).xyz : n;
	vec3 L = normalize(direction.xyz);
	float f = m.shininess;
		
	float _daf = daf(length(L), light);
	float _saf = saf(light, spotDirection, L, light.spotExponent);
	
	vec4 ambient = light.ambient * m.ambient;
	
	vec4 diffuse =  diffuseContrib(L, N, light, m);
	
	vec3 E = normalize(vertex_in.eyes);
	vec3 S = normalize(L + E);	// half way vector between light direction and eyes
	vec4 specular = pow(max(dot(S, N), 0), f) * light.specular * getSpecular(m);
	return  _daf * _saf * ((ambient + diffuse) + specular); 
}
vec4 phongLightModel(mat4 M){
	Material m = !lightModel.twoSided ?  material[0] : gl_FrontFacing ? material[0] : material[1];
	vec4 color = m.emission + lightModel.globalAmbience * getAmbience(m);
	for(int i = 0; i < numLights; i++ )
		color += apply(light[i], vertex_in.spotDirection[i], vertex_in.lightDirection[i], m);
	return color;
}
vec4 getAmbience(Material m){
    vec4 color = m.ambientMap ? m.ambient * texture(ambientMap, vertex_in.texCoord) : m.ambient;
	return lightModel.colorMaterial ? vertex_in.color : color;
}
vec4 getDiffuse(Material m){
    vec3 color = m.diffuseMap ? m.diffuse.xyz * pow(texture(diffuseMap, vertex_in.texCoord).xyz, vec3(2.2)) : m.diffuse.xyz;
	return lightModel.colorMaterial ? vertex_in.color : vec4(color, 1);
}
vec4 getSpecular(Material m) {
	vec4 color = m.specularMap ? m.specular * texture(specularMap, vertex_in.texCoord) : m.specular;
	return lightModel.colorMaterial ? vertex_in.color : color;
}

struct ToonShader{
	int levels;
	float scaleFactor;
} toonShader;
uniform int diffuseType = 0;
vec4 asdDiffuse(vec3 L, vec3 N, LightSource light, Material m){
	return  max(dot(L, N), 0)  * light.diffuse * getDiffuse(m);
}
vec4 toonDiffuse(vec3 L, vec3 N, LightSource light, Material m){
	toonShader.levels = 3;
	toonShader.scaleFactor = 1.0 / toonShader.levels;
	return floor(max(dot(L, N), 0) * toonShader.levels) * toonShader.scaleFactor * light.diffuse *  getDiffuse(m);
}
vec4 hemisphereDiffuse(vec3 L, vec3 N, LightSource light, Material m){
    float a = 0.5 + (0.5 * dot(L, N));
    return vec4(mix(vec3(0), vec3(1), a), 1);
}
vec4 diffuseContrib(vec3 L, vec3 N, LightSource light, Material m){
	switch(diffuseType){
        case 0: return asdDiffuse(L, N, light, m);
        case 1: return toonDiffuse(L, N, light, m);
        case 2: return hemisphereDiffuse(L, N, light, m);
        default: return vec4(0);
	}
}


out vec4 fragColor;

uniform bool gammaCorrect;

const float gamma = 2.2;

void main(){
	vec4 color = phongLightModel(mat4(1));
	fragColor = gammaCorrect ? vec4(pow(color.rgb, vec3(1/gamma)), 1.0) : color;	
}

