// Utility functions
//
// # Add the following to use:
// #include "lib/utils/functions.glsl"

/* clamp(x, 0., 1.) */
#define saturate(x) clamp(x, 0., 1.)

/* I don't like `mix()`. */
#define lerp(x, a ,b) mix(x, a, b)

/*
 * Change the chroma of the color.
 * 
 * # Arguments
 * - color: Color to change.
 * - amount: Percentage to change saturation. 0.0 is no change.
 */
vec3 chroma(const vec3 color, const float amount) {
    float avg = (color.r +color.g +color.b)/3.;
    return saturate(color +(avg -color)*(1. -amount));
}
/*vec3 chroma_old(vec3 color, const float amount) {
    if (color.g < color.r && color.b < color.r) {
        color.gb *= amount;
    } else if (color.r < color.g && color.b < color.g) {
        color.rb *= amount;
    } else if (color.r < color.b && color.g < color.b) {
        color.rg *= amount;
    }
    return color;
}*/

/* Get the luma of the color. */
float luma(const vec3 color) {
    return dot(color, vec3(.2126, .7152, .0722));
}

/* https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve */
vec3 ACESFilm(const vec3 x) {
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate(
        (x*(a*x +b))/
        (x*(c*x +d) +e)
    );
}

/**
 * Hash without Sine (1 out 1 in)
 * https://www.shadertoy.com/view/4djSRW
 *
 * Copyright (c) 2014 David Hoskins.
 * Distributed under the MIT License: https://opensource.org/licenses/mit-license.php
 */
float hash11(float p) {
    p = fract(p*.1031);
    p *= p +33.33;
    p *= p +p;
    return fract(p);
}

/**
 * Hash without Sine (1 out 2 in)
 * https://www.shadertoy.com/view/4djSRW
 *
 * Copyright (c) 2014 David Hoskins.
 * Distributed under the MIT License: https://opensource.org/licenses/mit-license.php
 */
float hash12(const vec2 p) {
	vec3 p3  = fract(vec3(p.xyx)*.1031);
    p3 += dot(p3, p3.yzx +33.33);
    return fract((p3.x + p3.y)*p3.z);
}

/**
 * Hash without Sine (1 out 3 in)
 * https://www.shadertoy.com/view/4djSRW
 *
 * Copyright (c) 2014 David Hoskins.
 * Distributed under the MIT License: https://opensource.org/licenses/mit-license.php
 */
float hash13(vec3 p3) {
	p3 = fract(p3*.1031);
    p3 += dot(p3, p3.zyx +31.32);
    return fract((p3.x +p3.y)*p3.z);
}

/**
 * 1 out 2 in 2D Noise. 
 * https://www.shadertoy.com/view/4dS3Wd
 *
 * By Morgan McGuire @morgan3d, http://graphicscodex.com
 * Reuse permitted under the BSD license: https://opensource.org/licenses/BSD-3-Clause
 */
float noise12(vec2 x) {
    vec2 i = floor(x);
    vec2 f = fract(x);

	// Four corners in 2D of a tile.
	float a = hash12(i);
    float b = hash12(i +vec2(1., 0.));
    float c = hash12(i +vec2(0., 1.));
    float d = hash12(i +vec2(1., 1.));

    // Simple 2D lerp using smoothstep envelope between the values.
	/*return vec3(mix(
        lerp(a, b, smoothstep(0., 1., f.x)),
		lerp(c, d, smoothstep(0., 1., f.x)),
        smoothstep(0., 1., f.y)
    ));*/

    // Same code.
    // with the clamps in smoothstep and common subexpressions optimized away.
	// Cubic Hermine Curve. Same as smoothstep().
    vec2 u = f*f*(3. -2.*f);
	return lerp(a, b, u.x) +(c -a)*u.y*(1. -u.x) +(d -b)*u.x*u.y;
}

/**
 * 1 out 2 in 2D Fractal Brownian Motion. 
 * https://www.shadertoy.com/view/4dS3Wd
 *
 * By Morgan McGuire @morgan3d, http://graphicscodex.com
 * Reuse permitted under the BSD license: https://opensource.org/licenses/BSD-3-Clause
 *
 * And modified by Rinrin.rs
 */
float fbm12(vec2 x, int octaves, float frame) {
	float v = 0.;
	float amplitude = .5;
    float speed = .05;
	for (int i = 0; i < octaves; ++i) {
		v += amplitude*noise12(x);
		x *= 2.;
        x.xy -= frame*speed*float(i +1);
		amplitude *= .5;
	}
	return v;
}

/**
 * Array and textureless GLSL 2D simplex noise function.
 * https://github.com/ashima/webgl-noise/blob/master/src/noise2D.glsl
 *
 * Copyright (c) 2011 Ashima Arts.
 * Distributed under the MIT License: https://github.com/ashima/webgl-noise/blob/master/LICENSE
 */
vec3 mod289(vec3 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec2 mod289(vec2 x) {return x - floor(x * (1.0 / 289.0)) * 289.0;}
vec3 permute(vec3 x) {return mod289(((x*34.0)+10.0)*x);}
float snoise(vec2 v) {
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                        -0.577350269189626,  // -1.0 + 2.0 * C.x
                        0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
        + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

/** Whether the color is colorless. */
bool is_colorless(const vec3 color) {
    return color.r == color.g && color.g == color.b;
}

/**
 * Straightstep function.
 * As Smoothstep, but not hermite interpolation. 
 */
vec3 sstep(float edge0, float edge1, vec3 x) {
    x = clamp(x, edge0, edge1);
    return (x -edge0)/(edge1 -edge0)*1.;
}

float fogify(const float x, const float w) {
    return w/(x*x +w);
}
