// Struct `LightCol`, `EnvCol` definitions
//
// # Add the following to use:
// #include "lib/defs/env_light_col.glsl"

struct LightCol {
    vec3 primary;
    vec3 rain;
    vec3 underwater;
    vec3 deep_underwater;
};

struct EnvCol {
    vec3 day;
    vec3 night;
    vec3 twilight;
};