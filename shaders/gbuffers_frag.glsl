// Included by:
// - GBUFFERS_TERRAIN (gbuffers_terrain.fsh)
// - GBUFFERS_WATER (gbuffers_water.fsh)
// - GBUFFERS_ENTITIES (gbuffers_entities.fsh)
// - GBUFFERS_BLOCK (gbuffers_block.fsh)
// - GBUFFERS_HAND (gbuffers_hand.fsh)
// - GBUFFERS_HAND_WATER (gbuffers_hand_water.fsh)

#if defined(GBUFFERS_TERRAIN) || defined(GBUFFERS_WATER) || defined(GBUFFERS_BLOCK)
    #define BLOCK
#endif

uniform sampler2D texture;
uniform sampler2D shadowtex1, shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D depthtex1;
uniform float rainStrength;
uniform vec4 entityColor;

varying vec2 texcoord;
varying vec4 glcolor;
/**
 * The lightmap coordinates
 * x: block light level (from light source)
 * y: sunlight and moonlight level (not drop shadow)
 */
varying vec2 lmcoord;
varying vec3 sun_pos, moon_pos;
varying vec4 shadowPos;
/* Suface normal */
varying vec3 normal;
/* Sky light of Vanilla */
varying float sky_light;
varying float is_water;

#include "lib/utils/functions.glsl"
#include "lib/defs/properties.glsl"

const int shadowMapResolution = 4096; // [64 512 1024 2048 4096 8192 16384]
// Fix artifacts when colored shadows are enabled
const bool shadowcolor0Nearest = true;
const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;

// shaders.properties of shit would not these options load without this useless ifdefs :(
#ifdef ENABLE_WATER_WAVES
#endif
#ifdef ENABLE_WIND
#endif
#ifdef ENABLE_THE_END_SKY_IN_OVERWORLD
#endif

void main() {
    vec4 albedo = texture2D(texture, texcoord)*glcolor;
    albedo.rgb *= glcolor.a;

    // ▼ DB

    // float:is_day, float:is_night, is_twilight
    #include "lib/utils/time_elms.glsl"

    /* Whether the surface is blended.*/
    float is_blend = 
    #if defined(GBUFFERS_WATER) || defined(GBUFFERS_HAND_WATER)
        1.
    #else
        0.
    #endif
    ;

    // Whether the surface is terrain.
    float is_block = 
    #if defined(BLOCK)
        1.
    #else
        0.
    #endif
    ;

    // High precision light intensity
    // Calculated here because the accuracy decreases when calculating with a composite shader.
    // (block_light^8) * 2
    float light_intensity_highp = lmcoord.x*lmcoord.x*lmcoord.x*lmcoord.x*lmcoord.x*lmcoord.x*lmcoord.x*lmcoord.x*2.;

    // ▲ DB

    // ▼ Lightmap

    // Directional light map coordinates
    vec2 d_lmc = lmcoord;
    bool is_tinted_glass_shadow = false;
    if (lightdot_threshold < shadowPos.w) {

        // Sky level of sunny side
        float sunny_side_slc = lerp(31./32.*SHADOW_BRIGHTNESS, 31./32., sqrt(shadowPos.w));

        // Whether there is anything opaque.
        if (texture2D(shadowtex1, shadowPos.xy).r < shadowPos.z) {
            // Surface is not in direct sunlight and monlight so reduce light level.
            d_lmc = saturate(SHADOW_BRIGHTNESS*d_lmc -.09);

            d_lmc.y = lerp(d_lmc.y, sunny_side_slc, rainStrength);
        } else {
            // Surface is in direct sunlight and moonlight so increase light level between the camera and the sun.
            d_lmc.y = sunny_side_slc;

            // Reduce the level in areas where the block light is strong.
            d_lmc.y -= light_intensity_highp*.12;

            // Whether there is anything translucent between us and the sun.
            if (texture2D(shadowtex0, shadowPos.xy).r < shadowPos.z) {
                vec4 colored_shadow = texture2D(shadowcolor0, shadowPos.xy);
                vec3 absorted_light = 1. -abs(colored_shadow.rgb -1.)/1.5;
                absorted_light = lerp(
                    absorted_light,
                    (absorted_light +1)*.55,
                    light_intensity_highp
                );
                albedo.rgb *= lerp(absorted_light, vec3(1.), rainStrength);
                
                is_tinted_glass_shadow = colored_shadow.rgb == vec3(0.);
                albedo.rgb = is_tinted_glass_shadow ? vec3(0.) : albedo.rgb;
            }
        }
    }

    // ▲ Lightmap

    // Entity damage overlay
    #if defined(GBUFFERS_ENTITIES)
        albedo.rgb = lerp(albedo.rgb, entityColor.rgb, entityColor.a);
    #endif

    /* DRAWBUFFERS:045678 */
    // 0 = gcolor
    // 1 = gdepth
    // 2 = gnormal
    // 3 = composite
    // 4 = gaux1
    // 5 = gaux2
    // 6 = gaux3
    // 7 = gaux4
    // 8 = colortex8
    // 9 = colortex9
    // 10 = colortex10
    // 11 = colortex11
    // 12 = colortex12
    // 13 = colortex13
    // 14 = colortex14
    // 15 = colortex15
	gl_FragData[0] = albedo; // gcolor
    gl_FragData[1] = vec4(is_blend, is_water, light_intensity_highp, 1.); // gaux1
    gl_FragData[2] = vec4(d_lmc.y, is_block, sky_light, 1.); // gaux2
    gl_FragData[3] = vec4(normal, 1.); // gaux3
    gl_FragData[4] = vec4(lmcoord, shadowPos.w, 1.); // gaux4
    gl_FragData[5] = vec4(albedo.a, float(is_tinted_glass_shadow), 1., 1.); // colortex8
}