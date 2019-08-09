#pragma once

template<size_t n>
struct SampledSpectrum {
	float lambda[n];
	float value[n];

	const size_t size = n;
};

static const int nCIESamples = 471;

struct XYZColorCurves {
	
	const float X[nCIESamples];
	const float Y[nCIESamples];
	const float Z[nCIESamples];
};