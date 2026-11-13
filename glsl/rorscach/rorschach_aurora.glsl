/* 
   Title: "Rorschach/Aurora"
   Year: 2026
   Author: Alif Ramedhis
   Description:
      An endlessly shifting, mirrored Rorschach inkblot made of colorful light.
      Shader style inspired by "Aurora" by @kishimisu.
*/

#define TAU    6.28318530718
#define LOOP   16.0        // in seconds
#define LAYERS 26          // glow layers (lower = faster)
#define GLOW   1.5         // overall brightness (0.7 - 2.2)
#define POP    1.0         // color pop: 0.0 = original v3, 1.0 = slight pop, 2.0 = strong

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
float inkField(vec2 p, vec2 warp, float a, float z) {
    // Strong domain warp (like spilled ink):
    vec2 q = p + warp * 1.4;

    float e = 1.0 - length(vec2(p.x * 0.72, p.y * 0.95));

    float n = fbm(q * 2.3 + vec2(0.0, z * 0.9), a + z * 1.3, 3);
    float h = (n - 0.5) * 2.2 + e - 0.36;

    // Splatter:
    float sp   = lnoise(p * 6.5 + vec2(3.0, 7.0 + z * 0.5), a, 0.5);
    float gate = smoothstep(0.0, 0.3, 1.0 - length(vec2(p.x * 0.50, p.y * 0.75)));
    h = max(h, (sp - 0.72) * 3.0 * gate);

    h -= 0.18 * exp(-p.x * p.x * 500.0);
    vec2 d = p - vec2(0.0, 0.14);
    h -= 0.6 * exp(-50.0 * dot(d, d));
    return h;
}

void mainImage(out vec4 O, in vec2 F) {
    vec2 res = iResolution.xy;
    vec2 uv  = (2.0 * F - res) / res.y;

    float a = TAU * iTime / LOOP;

    // Slow breathing of the whole blot (periodic):
    uv *= 1.0 + 0.04 * sin(a);

    // Mirror, bilateral symmetry:
    vec2 p = vec2(abs(uv.x), uv.y);

    // Animated domain warp:
    vec2 warp = vec2(fbm(p * 1.1,                  a,       3),
                     fbm(p * 1.1 + vec2(5.2, 1.3), a + 2.0, 3)) - 0.5;
    vec3 col = vec3(0.0);

    for (int i = 0; i < LAYERS; i++) {
        float z = float(i) / float(LAYERS - 1);

        float h = inkField(p * (1.0 + z * 0.35), warp, a, z);

        float body = smoothstep(-0.03, 0.12, h);
        float edge = exp(-abs(h) * 16.0);
        float halo = exp(-abs(h) * 4.5);
        float fall = 1.0 - 0.75 * z;

        // Aurora-style cosine palette:
        vec3 c = 1.0 + cos(TAU * (z * 0.9 + vec3(0.0, 0.33, 0.67)) + a + h * 3.0);

        vec3 cp = pow(c * 0.5, vec3(1.0 + 0.15 * POP)) * 2.0;
        c = mix(c, cp, min(POP, 1.0));

        float dens = 0.6 + 0.8 * clamp(h * 2.0, 0.0, 1.0);

        float light = 0.55 * edge + 0.20 * halo + 0.22 * body * fall * dens;
        col += c * light * (0.05 / (0.35 + z));
    }

    col *= GLOW;

    // Faint ambient glow so the background isn't dead black:
    float r = length(uv);
    col += 0.02 * (1.0 + cos(vec3(0.0, 1.0, 2.0) + a + r * 2.0)) * exp(-r * 1.2);

    float lum = dot(col, vec3(0.2126, 0.7152, 0.0722));
    col = max(mix(vec3(lum), col, 1.0 + 0.25 * POP), 0.0);

    // Tone map + gamma:
    col = 1.0 - exp(-col * 2.2);
    col = pow(col, vec3(0.4545));

    // Gentle contrast curve:
    col = mix(col, col * col * (3.0 - 2.0 * col), 0.25 * POP);

    // Vignette:
    col *= smoothstep(1.9, 0.4, r);

    O = vec4(col, 1.0);
}
