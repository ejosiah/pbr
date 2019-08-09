#version 450 core
#pragma debug(on)
#pragma optimize(off)

layout(binding=0) uniform sampler2D image;

out vec4 fragColor;

void main(){
	fragColor = texture(image, vec2(gl_FragCoord.xy)/ vec2(textureSize(image, 0)));
}