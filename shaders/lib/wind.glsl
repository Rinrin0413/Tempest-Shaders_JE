// Calculate and apply the wind.
//
// # Add the following to use:
// #include "lib/wind.glsl"
//
// # Required:
// - b_id
// - abs_pos
// - `uniform float frameTimeCounter;`
// - `#include "lib/utils/functions.glsl"`
// - lmcoord
// - `attribute vec4 mc_midTexCoord;`

bool is_hanged = b_id == 10004;
bool is_blown = b_id == 10002 || b_id == 10003 || is_hanged;

if (is_hanged) {
    // Note: Here, implement the lantern swing,
    //       but this implementation is very simple and pseudo.
    //       So swings while the top and bottom  surface are horizontal.

    // Block coordinate based pseudo noise
    float bbpn = float(int(abs_pos.x))*float(int(abs_pos.y));

    // Swing offsets
    vec3 swing = vec3(sin(
        frameTimeCounter +bbpn
    )/10.);

    // Pseudo axis implemented by suppressing movement near the origin.
    // abs_pos.y was subtracted by 0.01 because the chain will be fucking buggg.
    swing *= lerp(1., 0., fract(abs_pos.y -.01));

    // Randomize the swing offsets.
    swing.x *= (hash11(bbpn) -.5)*2.;
    swing.z *= (hash11(bbpn*16.) -.5)*2.;

    // Height adjustment according to the swing offsets.
    swing.y = smoothstep(0., .8, abs(swing.x/2.) +abs(swing.z/2.));

    rel_pos.xyz += swing;
    
} else if (is_blown) {
    float wave = cos(
        abs_pos.x*1.13 
        +abs_pos.y*.84
        +abs_pos.z*.9
        +frameTimeCounter*2.1
    )*.05*lerp(.15, 1., lmcoord.y);

    bool is_rooted = b_id == 10003;
    wave *= is_rooted ? gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1. : 0. : 1.;

    rel_pos.x += wave*sin(abs_pos.x +abs_pos.z*abs_pos.y +frameTimeCounter*3.);
    rel_pos.z -= wave/2.7;
}
