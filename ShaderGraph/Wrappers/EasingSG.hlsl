#ifndef COLESLOW_SG_EASING_INCLUDED
#define COLESLOW_SG_EASING_INCLUDED

// Shader Graph wrapper layer for com.coleslow.shaderlib (Easing module).
// See ShaderGraph/README.md for the convention and how to add a node.

#include "Packages/com.coleslow.shaderlib/Shaders/Easing.hlsl"

void SmootherStep_float(float T, out float Out) { Out = SmootherStep(T); }
void SmootherStep_half(half T, out half Out)     { Out = SmootherStep(T); }

void EaseInOutCubic_float(float T, out float Out) { Out = EaseInOutCubic(T); }
void EaseInOutCubic_half(half T, out half Out)     { Out = EaseInOutCubic(T); }

void EaseOutElastic_float(float T, out float Out) { Out = EaseOutElastic(T); }
void EaseOutElastic_half(half T, out half Out)     { Out = EaseOutElastic(T); }

void EaseOutBounce_float(float T, out float Out) { Out = EaseOutBounce(T); }
void EaseOutBounce_half(half T, out half Out)     { Out = EaseOutBounce(T); }

void Gain_float(float T, float K, out float Out) { Out = Gain(T, K); }
void Gain_half(half T, half K, out half Out)     { Out = Gain(T, K); }

void Pulse_float(float Edge0, float Edge1, float X, out float Out) { Out = Pulse(Edge0, Edge1, X); }
void Pulse_half(half Edge0, half Edge1, half X, out half Out)      { Out = Pulse(Edge0, Edge1, X); }

#endif
