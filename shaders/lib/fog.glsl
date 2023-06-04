// Draws the fog
//
// # Add the following to use:
// #include "lib/fog.glsl"
//
// # Required:
// - underground_fog_color
// - sky_color
// - fog_color
// - `#include "lib/utils/functions.glsl"`
// - view_pos
// - `uniform mat4 gbufferModelView;`
// - `uniform float rainStrength;`
// - `uniform ivec2 eyeBrightnessSmooth;`
// - albedo
// - rel_pos
// - `uniform float near, far;`

fog_color = lerp(
    underground_fog_color,
    lerp(
        sky_color,
        fog_color,
        fogify(max(0., dot(normalize(view_pos.xyz), gbufferModelView[1].xyz)), lerp(.06, .4, rainStrength))
    ),
    // 0.00416666666 = 1/240
    // use saturate() because it is low precision
    saturate(float(eyeBrightnessSmooth.y)*.004167)
);

float fog_factor = smoothstep(
    lerp(.45, 0., rainStrength), 
    lerp(.83, 1., rainStrength), 
    (length(rel_pos*.8) -near)/(far -near)
);

albedo = lerp(albedo, fog_color, fog_factor);