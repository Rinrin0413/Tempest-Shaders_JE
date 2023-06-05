# Shadow
- [shadow.glsl](./shaders/shadow.glsl)
- shadow.vsh
- shadow.fsh

# Deferred
- [deferred_pipeline.glsl](./shaders/deferred_pipeline.glsl)
- deferred.vsh
- deferred.fsh

# Gbuffers
<!-- Main VSH & FSH of the Gbuffers -->
- [gbuffers_vert.glsl](./shaders/gbuffers_vert.glsl)
- [gbuffers_frag.glsl](./shaders/gbuffers_frag.glsl)
<!-- General blocks -->
- gbuffers_terrain.vsh
- gbuffers_terrain.fsh
<!-- Translucent blocks -->
- gbuffers_water.vsh
- gbuffers_water.fsh
<!-- Entities -->
- gbuffers_entities.vsh
- gbuffers_entities.fsh
<!-- Block entities -->
- gbuffers_block.vsh
- gbuffers_block.fsh
<!-- Handheld objects -->
- gbuffers_hand.vsh
- gbuffers_hand.fsh
<!-- Translucent handheld objects -->
- gbuffers_hand_water.vsh
- gbuffers_hand_water.fsh
<!-- Particles -->
- gbuffers_textured.vsh
- gbuffers_textured.fsh
<!-- Luminous particles -->
- gbuffers_textured_lit.vsh
- gbuffers_textured_lit.fsh

# Composite
- [composite_pipeline.glsl](./shaders/composite_pipeline.glsl)
- composite.vsh
- composite.fsh

# Library
- [lib/wind.glsl](./shaders/lib/wind.glsl)
- [lib/godrays.glsl](./shaders/lib/godrays.glsl)
- [lib/fog.glsl](./shaders/lib/fog.glsl)
- [lib/utils/](#Utils) (directory)
- [lib/defs/](#Defines) (directory)

# Utils
- [lib/utils/functions.glsl](./shaders/lib/utils/functions.glsl)
- [lib/utils/consts.gls](./shaders/lib/utils/consts.glsl)
- [lib/utils/colors.glsl](./shaders/lib/utils/colors.glsl)
- [lib/utils/time_elms.glsl](./shaders/lib/utils/time_elms.glsl)

# Defines
- [lib/defs/properties.glsl](./shaders/lib/defs/properties.glsl)
- [lib/defs/col.glsl](./shaders/lib/defs/col.glsl)
- [lib/defs/sun_moon_col.gls](./shaders/lib/defs/sun_moon_col.glsl)
- [lib/defs/distort.glsl](./shaders/lib/defs/distort.glsl)
- [lib/defs/stars_col.gls](./shaders/lib/defs/stars_col.glsl)
- [lib/defs/env_light_col.glsl](./shaders/lib/defs/env_light_col.glsl)

# Others
- [shaders.properties](./shaders/shaders.properties)
- [block.properties](./shaders/block.properties)