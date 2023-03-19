// Struct `SunCol`, `MoonCol` definitions
//
// # Add the following to use:
// #include "lib/defs/sun_moon_col.glsl"

struct SunCol {
    vec3 primary;
    vec3 secondary;
    vec3 sunlight;
};

struct MoonCol {
    vec3 main;
    vec3 shade;
    vec3 moonlight;
};
