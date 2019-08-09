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