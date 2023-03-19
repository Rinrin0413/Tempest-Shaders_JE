// Struct `Col` and utility function `get_col` definitions
//
// # Add the following to use:
// #include "lib/defs/col.glsl"
//
// # Dependencies:
// - `#include "lib/utils/functions.glsl"`
// - `uniform float rainStrength;`

struct Col {
    vec3 day;
    vec3 night;
    vec3 twilight;
    vec3 rain;
};

/* for struct `Col` */
vec3 get_col(const Col col, const float is_day, const float is_twilight) {
    return lerp( // is Rain
        lerp( // is Twilight
            lerp( // is Day
                col.night,
                col.day, 
                smoothstep(0., .3, is_day)
            ),
            col.twilight, 
            is_twilight
        ), 
        col.rain, 
        rainStrength
    );
}
