// Calculate the shadow distortion
//
// # Add the following to use:
// #include "lib/defs/distort.glsl"
//
// # Dependencies:
// - `include "lib/defs/properties.glsl"`

/**
 * Euclidian distance is defined as sqrt(a^2 +b^2 +...)
 * This length function instead does cbrt(a^3 + b^3 + ...)
 * This results in smaller distances along the diagonal axes.
 */
float cube_len(vec2 v) {
	return pow(abs(v.x*v.x*v.x) +abs(v.y*v.y*v.y), 1./3.);
}

float distort_factor(vec2 v) {
	return cube_len(v) +SHADOW_DISTORT_FACTOR;
}

vec3 distort313(vec3 v, float factor) {
	return vec3(v.xy/factor, v.z*.5);
}

vec3 distort33(vec3 v) {
	float factor = distort_factor(v.xy);
	return distort313(v, factor);
}