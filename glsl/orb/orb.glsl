/*
   Title: "Orb"
   Year: 2026
   Author: Alif Ramedhis
   Description:
      A thick clear glass sphere filled with 3 aggressive liquids.
*/

#define FRAME        1.0
#define FIGHT        3.00
#define WARP         0.35
#define SHAFTS       0.3
#define SHAFT_STEPS  30
#define HALO         0.35

// Orb constants:
const float R_OUT = 1.10;
const float R_IN  = 0.85;
const float STEP  = 0.02;

// Liquid refractive index (1.50 +/- 0.35 gives strong lensing at the borders):
const vec3 N_SET = vec3(1.15, 1.50, 1.85);

// Liquid tints:
const mat3 TINT = mat3(1.00, 0.76, 0.82,    // Rose
                       0.98, 0.94, 0.82,    // Ivory
                       0.72, 0.80, 0.85);   // Mint
const mat3 SIG = (1.0 - TINT) * 4.5;

// Light and camera:
const vec3 L  = normalize(vec3(-35.0, 20.0, -30.0));
const vec3 KT = normalize(cross(vec3(0.0, 1.0, 0.0), L));
const vec3 KB = cross(L, KT);
const vec3 RO    = vec3(0.0, 0.54, 2.95);
const vec3 FWD   = normalize(-RO);
const vec3 RIGHT = normalize(cross(FWD, vec3(0.0, 1.0, 0.0)));
const vec3 UP    = cross(RIGHT, FWD);

// Liquid agression:
float gT;
vec3  gSeed[3];
float gSize[3];

// Calm position (laid out in x/z, since we look down the y axis):
const vec3 HOME[3] = vec3[3](vec3( 0.00, 0.05, -0.50),   // top of the screen
                             vec3(-0.45, 0.00,  0.40),   // bottom left
                             vec3( 0.55, 0.00,  0.10));  // right

void setupFight() {
    gT = iTime * 1.30;
    for (int i = 0; i < 3; i++) {
        float k = float(i);

        // Wandering:
        vec3 wander = 0.22 * FIGHT * vec3(sin(gT * (0.71 + 0.19 * k) + 1.7 * k),
                                          sin(gT * (0.93 - 0.11 * k) + 4.0 * k + 1.0),
                                          sin(gT * (0.57 + 0.23 * k) + 2.3 * k + 0.5));

        // Periodic lunge:
        float pulse = pow(0.5 + 0.5 * sin(gT * (0.80 + 0.17 * k) + 2.4 * k), 3.0);
        float lunge = min(0.40 * FIGHT, 0.90) * pulse;

        gSeed[i] = mix(HOME[i] + wander, HOME[(i + 1) % 3], lunge);

        // Swelling and shrinking, out of phase:
        gSize[i] = 0.14 * FIGHT * sin(gT * (0.90 + 0.30 * k) + 2.1 * k);
    }
}

// How much of each liquid is present at point p (the three weights add up to 1)
vec3 weightsAt(vec3 p) {
    // Twist space so the borders become tendrils instead of smooth curves:
    vec3 q = p + WARP * vec3(sin(3.1 * p.y + 1.3 * gT + 1.7 * p.z),
                             sin(2.7 * p.z - 1.1 * gT + 2.0 * p.x),
                             sin(3.3 * p.x + 0.9 * gT + 1.5 * p.y));
    q += 0.5 * WARP * vec3(sin(7.0 * q.y - 2.3 * gT),
                           sin(6.5 * q.z + 1.9 * gT),
                           sin(7.3 * q.x - 1.6 * gT));

    vec3 sd = vec3(length(q - gSeed[0]) - gSize[0],
                   length(q - gSeed[1]) - gSize[1],
                   length(q - gSeed[2]) - gSize[2]);
    float m = min(sd.x, min(sd.y, sd.z));
    vec3 e = exp(-(sd - m) * 60.0);
    return e / (e.x + e.y + e.z);
}

// Filmic tone curve (ACES approximation):
vec3 aces(vec3 x) {
    return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

float schlick(float cosT, float f0) {
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cosT, 0.0, 1.0), 5.0);
}

// Environment:
vec3 env(vec3 d) {
    vec3 c = mix(vec3(0.95, 0.96, 0.98), vec3(0.45, 0.47, 0.52), smoothstep(-0.6, 0.2, d.y));
    c = mix(c, vec3(0.18, 0.20, 0.25), pow(clamp(d.y, 0.0, 1.0), 0.6));

    // Key softbox that follows the key light:
    float w = dot(d, L);
    if (w > 0.05) {
        vec2 p = vec2(dot(d, KT), dot(d, KB)) / w;
        vec2 q = abs(p) - vec2(0.42, 0.26);
        float m = 1.0 - smoothstep(-0.03, 0.03, max(q.x, q.y));
        c += vec3(1.0, 0.95, 0.88) * (m * 6.0 + pow(w, 24.0) * 0.25);
    }

    // Fixed cool strip light:
    float a = atan(d.x, d.z);
    float strip = (1.0 - smoothstep(0.07, 0.10, abs(a - 2.2))) * (1.0 - smoothstep(0.60, 0.75, abs(d.y)));
    c += vec3(0.35, 0.50, 1.00) * strip * 1.6;

    return c;
}

// Optics helpers:
float leaveGlass(vec3 p, vec3 d, float nG, int ch) {
    float b = dot(p, d);
    float c = dot(p, p) - R_OUT * R_OUT;
    vec3 pe = p + d * (-b + sqrt(max(b * b - c, 0.0)));
    vec3 ne = pe / R_OUT;
    vec3 o = refract(d, -ne, nG);
    if (dot(o, o) < 0.5) o = reflect(d, -ne);   // trapped light in the shell (approximation)
    return env(o)[ch];
}

// Distance from p to the inner wall along d
float wallDist(vec3 p, vec3 d) {
    float b = dot(p, d);
    return -b + sqrt(max(b * b - (dot(p, p) - R_IN * R_IN), 0.0));
}

// Ray in the orb interior (medium index nIn):
float exitOrb(vec3 p, vec3 d, float nIn, float nG, int ch) {
    float tw = wallDist(p, d);
    float T = exp(-(SIG * weightsAt(p + d * (0.5 * tw)))[ch] * tw);
    vec3 pw = p + d * tw;
    vec3 nw = pw / R_IN;
    vec3 g = refract(d, -nw, nIn / nG);
    if (dot(g, g) < 0.5) g = reflect(d, -nw);
    return T * leaveGlass(pw, g, nG, ch);
}

// Full path of one colour channel:
float trace(vec3 rd, int ch) {
    // Rainbow fringing:
    float k  = float(ch - 1);
    float nG = 2.00 + 0.066 * k;
    float dn = 0.11 * k;

    // Outer glass surface:
    float b = dot(RO, rd);
    float c = dot(RO, RO) - R_OUT * R_OUT;
    vec3 p = RO + rd * (-b - sqrt(max(b * b - c, 0.0)));
    vec3 nf = p / R_OUT;
    float Ff = schlick(max(dot(-rd, nf), 0.0), 0.04);
    float col = env(reflect(rd, nf))[ch] * Ff;
    float T = 1.0 - Ff;
    vec3 d = refract(rd, nf, 1.0 / nG);

    // Through the glass wall to the inner surface:
    float bi = dot(p, d);
    float di = bi * bi - (dot(p, p) - R_IN * R_IN);
    if (di < 0.0) return col + T * leaveGlass(p, d, nG, ch);   // grazing ray
    p += d * (-bi - sqrt(di));
    vec3 ni = p / R_IN;

    float nI = dot(weightsAt(p), N_SET) + dn;
    vec3 dI = refract(d, ni, nG / nI);
    if (dot(dI, dI) < 0.5) return col + T * leaveGlass(p, reflect(d, ni), nG, ch);
    float f0 = (nG - nI) / (nG + nI);
    float Fi = schlick(dot(dI, -ni), f0 * f0);
    col += T * Fi * leaveGlass(p, reflect(d, ni), nG, ch);
    T *= 1.0 - Fi;
    d = dI;

    // March through the liquids:
    const float h = 0.02;
    float glow = 0.55 * (0.85 + 0.15 * sin(gT * 1.7));
    for (int i = 0; i < 80; i++) {
        vec3 w = weightsAt(p);
        float n0 = dot(w, N_SET);
        float n  = n0 + dn;
        vec3 g = (vec3(dot(weightsAt(p + vec3(h, 0.0, 0.0)), N_SET),
                       dot(weightsAt(p + vec3(0.0, h, 0.0)), N_SET),
                       dot(weightsAt(p + vec3(0.0, 0.0, h)), N_SET)) - n0) / h;
        float gl = length(g);

        d = normalize(d + (g - dot(g, d) * d) / n * STEP);   // gradient-index bending

        float tw = wallDist(p, d);
        float stp = min(STEP, tw);

        // Deep glow:
        col += T * glow * (TINT * w)[ch] * (0.25 + 9.0 * smoothstep(0.0, 1.5, gl)) * stp;

        // Absorption, plus extra darkening (4.0) along the borders:
        T *= exp(-((SIG * w)[ch] + 4.0 * gl) * stp);
        p += d * stp;
        if (tw <= STEP) break;   // reached the wall
    }

    // Out through the inner wall, the glass, and into the room:
    float nEnd = dot(weightsAt(p), N_SET) + dn;
    return col + T * exitOrb(p, d, nEnd, nG, ch);
}

// Light rays:
// how much key light reaches the point s, and in what colour
// if the orb sits between s and the light, the light is tinted by the liquids it crossed
// and (behind the orb) focused toward the axis like a ball lens
vec3 lightVis(vec3 s) {
    float t0 = -dot(s, L);
    if (t0 <= 0.0) return vec3(1.0);
    vec3 cp = s + L * t0;
    float b2 = dot(cp, cp);
    if (b2 >= R_OUT * R_OUT) return vec3(1.0);

    float b = sqrt(b2);
    float hh = sqrt(R_OUT * R_OUT - b2);
    vec3 e = s + L * (t0 - hh);
    vec3 x = s + L * (t0 + hh);
    vec3 sg = SIG * (weightsAt(mix(e, x, 0.2)) + weightsAt(mix(e, x, 0.5)) + weightsAt(mix(e, x, 0.8)));
    vec3 tr = exp(-sg * (0.6 * hh)) * 0.85;

    float rim = 1.0 - 0.5 * smoothstep(0.6, 1.0, b);
    float fx = t0 - 2.0;
    float focus = (1.0 - smoothstep(0.0, 0.6, b)) * exp(-fx * fx);
    return tr * rim * (1.0 + 3.0 * focus);
}

vec3 shafts(vec3 rd, float jit) {
    const float RB = 4.2;
    float bq = dot(RO, rd);
    float tFar = -bq + sqrt(max(bq * bq - (dot(RO, RO) - RB * RB), 0.0));
    float tNear = 0.3;
    float dt = (tFar - tNear) / float(SHAFT_STEPS);

    // Forward scattering (Henyey-Greenstein, g = 0.55):
    float hg = 0.6975 / pow(1.3025 - 1.1 * dot(L, rd), 1.5);
    float phase = 0.25 + 0.12 * hg;

    vec3 acc = vec3(0.0);
    for (int i = 0; i < SHAFT_STEPS; i++) {
        float t = tNear + (float(i) + jit) * dt;
        vec3 s = RO + rd * t;
        if (dot(s, s) < (R_OUT + 0.03) * (R_OUT + 0.03)) continue;

        // A soft column of light around the axis through the orb:
        float r = length(s - L * dot(s, L));
        float beam = 1.0 - smoothstep(0.8, 2.4, r);
        if (beam < 0.003) continue;

        // Streaks across the beam, slowly drifting:
        float a = dot(s, KT);
        float bb = dot(s, KB);
        float st1 = 0.5 + 0.5 * sin(a * 9.0 + 2.0 * sin(bb * 4.0 + gT * 0.6) + gT * 0.5);
        float st2 = 0.5 + 0.5 * sin(bb * 13.0 + a * 3.0 - gT * 0.4);
        float streak = 0.3 + 0.7 * st1 * st1 * (0.5 + 0.5 * st2);

        float fade = exp(-0.12 * max(-dot(s, L), 0.0));
        acc += beam * streak * fade * phase * lightVis(s) * dt;
    }
    return acc * vec3(1.0, 0.95, 0.88) * 0.35;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float sc = min(iResolution.x, iResolution.y);
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / sc * FRAME;

    setupFight();

    vec3 rd = normalize(uv.x * RIGHT + uv.y * UP + FWD);

    float dmin = length(cross(RO, rd));
    float aa = 3.0 * FRAME / sc;
    float alpha = 1.0 - smoothstep(R_OUT - aa, R_OUT + aa, dmin);

    // One noise value per pixel:
    float noise = fract(sin(dot(fragCoord, vec2(12.9898, 78.233))) * 43758.5453);

    // The orb, in linear light (black where the ray misses it)
    vec3 col = vec3(0.0);
    if (dmin < R_OUT + aa) {
        col = vec3(trace(rd, 0), trace(rd, 1), trace(rd, 2));
    }

    // Light rays through the air:
    if (SHAFTS > 0.0) {
        col += shafts(rd, noise) * SHAFTS * 2.0;
    }

    // Tone map + gamma, applied to the orb only:
    col = mix(1.0 - exp(-col), aces(col), 0.4);
    col = pow(col, vec3(0.4545));

    // Backdrop:
    vec3 bg = vec3(0.0);
    if (alpha < 1.0) {
        float v = 1.0 - 0.05 * dot(uv, uv);

        // Soft shadow:
        vec2 so = uv + vec2(dot(L, RIGHT), dot(L, UP)) * 0.12;
        v *= 1.0 - 0.30 * exp(-dot(so, so) * 4.0);

        // Tiny noise:
        bg = vec3(v + (noise - 0.5) / 255.0);

        // Faint colour tint:
        if (HALO > 0.0) {
            vec3 pc = RO + rd * (-dot(RO, rd));
            vec3 ps = normalize(pc + vec3(1e-4)) * 0.8;
            float bleed = HALO * exp(-max(dmin - R_OUT, 0.0) * 5.0);
            bg *= mix(vec3(1.0), TINT * weightsAt(ps), bleed);
        }
    }

    fragColor = vec4(mix(bg, col, alpha), 1.0);
}
