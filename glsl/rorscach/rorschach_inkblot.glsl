/*
   Title: "Rorschach"
   Year: 2026
   Author: Alif Ramedhis
   Description:
      An endlessly shifting, mirrored Rorschach inkblot made of black
      ink on white paper that keeps morphing into new blots.
*/

#define TAU      6.28318530718
#define LOOP     15.0      // in seconds
#define VIGNETTE 0.40      // 0 - 0.8

// Noise:
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
    vec3 i = floor(x), f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(mix(hash(i),                 hash(i + vec3(1,0,0)), f.x),
                   mix(hash(i + vec3(0,1,0)),   hash(i + vec3(1,1,0)), f.x), f.y),
               mix(mix(hash(i + vec3(0,0,1)),   hash(i + vec3(1,0,1)), f.x),
                   mix(hash(i + vec3(0,1,1)),   hash(i + vec3(1,1,1)), f.x), f.y), f.z);
}

float lnoise(vec2 p, float a, float ph) {
    vec2 c = vec2(cos(a + ph), sin(a + ph)) * 1.9;
    return 0.5 * (vnoise(vec3(p,                   c.x + 5.0)) +
                  vnoise(vec3(p + vec2(13.7, 3.1), c.y + 9.0)));
}

float fbm(vec2 p, float a, int oct) {
    float s = 0.0, amp = 0.5;
    for (int i = 0; i < 4; i++) {
        if (i >= oct) break;
        s += amp * lnoise(p, a, float(i) * 1.7);
        p = p * 2.03 + vec2(1.7, 9.2);
        amp *= 0.5;
    }
    return s / (1.0 - pow(0.5, float(oct)));
}

// Inkblot:
// h > 0 inside the ink, h < 0 outside. p must already be mirrored (x >= 0).
float inkField(vec2 p, vec2 warp, float a) {
    // Strong domain warp (like spilled ink):
    vec2 q = p + warp * 1.4;

    float e = 1.0 - length(vec2(p.x * 0.72, p.y * 0.95));

    float n = fbm(q * 2.3, a, 3);
    float h = (n - 0.5) * 2.2 + e - 0.36;

    // Splatter:
    float sp   = lnoise(p * 6.5 + vec2(3.0, 7.0), a, 0.5);
    float gate = smoothstep(0.0, 0.3, 1.0 - length(vec2(p.x * 0.50, p.y * 0.75)));
    h = max(h, (sp - 0.72) * 3.0 * gate);

    h -= 0.18 * exp(-p.x * p.x * 500.0);
    vec2 d = p - vec2(0.0, 0.14);
    h -= 0.6 * exp(-50.0 * dot(d, d));
    return h;
}

// Black ink on white paper:
vec3 inkOnPaper(vec2 F, vec2 p, float h0, float mott) {
    // Paper-fixed coordinates (don't breathe with the blot):
    vec2 pu = (2.0 * F - iResolution.xy) / iResolution.y;

    // Paper surface:
    float fine   = vnoise(vec3(pu * 300.0, 1.0));
    float mid    = vnoise(vec3(pu * 90.0,  2.0));
    float fiberA = vnoise(vec3(pu * vec2(140.0, 14.0), 3.0));
    float fiberB = vnoise(vec3(pu * vec2(12.0, 150.0), 4.0));
    float cloud  = vnoise(vec3(pu * 1.6, 5.0));
    float tooth  = 0.45 * fine + 0.30 * mid + 0.25 * max(fiberA, fiberB);

    vec3 paper = vec3(0.962, 0.955, 0.925);
    paper *= 1.0 + 0.10 * (tooth - 0.5) + 0.04 * (cloud - 0.5);

    // Ink shape:
    float rough = (vnoise(vec3(p * 32.0, 2.0)) - 0.5) * 0.07
                + (vnoise(vec3(p * 11.0, 5.0)) - 0.5) * 0.05;
    float feather = (tooth - 0.5) * 0.10;
    float h = h0 + rough + feather;

    float core = smoothstep(-0.008, 0.012, h);
    float wash = smoothstep(-0.10, 0.0, h) * (1.0 - core);

    // Ink thickness:
    float gran = vnoise(vec3(p * 45.0, 6.0));
    float pool = clamp(smoothstep(0.0, 0.5, h) * (0.45 + 0.9 * mott), 0.0, 1.0);
    float ring = exp(-max(h, 0.0) * 40.0);

    float T = core * (0.55 + 2.9 * pool + 0.55 * ring) * (0.82 + 0.36 * gran);
    T += wash * 0.45 * (0.5 + tooth);

    // Dry-brush gaps:
    float dry = smoothstep(0.58, 0.80, tooth) * (1.0 - pool);
    T *= 1.0 - 0.7 * dry * core;

    // Beer-Lambert style absorption:
    vec3 absorb = vec3(1.05, 0.95, 0.70);
    vec3 col = paper * exp(-absorb * T);

    col *= 1.0 - 0.04 * exp(-pu.x * pu.x * 4000.0);

    // Film grain:
    col *= 1.0 + 0.02 * (hash(vec3(F, 1.0)) - 0.5);
    return col;
}

void mainImage(out vec4 O, in vec2 F) {
    vec2 res = iResolution.xy;
    vec2 uv  = (2.0 * F - res) / res.y;
    vec2 pu  = uv;

    float a = TAU * iTime / LOOP;

    // Slow breathing of the whole blot (periodic)
    uv *= 1.0 + 0.04 * sin(a);

    // Mirror, bilateral symmetry:
    vec2 p = vec2(abs(uv.x), uv.y);

    // Animated domain warp:
    vec2 warp = vec2(fbm(p * 1.1,                  a,       3),
                     fbm(p * 1.1 + vec2(5.2, 1.3), a + 2.0, 3)) - 0.5;
    float h0   = inkField(p, warp, a);
    float mott = fbm(p * 5.0 + vec2(7.0, 3.0), a, 3);
    vec3 col   = inkOnPaper(F, p, h0, mott);

    // Vignette (screen-fixed)
    float vig = 1.0 - VIGNETTE * pow(smoothstep(0.45, 2.0, length(pu)), 1.4);
    col *= vig;

    O = vec4(clamp(col, 0.0, 1.0), 1.0);
}
