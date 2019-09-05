const float OneMinusEpsilon = 0.99999994

uniform int nSamples;
uniform int nDimensions;

int samples1D[];
vec2 samples2D[];

int samples1DArray[];
vec2 samples2DArray[];

int  current1DDimension;
int current2DDimension;
int currentSample;

void initSampler();

CameraSample getCameraSample(vec2 pRaster);

float get1D();

vec2 get2D();

vec2 rejectionSampleDisk();
vec3 uniformSampleHemisphere(vec2 u);
float uniformSpherePdf();

vec3 uniformSampleCone(vec2 u, float thetamax);
vec3 uniformSampleCone(vec2 u, float thetamax, vec3 x, vec3 y, vec3 z);
float uniformConePdf();

vec2 uniformSampleDisk(vec2 u);

vec3 concentricSampleDist(vec2 u);

vec2 uniformSampleTriangle(vec2 u);