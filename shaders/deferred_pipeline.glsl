// Included by:
// - VSH (deferred.vsh)
// - FSH (deferred.fsh)

varying vec2 texcoord;

// Vertex shaders
#if defined(VSH)
    void main() {
        texcoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;

        gl_Position = ftransform();
    }
#endif

// Fragment shaders
#if defined(FSH)
    uniform sampler2D gcolor;
    uniform sampler2D depthtex0;
    uniform sampler2D noisetex;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferModelView, gbufferModelViewInverse;
    uniform float viewWidth, viewHeight;
    uniform float rainStrength;
    uniform vec3 sunPosition, moonPosition;
    uniform float frameTimeCounter;
    uniform int moonPhase; // 0 ~ 7

    #include "lib/utils/functions.glsl"
    #include "lib/defs/col.glsl"
    #include "lib/utils/consts.glsl"
    #include "lib/defs/stars_col.glsl"
    #include "lib/defs/sun_moon_col.glsl"
    #include "lib/defs/properties.glsl"

    /**
     * 2D Fractal Brownian Motion for the moon texture.
     * 
     * Based on:
     * https://www.shadertoy.com/view/4dS3Wd
     *
     * By Morgan McGuire @morgan3d, http://graphicscodex.com
     * Reuse permitted under the BSD license: https://opensource.org/licenses/BSD-3-Clause
     *
     * And modified by Rinrin.rs
     */
    float fbm12_moon(vec2 x) {
        float v = 0.;
        float amplitude = .5;
        for (int i = 0; i < 8; ++i) {
            v += amplitude*texture2D(noisetex, x).r;
            x *= 2.;
            amplitude *= .5;
        }
        return v;
    }

    vec3 draw_moon(vec3 sky, vec3 rel_pos, vec3 moon_pos, vec3 sky_color) {
        #define IMPORT_MOON_COL
        // vec3:moon_col
        #include "lib/utils/colors.glsl"

        #ifdef ENABLE_MOON_TEXTURE
            vec2 noise_st = rel_pos.xz/((rel_pos.y +1.)/2.);
            float sea = fbm12_moon(noise_st/2.)*.65;
            float craters = saturate(fbm12_moon(noise_st))*.6;
            moon_col.main = moon_col.main -sea +craters;
        #endif
        
        float scale = .15;
        vec3 moon_rel_pos = cross(rel_pos.xyz, moon_pos);
        float moon_depth = sqrt(
            scale*scale 
                -moon_rel_pos.x*moon_rel_pos.x 
                -moon_rel_pos.y*moon_rel_pos.y 
                -moon_rel_pos.z*moon_rel_pos.z
        );
        vec3 moon_n = normalize(vec3(moon_rel_pos.yx, moon_depth));

        float phase = float(moonPhase)*PI*.25;

        // Relative position of the light to the moon
        vec3 light = vec3(sin(phase), -.2, -cos(phase));

        float lightmap = smoothstep(0., .5, saturate(dot(moon_n, light)));

        float shade_brightness = .014;

        sky = saturate(moon_depth) <= 0. ? sky : lerp(sky_color, lerp(
            sky_color,
            moon_col.main, 
            shade_brightness +lightmap*(1. -shade_brightness)
        ), smoothstep(0., .06, moon_depth));
        
        return sky;
    }

    const int noiseTextureResolution = 32;

    void main() {
        vec3 albedo = texture2D(gcolor, texcoord).rgb;

        float depth0 = texture2D(depthtex0, texcoord).x;

        // Whether is sky
        if (1. <= depth0) {
            /* Relative position */
            vec4 rel_pos = gbufferProjectionInverse*vec4(vec3(texcoord, depth0)*2. -1., 1.);
            rel_pos = gbufferModelViewInverse*(rel_pos/rel_pos.w);
            rel_pos = normalize(rel_pos/rel_pos.w);

            #if defined(END_SHADERS) || defined(ENABLE_THE_END_SKY_IN_OVERWORLD)
                // The end door:
                float opening_speed = frameTimeCounter/16.;
                vec3 noise = texture2D(noisetex, rel_pos.yy +opening_speed).rgb;

                vec3 noisy_base_col = vec3(
                #if THE_END_SKY_COL == 0 // Purple
                    noise.r, 0., noise.r
                #elif THE_END_SKY_COL == 1 // Red
                    noise.r, 0., 0.
                #elif THE_END_SKY_COL == 2 // Green
                    0., noise.r, 0.
                #elif THE_END_SKY_COL == 3 // Blue
                    0., 0., noise.r
                #elif THE_END_SKY_COL == 4 // Colorful
                    noise.rgb*2. -.75
                #elif THE_END_SKY_COL == 5 // Monochrome
                    noise.r, noise.r, noise.r
                #endif
                );

                albedo = 
                #if THE_END_SKY_COL == 4
                    noisy_base_col
                #else
                    .85 < noise.g ? vec3(0.) : noise.g < .15 ? vec3(1.) : noisy_base_col
                #endif
                ;

                albedo = .97 < length(rel_pos.y) ? vec3(0.) : albedo;
            #else
                // The sky of the overworld
                
                // ▼ DB

                vec3 sun_pos = normalize(mat3(gbufferModelViewInverse)*sunPosition);
                vec3 moon_pos = normalize(mat3(gbufferModelViewInverse)*moonPosition);

                // float:is_day, float:is_night, is_twilight
                #include "lib/utils/time_elms.glsl"

                #define IMPORT_STARS_COL
                #define IMPORT_SKY_COL
                #define IMPORT_SUN_COL
                #define IMPORT_CLOUD_COL
                #define IMPORT_FOG_COL
                // vec3:sky_color, vec3:stars_col, vec3:sun_col, vec3:cloud_color, vec3:fog_color 
                #include "lib/utils/colors.glsl"

                vec4 view_pos = gbufferProjectionInverse
                    *vec4(gl_FragCoord.xy/vec2(viewWidth, viewHeight)*2. -1., 1., 1.);

                // ▲ DB

                vec3 sky = sky_color;

                // ▼ Stars

                #ifdef ENABLE_STARS
                    float opacity = lerp(.8, 0., rainStrength);

                    float smallness = 224.;
                    float star = smoothstep(.997, 1., hash13(floor((rel_pos.xyz)*smallness)));

                    vec3 stars_color;

                    #if STARS_COL == 0 // Colorful
                        stars_color = (texture2D(noisetex, rel_pos.xz/(rel_pos.y +1.)).rgb +1.)*.83;
                    #elif STARS_COL == 1 // White
                        stars_color = stars_col.white;
                    #elif STARS_COL == 2 // Blue
                        stars_color = stars_col.blue;
                    #elif STARS_COL == 3 // Yellow
                        stars_color = stars_col.yellow;
                    #endif

                    stars_color *= opacity;

                    sky = lerp(
                        sky,
                        stars_color,
                        lerp(0., star, smoothstep(0., .1, is_night))
                    );
                #endif

                // ▲ Stars

                // ▼ Sun
                
                float sun_d = distance(rel_pos.xyz, sun_pos);


                sky = lerp(
                    sun_col.sunlight,
                    sky,
                    smoothstep(-.3, 1., saturate(sun_d))
                );

                sky = lerp(
                    sun_col.secondary,
                    sky,
                    smoothstep(-1.3, 1., saturate(sun_d*4.))
                );

                sky = lerp(
                    sun_col.primary,
                    sky,
                    smoothstep(.6, 1., saturate(sun_d*7.))
                );

                sky = saturate(sky);

                float sunlight = (1. -smoothstep(-2., 1., saturate(sun_d*1.3)))/2.;

                // Here side is the SUN'S side so bye bye moon.
                float here_side_is_sun = 1.- smoothstep(.9, 1., distance(rel_pos.xyz, sun_pos));

                // ▲ Sun

                // ▼ Moon

                sky = here_side_is_sun < .5 ? draw_moon(sky, rel_pos.xyz, moon_pos, sky_color) : sky;

                float moonlight = 1. -smoothstep(-2., 1., saturate(distance(rel_pos.xyz, moon_pos)));

                sky = lerp(
                    sky,
                    moon_col.moonlight,
                    moonlight*.8
                );

                // ▲ Moon

                // ▼ Clouds 

                float sky_dot = max(0., dot(normalize(view_pos.xyz), gbufferModelView[1].xyz));

                #ifdef ENABLE_CLOUDS
                    // 2D pos
                    vec2 p = rel_pos.xz/(rel_pos.y +lerp(2.5, 5.5, rel_pos.y));

                    // Base cloud
                    float cloud = fbm12(
                        sin(p)*10., // Seed
                        16, // Octaves
                        frameTimeCounter
                    );

                    cloud -= fogify(sky_dot, .0001);

                    #if 1 <= CLOUDS_QUALITY
                        // Cloud shadow I
                        if (0. < cloud) {
                            float cloud_shadow = fbm12(
                                sin(p)*9.5, // Seed
                                8, // Octaves
                                frameTimeCounter
                            );
                            cloud_color *= lerp(1., .63, smoothstep(.54, .88, cloud_shadow));
                        }

                        #if CLOUDS_QUALITY <= 2
                            // Cloud shadow II
                            if (.7 < cloud) {
                                float cloud_shadow = fbm12(
                                    sin(p)*9., // Seed
                                    4, // Octaves
                                    frameTimeCounter
                                );
                                cloud_color *= lerp(1., .9, smoothstep(.6, .99, cloud_shadow));
                            }
                        #endif
                    #endif

                    cloud_color *= lerp(1., lerp(6., 2., rainStrength), moonlight*2.);

                    // Clouds will be deeper when it is raining.
                    float lower = lerp(.5, -.2, rainStrength);

                    sky = lerp(sky, cloud_color, smoothstep(lower, .68, cloud -sunlight));
                #endif

                // ▲ Clouds

                // Apply sky
                albedo = lerp(
                    sky, 
                    fog_color, 
                    fogify(
                        sky_dot, 
                        lerp(.06, .4, rainStrength)
                    ) -sunlight*lerp(2., 8., is_twilight)
                );
                
            #endif
        }

        /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo, 1.); // gcolor
    }
#endif
