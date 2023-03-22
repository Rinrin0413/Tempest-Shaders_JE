// Included by:
// - VSH (composite.vsh)
// - FSH (composite.fsh)

varying vec2 texcoord;
varying vec3 sun_pos, moon_pos;
uniform mat4 gbufferModelViewInverse;

// Vertex shaders
#if defined(VSH)
    uniform vec3 sunPosition, moonPosition;

    void main() {
        sun_pos = normalize(mat3(gbufferModelViewInverse)*sunPosition);
        moon_pos = normalize(mat3(gbufferModelViewInverse)*moonPosition);
        texcoord = (gl_TextureMatrix[0]*gl_MultiTexCoord0).xy;

        gl_Position = ftransform();
    }
#endif

// Fragment shaders
#if defined(FSH)
    uniform sampler2D gcolor;
    uniform sampler2D depthtex0, depthtex1;
    uniform sampler2D gaux1; // s = is_blend, t = is_water, p = light_intensity_highp
    uniform sampler2D gaux2; // s = d_lmc.y, t = is_block, p = sky_light
    uniform sampler2D gaux3; // stp = normal.xyz
    uniform sampler2D gaux4; // st = lmcoord.xy, p = shadowPos.w
    uniform sampler2D colortex8; // s = opacity, t = is_tinted_glass_shadow
    uniform sampler2D shadowtex0, shadowtex1;
    uniform sampler2D shadowcolor0;
    uniform mat4 gbufferProjectionInverse;
    uniform mat4 gbufferModelView;
    uniform float near, far;
    uniform float rainStrength;
    uniform float darknessFactor;
    uniform int isEyeInWater;
    uniform float viewWidth, viewHeight;

    #include "lib/utils/functions.glsl"
    #include "lib/defs/properties.glsl"
    #include "lib/defs/col.glsl"

    vec3 apply_shadow(vec3 albedo, const float shadow_level) {

        // Old shadow color (for BE)
        vec3 shadow_col1 = albedo*lerp(
            luma(albedo)*1.7,
            1.,
            smoothstep(.5, 1., shadow_level)
        );

        // New shadow color (for JE)
        vec3 shadow_col2 = lerp(
            saturate(chroma(albedo, .36)/5.),
            albedo,
            smoothstep(.5, 1., shadow_level)
        );

        float sky_light = texture2D(gaux2, texcoord).z;
        float is_night = max(0., sin(moon_pos.y));

        // Mix shadow colors
        return lerp(
            shadow_col1, 
            shadow_col2, 
            lerp(0., lerp(.89, .67, is_night), sky_light)
        );
    }

    float extreme_depth(const float d, const float fog) {
        // return pow(d, 2046.);
        return d <= 0. ? 0. :
            smoothstep(0., .85, smoothstep(0., lerp(2046.*(far/320.)*lerp(1., .2, rainStrength), 1.,  d), d));
    }

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

    void main() {

        vec3 albedo = texture2D(gcolor, texcoord).rgb;

        if (texture2D(depthtex0, texcoord).x < 1.) {
            // Environment colors
            EnvCol env_col = EnvCol(
                vec3(0.91, 0.94, 1.0)*1.6, // Day env. color
                vec3(0.68, 0.75, 1.0)*1.6, // Night env. color
                vec3(1.00, 0.48, 0.0)      // Dawn and Dusk env. color
            );

            // ▼ DB

            // float:is_day, float:is_night, is_twilight
            #include "lib/utils/time_elms.glsl"

            vec3 d_gaux1 = texture2D(gaux1, texcoord).stp;
            vec3 d_gaux2 = texture2D(gaux2, texcoord).stp;
            vec3 d_gaux3 = texture2D(gaux3, texcoord).stp;
            vec3 d_gaux4 = texture2D(gaux4, texcoord).stp;
            vec3 d_colortex8 = texture2D(colortex8, texcoord).stp;

            /**
            * Whether is BLEND 
            * Use it like:
            * if (.5 < is_blend) {
            */
            float is_blend = d_gaux1.x;

            /* Whether the surface is in water */
            float is_water = 0. < d_gaux1.y ? 1. : 0.;
            is_water = lerp(is_water, abs(is_water -1.), isEyeInWater);

            /**
            * The lightmap coordinates
            * x: block light level (from light source)
            * y: sunlight and moonlight level (not drop shadow)
            */
            vec2 lmc = d_gaux4.xy;

            /* The Directional Sky Light Coordinates */
            float d_slc = d_gaux2.x;

            /* Whether is block */
            float is_block = d_gaux2.y;

            /* The sky light level of Vanilla */
            float sky_light = d_gaux2.z;

            /* High precision light intensity */
            float light_intensity_highp = d_gaux1.z;

            /* The surface normal */
            vec3 normal = d_gaux3;

            /* Whether the surface is facing towards the sun. */
            float light_dot = d_gaux4.z;

            /* Opacity */
            float opacity = d_colortex8.x;

            /* Whether the surface is tinted glass shadow */
            float is_tinted_glass_shadow = d_colortex8.y;

            /**
            * Whether the surface is top;
            * between 0 and 1. if the surface is top completely, it is 1.
            */
            float is_top = saturate(normal.y);

            float depth0 = texture2D(depthtex0, texcoord).x;
            float depth1 = texture2D(depthtex1, texcoord).x;
            
            // ▲ DB

            // ▼ Lightmap

            // Lightings

            // Light colors
            LightCol light_col = LightCol(
                vec3(1.00, 0.88, 0.44),     // Primary light color
                vec3(0.83, 1.00, 0.88)*2.0, // Rain light color
                vec3(0.10, 1.00, 0.70)*2.1, // Underwater light color
                vec3(0.30, 0.50, 1.00)*1.8  // Deep underwater color
            );
            vec3 light_color = lerp(light_col.primary, light_col.rain, rainStrength)*5.;
            vec3 light_color_underwater = lerp(light_col.deep_underwater,  light_col.underwater, lmc.y)*5.;

            float suppress = lerp(
                0. < is_night ? 1. : lerp(1., .27, sky_light), 
                lerp(
                    2.8, 
                    0. < is_night ? .6 : .24,
                    sky_light
                ), 
                rainStrength
            );
            float light_intensity = .5 < is_block ? 
                // [Note] (block_light^8) * 2 * suppress
                light_intensity_highp*suppress :
                // [Note] smoothstep(-0.2, 1.2, block_light^2 -0.2)
                smoothstep(-.2, 1.2, lmc.x*lmc.x*suppress -.2);

            // Apply lightmaps

            if (lmc.y <= .5) {
                d_slc = lerp(
                    smoothstep(-1., 1., lmc.y +.5) -.625,
                    sky_light,
                    rainStrength
                );

                // Interference of light in shadows
                d_slc = lerp(
                    d_slc, 
                    saturate(d_slc +.5), 
                    light_intensity
                );

                albedo = apply_shadow(albedo, d_slc);
                albedo = lerp(
                    saturate(chroma(albedo, .2)/5.),
                    albedo,
                    smoothstep(.2, .35, d_slc)
                );
            } else {
                // Interference of light in shadows
                d_slc = lerp(
                    d_slc, 
                    saturate(d_slc +.1), 
                    light_intensity
                );

                // Suppression of directional shadows in rainy weather.
                d_slc = lerp(d_slc, sky_light, saturate(rainStrength -.3));

                albedo = apply_shadow(albedo, d_slc);

                // Height of the sun or moon.
                float sm_h = max(sun_pos.y, moon_pos.y);

                // Whether the sun or moon is shallow angle.
                // 0 between 1 (90° ~ 0°)
                float is_shallow_sm = saturate(smoothstep(0., .5, sm_h)*2.);

                // Side illuminated by the sun or moon.
                float sunny_side = 0 < is_day ? normal.x*sun_pos.x +normal.z*sun_pos.z : normal.x*moon_pos.x +normal.z*moon_pos.z;
                
                // Not env_col.day
                vec3 sunny_side_col = vec3(1.0, 1.0, 0.5)*1.7;

                // Illuminate the sunny SIDE.
                albedo *= lerp(vec3(1.),
                    lerp(
                        env_col.night*1.5, 
                        sunny_side_col, 
                        is_day
                    ),
                    saturate(lerp(0., lerp(sunny_side, 0, rainStrength), is_shallow_sm))
                );
            }

            albedo *= lerp(
                vec3(1.), 
                lerp(light_color, light_color_underwater, is_water), 
                light_intensity//*lerp(4., 1., d_slc)
            );

            // ▲ Lightmap
            
            // ▼ Environment

            // The night is dark
            albedo /= lerp(
                1.,
                lerp(7., 3., light_dot),
                is_night
            );

            // The indoor day is dark
            albedo /= lerp(
                1.,
                lerp(lerp(7., 3., light_dot), 1., lmc.y),
                is_day
            );

            // for Day and Night
            albedo *= lerp(
                env_col.night,
                env_col.day,
                is_day
            );

            // for Dawn and Dusk
            float twilight_level = saturate(
                // Side facing the sun
                normal.x*sun_pos.x

                // and Top surface (but disable if shadows of top surface does not exist)
                +saturate(lightdot_threshold < light_dot ? is_top : 0.)

                // Subtract in shadow
                -min(abs(saturate(d_slc +.23) -1.)*16., .8)
            );
            vec3 twilight_col = env_col.twilight*lerp(.125, .5, twilight_level);
            albedo = lerp(albedo,
                lerp(albedo,
                    lerp(
                        albedo +twilight_col,
                        albedo/2.,
                        rainStrength
                    ),
                    is_twilight
                ),
                lmc.y
            );

            // for Rain (in rain && is day && in sunshine)
            albedo /= vec3(lerp(1.,
                lerp(1., 
                    lerp(1., 
                        6., 
                        saturate(sky_light*4.)
                    ), 
                    is_day
                ),
                rainStrength
            ));

            // ~~Gamma correction (1/2.2 = 0.45..)~~ not like this
            //albedo = pow(albedo, vec3(.455));

            // Luma correction
            albedo *= lerp(1., luma(albedo)*2., .3);

            // ACES Filmic Tone Mapping
            albedo = lerp(
                albedo,
                ACESFilm(
                    albedo*lerp(1., .7, is_day)
                ),
                lerp(.75, 1., saturate(is_day +.5))
            );

            // ▲ Environment

            // ▼ Fog
            #ifdef ENABLE_FOG
                #define IMPORT_FOG_COL
                #define IMPORT_SKY_COL
                // vec3:fog_color, vec3:sky_color
                #include "lib/utils/colors.glsl"
                
                vec4 view_pos = gbufferProjectionInverse*(vec4(texcoord, texture2D(depthtex0, texcoord).r, 1.)*2. -1.);

                fog_color = lerp(
                    sky_color,
                    fog_color,
                    fogify(max(0., dot(normalize(view_pos.xyz), gbufferModelView[1].xyz)), lerp(.06, .4, rainStrength))
                );

                vec4 rel_pos = gbufferModelViewInverse*(view_pos/view_pos.w);
                float dist = length(rel_pos/rel_pos.w);
                float fog = saturate(smoothstep(
                    0., 
                    lerp(.76, .2, rainStrength), 
                    (dist -near)/(far -near)
                ));
                fog *= lerp(1., 1.8, is_blend);

                float fog_behind_blend = depth1 < 1. ? 
                    lerp(extreme_depth(depth1, fog) -extreme_depth(depth0, fog), 0., opacity): 
                    0.;

                albedo = lerp(albedo, fog_color, saturate(fog +fog_behind_blend));
            #endif
            // ▲ Fog

            // Darkness effect
            albedo -= lerp(0., .5, darknessFactor);

            // Again LIGHT ABSORPTION
            albedo = .5 < is_tinted_glass_shadow ? vec3(0.) : albedo;

            // albedo = vec3(light_dot);
        }

        /* DRAWBUFFERS:0 */
        gl_FragData[0] = vec4(albedo, 1.); // gcolor
    }
#endif
