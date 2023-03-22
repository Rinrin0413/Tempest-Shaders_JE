// Included by:
// - GBUFFERS_TERRAIN (gbuffers_terrain.vsh)
// - GBUFFERS_WATER (gbuffers_water.vsh)
// - GBUFFERS_ENTITIES (gbuffers_entities.vsh)
// - GBUFFERS_BLOCK (gbuffers_block.vsh)
// - GBUFFERS_HAND (gbuffers_hand.vsh)
// - GBUFFERS_HAND_WATER (gbuffers_hand_water.vsh)

#if defined(GBUFFERS_TERRAIN) || defined(GBUFFERS_WATER) || defined(GBUFFERS_BLOCK)
    #define BLOCK
#endif

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition, moonPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying vec4 shadowPos;
varying vec3 normal;
varying float sky_light;
varying vec3 sun_pos, moon_pos;
varying vec2 uv1;
varying float is_water;

#include "lib/defs/properties.glsl"
#include "lib/defs/distort.glsl"
#include "lib/utils/functions.glsl"

void main() {
    vec4 rel_pos = vec4((gbufferModelViewInverse*gl_ModelViewMatrix*gl_Vertex).xyz, 1.);
    vec3 abs_pos = rel_pos.xyz +cameraPosition;

    glcolor = gl_Color;
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    sun_pos = normalize(mat3(gbufferModelViewInverse)*sunPosition);
    moon_pos = normalize(mat3(gbufferModelViewInverse)*moonPosition);
    sky_light = lmcoord.y;
    uv1 = (gl_TextureMatrix[1]*gl_MultiTexCoord1).xy;
    normal = mat3(gbufferModelViewInverse)*normalize(gl_NormalMatrix*gl_Normal);

    int b_id = int(mc_Entity.x);

    // ▼ Waving foliage and lanterns etc.
    #if defined(ENABLE_WIND) && (defined(GBUFFERS_TERRAIN) || defined(GBUFFERS_WATER))
        #include "lib/wind.glsl"
    #endif
    // ▲ Waving foliage lanterns etc.

    // ▼ Directional sun light

    float lightDot = dot(normalize(shadowLightPosition), normalize(gl_NormalMatrix*gl_Normal));
    
    // Whether the vertex is facing towards the sun.
    if (lightdot_threshold < lightDot) {
        // Convert to shadow screen space.
        shadowPos = shadowProjection*(shadowModelView*rel_pos);
        float distortFactor = distort_factor(shadowPos.xy);
        // Apply shadow distortion.
        shadowPos.xyz = distort313(shadowPos.xyz, distortFactor);
        // Convert from -1 ~ +1 to 0 ~ 1
        shadowPos.xyz = shadowPos.xyz*.5 +.5;
        // Apply shadow bias.
        shadowPos.z -= SHADOW_BIAS*(distortFactor*distortFactor)/abs(lightDot);
    } else {
        // Here is the side cannot be seen from the sun!
        lmcoord.y *= SHADOW_BRIGHTNESS;
        shadowPos = vec4(0.); 
    }

    shadowPos.w = lightDot;

    // ▲ Directional sun light

    gl_Position = gl_ProjectionMatrix*(gbufferModelView*rel_pos);
}