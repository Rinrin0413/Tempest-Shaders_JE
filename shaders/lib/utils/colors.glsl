// Global colors definitions
//
// # Add the following to use:
// #include "lib/utils/colors.glsl"

// Sky colors
#ifdef IMPORT_SKY_COL
    // # Dependencies:
    // - `#include "lib/defs/col.glsl"`
    // - `#include "lib/utils/functions.glsl"`
    // - `uniform float rainStrength;`
    // - `#include "lib/utils/time_elms.glsl"`

    Col sky_col = Col(
        vec3(0.20, 0.47, 0.74), // Day sky color
        vec3(0.00, 0.04, 0.11), // Night sky color
        vec3(0.13, 0.18, 0.18), // Dusk & Dawn sky color
        vec3(0.00, 0.00, 0.00)  // Rainy sky color
    );

    vec3 sky_color = get_col(sky_col, is_day, is_twilight);
#endif

// Star colors
#ifdef IMPORT_STARS_COL
    // # Dependencies:
    // - `#include "lib/defs/stars_col.glsl"`

    StarsCol stars_col = StarsCol(
        vec3(1.0, 1.00, 1.0), // White stars color
        vec3(0.6, 0.80, 1.0), // Blue stars color
        vec3(1.0, 0.93, 0.7) // Yellow stars color
    );
#endif

// Sun colors
#ifdef IMPORT_SUN_COL
    // # Dependencies:
    // - `#include "lib/defs/sun_moon_col.glsl"`
    // - `#include "lib/utils/functions.glsl"`

    SunCol sun_col = SunCol(
        vec3(1.0, 1.0, 1.0), // Primary sun color
        vec3(2.0, 1.4, 1.0), // Secondary sun color
        vec3(1.0, 1.0, 1.0)  // Sunlight color
    );

#endif

// Moon colors
#ifdef IMPORT_MOON_COL
    // # Dependencies:
    // - `#include "lib/defs/sun_moon_col.glsl"`
    // - `#include "lib/utils/functions.glsl"`

    MoonCol moon_col = MoonCol(
        vec3(0.75, 0.80, 1.00), // Moon main color
        vec3(0.00, 0.04, 0.11),// Moon shade color
        vec3(0.50, 0.70, 1.00)  // Moonlight color
    );
#endif

// Cloud colors
#ifdef IMPORT_CLOUD_COL
    // # Dependencies:
    // - `#include "lib/defs/col.glsl"`
    // - `#include "lib/utils/functions.glsl"`
    // - `uniform float rainStrength;`
    // - `#include "lib/utils/time_elms.glsl"`

    Col cloud_col = Col(
        vec3(0.80, 0.90, 1.00), // Day cloud color
        vec3(0.17, 0.26, 0.39), // Night cloud color
        vec3(0.46, 0.41, 0.37), // Twilight cloud color
        vec3(0.70, 0.70, 0.70)  // Rainy cloud color
    );

    vec3 cloud_color = get_col(cloud_col, is_day, is_twilight);
#endif

// Fog colors
#ifdef IMPORT_FOG_COL
    // # Dependencies:
    // - `#include "lib/defs/col.glsl"`
    // - `#include "lib/utils/functions.glsl"`
    // - `uniform float rainStrength;`
    // - `#include "lib/utils/time_elms.glsl"`

    const float eyeBrightnessHalflife = 2.0f;

    Col fog_col = Col(
        vec3(0.66, 0.84, 0.94), // Day fog color
        vec3(0.00, 0.05, 0.10), // Night fog color
        vec3(0.43, 0.16, 0.00), // Twilight fog color
        vec3(0.60, 0.70, 0.80)  // Rainy fog color
    );

    // Underground fog color
    vec3 underground_fog_color = vec3(0.25, 0.30, 0.35);

    vec3 fog_color = get_col(fog_col, is_day, is_twilight);
#endif

// Godrays colors
#ifdef IMPORT_GODRAYS_COL
    // # Dependencies:
    // - `#include "lib/defs/col.glsl"`
    // - `#include "lib/utils/functions.glsl"`
    // - `uniform float rainStrength;`
    // - `#include "lib/utils/time_elms.glsl"`

    Col godrays_col = Col(
        vec3(1.00, 0.90, 0.60), // Day godrays color
        vec3(0.72, 0.98, 1.20), // Night godrays color
        vec3(1.00, 0.40, 0.00), // Twilight godrays color
        vec3(0.60, 0.70, 0.80)  // Rainy godrays color
    );

    vec3 godrays_color = get_col(godrays_col, is_day, is_twilight);
#endif

// Environment colors
#ifdef IMPORT_ENV_COL
    // # Dependencies:
    // - `#include "lib/defs/env_light_col.glsl"`

    EnvCol env_col = EnvCol(
        vec3(1.46, 1.50, 1.6), // Day env. color
        vec3(1.09, 1.20, 1.6), // Night env. color
        vec3(1.00, 0.48, 0.0)  // Dawn and Dusk env. color
    );
#endif

// Block light colors
#ifdef IMPORT_LIGHT_COL
    // # Dependencies:
    // - `#include "lib/defs/env_light_col.glsl"`
    // - `#include "lib/utils/functions.glsl"`
    // - is_rain
    // - lmc

    LightCol light_col = LightCol(
        vec3(1.12, 0.88, 0.44), // Primary light color
        vec3(1.66, 2.00, 1.76), // Rain light color
        vec3(0.21, 2.10, 1.47), // Underwater light color
        vec3(0.54, 0.90, 1.80)  // Deep underwater color
    );

    vec3 light_color = lerp(light_col.primary, light_col.rain, is_rain)*5.;
    vec3 light_color_underwater = lerp(light_col.deep_underwater, light_col.underwater, lmc.y)*5.;
#endif
