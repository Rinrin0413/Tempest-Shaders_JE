// Draws the godrays effect
//
// # Add the following to use:
// #include "lib/godrays.glsl"
//
// # Required:
// - `#include "lib/defs/col.glsl"`
// - `#include "lib/utils/functions.glsl"`
// - `uniform float rainStrength;`
// - `#include "lib/utils/time_elms.glsl"`
// -  rel_pos
// - `uniform float frameTimeCounter;`
// - `uniform mat4 gbufferModelViewInverse`
// - `uniform mat4 shadowProjection;`
// - `uniform mat4 shadowModelView;`
// - `#include "lib/defs/distort.glsl"`
// - `uniform sampler2D shadowtex0;`
// - sky_rel_pos
// - sun_pos
// - moon_pos
// - albedo

#define IMPORT_GODRAYS_COL
// vec3:godrays_color
#include "./utils/colors.glsl"

// Don't exceed 1.0
float q = lerp(0.8, 0.6, is_twilight);

vec3 ray_rel_pos = rel_pos.xyz*lerp(1., 1./q, hash12(gl_FragCoord.xy +frameTimeCounter));
float ray_factor = 0.;

// 0.0625 = 0.25^2
while (.0625 < dot(ray_rel_pos, ray_rel_pos)) {
    ray_rel_pos *= q;
    vec4 ray_pos = vec4(ray_rel_pos + gbufferModelViewInverse[3].xyz, 1.);
    ray_pos = shadowProjection*(shadowModelView*ray_pos);
    ray_pos.xyz = distort33(ray_pos.xyz)*.5 +.5;

    ray_factor = lerp(
        ray_pos.z < texture2D(shadowtex0, ray_pos.xy).r ? 1. : 0., 
        ray_factor, 
        exp2(length(ray_rel_pos)*-.0625)
    );
}

ray_factor = min(
    ray_factor
        *max(0., 1. -distance(sky_rel_pos.xyz, 0. < is_day ? sun_pos : moon_pos))
        *(0. < is_day ? 1.: is_night),
    1.
);

albedo = lerp(
    albedo, 
    godrays_color, 
    ray_factor
);
