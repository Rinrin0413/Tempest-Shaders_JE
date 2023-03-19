// Included by:
// - VSH (shadow.vsh)
// - FSH (shadow.fsh)

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 glcolor;
varying float is_tinted_glass, is_water;

#include "lib/utils/functions.glsl"

// Vertex shaders
#ifdef VSH
    attribute vec4 mc_Entity;
    attribute vec4 mc_midTexCoord;

    uniform vec3 cameraPosition;
    uniform float frameTimeCounter;
    uniform mat4 shadowProjection, shadowProjectionInverse;
    uniform mat4 shadowModelView, shadowModelViewInverse;

    #include "lib/defs/properties.glsl"
    #include "lib/defs/distort.glsl"

    void main() {
        vec4 rel_pos = shadowModelViewInverse*shadowProjectionInverse*ftransform();
        vec3 abs_pos = rel_pos.xyz +cameraPosition;

        glcolor = gl_Color;
        texcoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;
        lmcoord  = (gl_TextureMatrix[1]*gl_MultiTexCoord1).xy;

        int b_id = int(mc_Entity.x);
        is_tinted_glass = b_id == 10001 ? 1. : 0.;
        is_water = b_id == 10000 ? 1. : 0.;

        // Waving foliage and lanterns etc.
        #ifdef ENABLE_WIND
            #include "lib/wind.glsl"
        #endif

        gl_Position = vec4(distort33((shadowProjection*shadowModelView*rel_pos).xyz), 1.);
    }
#endif

// Fragment shaders
#ifdef FSH
    uniform sampler2D texture;

    void main() {
        vec4 albedo = texture2D(texture, texcoord)*glcolor;

        // Super absorption
        albedo = .5 < is_tinted_glass ? vec4(0.,0.,0.,.5) : albedo;

        // Water
        albedo.rgb = .5 < is_water ? chroma(albedo.rgb, 2.) +.37 : albedo.rgb;

        gl_FragData[0] = albedo;
    }
#endif