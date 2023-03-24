// Properties definitions
//
// # Add the following to use:
// #include "lib/defs/properties.glsl"

#define SHADOW_BIAS 0.0050 // [0.0010 0.0025 0.0050 0.0100 0.0150 0.0200 0.0250 0.0300 0.0400 0.050]

#define SHADOW_BRIGHTNESS .75

#define SHADOW_DISTORT_FACTOR .1

const float lightdot_threshold = 
#if defined(GBUFFERS_BLOCK) || defined(GBUFFERS_ENTITIES)
    .05
#else
    .083
#endif
;

#define ENABLE_FOG

#define ENABLE_WATER_WAVES

#define ENABLE_WIND

const float sunPathRotation = -40; // [-90 -80 -70 -60 -50 -40 -30 -20 -10 0 10 20 30 40 50 60 70 80 90]

#define ENABLE_STARS

#define STARS_COL 0 // [0 1 2 3]

#define CLOUDS_QUALITY 2 // [0 1 2]

#define ENABLE_CLOUDS

#define ENABLE_MOON_TEXTURE

#define THE_END_SKY_COL 0 // [0 1 2 3 4 5]

#define ENABLE_GODRAYS

// #define ENABLE_THE_END_SKY_IN_OVERWORLD
