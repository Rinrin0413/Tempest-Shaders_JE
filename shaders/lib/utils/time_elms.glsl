// Provide elements for time detection.
//
// # Add the following to use:
// #include "lib/utils/time_elms.glsl"
//
// # Required:
// - sun_pos
// - moon_pos

/**
 * Whether it is daytime.
 * between 0 and 1. if the sun is set, it is 0.
 */
float is_day = max(0., sin(sun_pos.y));

/**
 * Whether it is nighttime.
 * between 0 and 1. if the moon is set, it is 0.
 */
float is_night = max(0., sin(moon_pos.y));

/**
 * Whether it is twilight.
 * between 0 and 1.
 */
float is_twilight = min(
    smoothstep(-.08, .05, is_day -is_night), 
    smoothstep(.314, .15, is_day)
);
