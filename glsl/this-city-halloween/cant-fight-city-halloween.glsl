/* Title: "Can't Fight City Halloween"
   Year: 2026
   Author: Alif Ramedhis
   Description:
      An architecture folding - a flat city cut at two hinges;
      Inspired by Christopher Nolan's Inception and Matt Reeves'
      Batman-esque noir aesthetic.
*/

#define TAU    6.28318530718
#define LOOP   56.0      // seconds per loop
#define FOLDS  3.        // fold cycles per loop (whole number)
#define TRAVEL 12.       // blocks travelled per loop
#define CELL   2.5       // size of one city block
#define HINGE  5.0       // side hinge distance
#define TMAX   70.0      // view distance

mat2  R1, R2;            // fold rotations: front hinge, side hinges
float ZT;                // distance travelled down the street
float ZH;                // front hinge distance
vec3  RO;                // camera position

mat2 rot(float a){ float c = cos(a), s = sin(a); return mat2(c, s, -s, c); }

float ease(float x){
    float s = x * x * x * (x * (x * 6. - 15.) + 10.);
    float s2 = s * s * s * (s * (s * 6. - 15.) + 10.);
    return mix(s, s2, .7);
}

vec3 hash32(vec2 p){
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

float box(vec3 p, vec3 b){
    vec3 q = abs(p) - b;
    return length(max(q, 0.)) + min(max(q.x, max(q.y, q.z)), 0.);
}

float tower(vec3 p, vec2 w, float h){ return box(p - vec3(0., h, 0.), vec3(w.x, h, w.y)); }

// Flat city: ground at y = 0, one cubic building per block, 5 shape families
float city(vec3 q){
    q.z += ZT;
    vec2 id = floor(q.xz * (1. / CELL));
    q.xz -= (id + .5) * CELL;
    vec2 k = vec2(id.x, mod(id.y, TRAVEL));
    vec3 r = hash32(k), s = hash32(k + 17.3), t = hash32(k + 53.1);

    float H  = .3 + 1.3 * r.x;
    vec2  w  = .6 + .15 * r.yz;
    float v  = t.x, d;
    float Hb = H;

    // Building shape families:
    if (v < .2){
        d = tower(q, w, H);
    } else if (v < .4){
        vec2 sg = step(.5, s.yz) * 2. - 1.;
        d = tower(q, w, H);
        d = max(d, -box(q - vec3(-sg.x * w.x, 0., -sg.y * w.y), vec3(.2 + .15 * t.y, 9., .2 + .15 * t.z)));
    } else if (v < .6){
        d = tower(q, w, H);
        float e  = min(.07 + .1 * t.z, max(H - .35, .03));
        float lo = .35 + e, hi = 2. * H - .35 - e;
        float hc = hi > lo ? mix(lo, hi, t.y) : H;
        d = max(d, -box(q - vec3(0., hc, 0.), s.y < .5 ? vec3(9., e, w.y * .55) : vec3(w.x * .55, e, 9.)));
    } else if (v < .8){
        float podiumH = .3 + .25 * t.y;
        Hb = max(H, podiumH + .4);
        d = min(tower(q, vec2(.75), podiumH), tower(q, w * .72, Hb));
    } else {
        d = min(tower(q - vec3(-.55 * w.x, 0., 0.), vec2(.42 * w.x, w.y), H),
                tower(q - vec3( .55 * w.x, 0., 0.), vec2(.42 * w.x, w.y), H * (.35 + .5 * t.y)));
    }

    // Rooftop box, random size and offset, stacked on top:
    if (v < .8){
        float H2 = .2 + .3 * r.z;
        vec2 w2  = w * (.5 + .4 * s.x) * (v < .6 ? 1. : .72);
        vec2 off = (s.yz - .5) * (w - w2) * 1.6;
        d = min(d, box(q - vec3(off.x, 2. * Hb + H2, off.y), vec3(w2.x, H2, w2.y)));
    }

    // Other blocks are at least this far:
    d = min(d, 1.7 - max(abs(q.x), abs(q.z)));
    return min(d, q.y);
}

// Undo a fold: where does a point of the folded world sit in the flat city?
vec3 unfoldX(vec3 p){ p.xy = (p.xy - vec2(HINGE, 0.)) * R2 + vec2(HINGE, 0.); return p; }
vec3 unfoldZ(vec3 p){ p.yz = R1 * (p.yz - vec2(0., ZH)) + vec2(0., ZH); return p; }

// Side hinges (symmetric left / right): the part beyond |x| = HINGE rotates by R2
float sideFold(vec3 p, out float fy){
    p.x = abs(p.x);
    vec3 q = unfoldX(p);
    float a = p.x - HINGE, b = HINGE - q.x;
    if (a > b){ vec3 t = p; p = q; q = t; float s = a; a = b; b = s; }
    float d = max(city(p), a);
    fy = p.y;
    if (b < d){ float e = max(city(q), b); if (e < d){ d = e; fy = q.y; } }
    return d;
}

// Front hinge: the part beyond z = ZH rotates by R1 (and carries its own side folds)
float scene(vec3 p, out float fy){
    // Empty bubble around the camera
    float bubble = .4 - length(p - RO);
    vec3 q = unfoldZ(p);
    float a = p.z - ZH, b = ZH - q.z;
    if (a > b){ vec3 t = p; p = q; q = t; float s = a; a = b; b = s; }
    float d = max(sideFold(p, fy), a);
    if (b < d){ float fy2, e = max(sideFold(q, fy2), b); if (e < d){ d = e; fy = fy2; } }
    return max(d, bubble) * .9;
}

float map(vec3 p){ float fy; return scene(p, fy); }

vec3 getNormal(vec3 p, float e){
    vec2 k = vec2(1., -1.);
    return normalize(k.xyy * map(p + k.xyy * e) + k.yyx * map(p + k.yyx * e) +
                     k.yxy * map(p + k.yxy * e) + k.xxx * map(p + k.xxx * e));
}

// Soft shadow (iq):
float shadow(vec3 ro, vec3 rd){
    float res = 1., t = .03;
    // Low backlight needs long shadow rays
    for (int i = 0; i < 32; i++){
        float h = map(ro + rd * t);
        res = min(res, 8. * h / t);
        t += clamp(h, .04, .8);
        if (res < .01 || t > 20.) break;
    }
    res = clamp(res, 0., 1.);
    return res * res * (3. - 2. * res);
}

// How much of light direction L reaches point p with normal n:
float lit(vec3 p, vec3 n, vec3 L){
    float k = max(dot(n, L), 0.);
    return k > 0. ? k * shadow(p + n * .02, L) : 0.;
}

// Fold timeline and hinge placement for loop phase ph (0..1):
void animate(float ph){
    float lap  = TRAVEL * CELL;
    float hold = 4.13 * FOLDS / LOOP;
    float move = .5 - hold;
    ZT = lap * ph;

    float u = fract(FOLDS * ph);
    float front = ease(clamp(u / move, 0., 1.)) - ease(clamp((u - move - hold) / move, 0., 1.));
    R1 = rot(TAU / 4. * front);             // folds are exactly 90 deg
    R2 = rot(TAU / 4. * (1. - front));      // side walls do the opposite

    float cycle = floor(FOLDS * ph + .5 * hold);
    float travelAtEnd = lap * (cycle + 1. - hold) / FOLDS;
    ZH = CELL * ceil((travelAtEnd + 1.6) / CELL) - ZT;
}

// Colour of a hit point p with normal n, seen along rd at distance t:
vec3 shade(vec3 p, vec3 n, vec3 rd, float t, mat3 cam, vec3 bg){
    float fy;
    scene(p, fy);

    float d1 = max(dot(n, cam * normalize(vec3( .7,  .5, -.5))), 0.);
    float d2 = max(dot(n, cam * normalize(vec3(-.6, -.5, -.3))), 0.);
    float fr = 1. + dot(n, rd);
    vec3 col = vec3(.10, .11, .14) * (.2 + 2. * d1) + vec3(.03, .04, .07) * (.3 + .7 * n.y);
    col += vec3(1., .5, .16) * d1 * d1 * 1.3 + vec3(.85, .06, .10) * (d2 * d2 * .65 + fr * fr * fr * .4);

    // Moonlight from the upper side (cool, soft shadows), and a hot ember backlight low down the far end of the street
    // (rim light on edges, long shadows toward you):
    col += vec3(.35, .5, .85) * (.8 * lit(p, n, normalize(vec3(.55, .8, -.3))));
    col += vec3(1., .42, .14) * (1.3 * lit(p, n, normalize(vec3(-.4, .22, 1.))));

    // Soft occlusion over growing radii: darkens streets and corners:
    float ao = 0., sc = 1., rad = .06;
    for (int k = 0; k < 5; k++){
        rad *= 1.7;
        ao += (rad - max(map(p + n * rad), 0.)) * sc;
        sc *= .62;
    }
    col *= 1. - .95 * smoothstep(.05, .8, 1.4 * ao);

    col *= mix(.15, 1.3, pow(smoothstep(0., 3.5, fy), 1.4));

    float road = 1. - smoothstep(.03, .1, fy);
    col *= mix(vec3(1.), vec3(.38, .42, .52), road);

    // Far city sinks into the haze:
    col *= mix(vec3(1.), vec3(.65, .82, 1.15), smoothstep(6., 35., t));
    col = mix(col, mix(vec3(.02, .05, .18), bg, .3), smoothstep(TMAX * .12, TMAX * .8, t));

    // Far roads lighten into a light red glow:
    return mix(col, vec3(.92, .38, .30), road * smoothstep(6., 40., t) * .85);
}

// Exposure, tone curve, colour grade:
vec3 grade(vec3 col){
    col = pow(1.35 * col / (1. + .75 * col), vec3(.97));
    float lum = dot(col, vec3(.3, .6, .1));
    col = mix(col, col * vec3(.75, 1., 1.3), .6 * (1. - smoothstep(0., .4, lum)));
    col.r *= .9;
    col = clamp(col, 0., 1.);
    col = max(col - .015, 0.) / .985;
    col = mix(col, col * col * (3. - 2. * col), vec3(.84, .7, .77));
    float lm = dot(col, vec3(.2126, .7152, .0722));
    float chroma = max(col.r, max(col.g, col.b)) - min(col.r, min(col.g, col.b));
    col = mix(vec3(lm), col, 1. + .4 * (1. - chroma));
    col = mix(vec3(lm), col, 1.15 * (1. + .2 * clamp(2. * (max(col.r, col.b) - col.g), 0., 1.)));
    return clamp(col, 0., 1.);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    float ph = iTime / LOOP;
    float W  = TAU * ph;               // loop angle
    float S  = TAU * iTime / 28.;      // sway angle: bob / look-around / flicker
    animate(ph);

    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;

    // Backdrop: red glow with a slow looping flicker:
    vec3 haze = vec3(.75, .13, .07);
    float flick = 1. + .07 * sin(3. * S) + .04 * sin(5. * S + 1.3);
    vec2 g = uv - vec2(0., .08);
    vec3 bg = vec3(.012, .014, .020) + haze * exp(-dot(g, g) * 2.2) * flick;

    // Camera: flies down the street, bobs, looks around, rolls twice per loop
    RO = vec3(0., 1.6 + .5 * sin(S + 1.), 0.);
    vec3 fwd = normalize(vec3(.45 * sin(S), .12 * sin(2. * S + 1.), 1.));
    vec3 rgt = normalize(cross(vec3(0, 1, 0), fwd));
    mat3 cam = mat3(rgt, cross(fwd, rgt), fwd) * mat3(rot(2. * W + .15 * sin(2. * S + .5)));
    vec3 rd = normalize(cam * vec3(uv, 1.1));

    // Raymarch:
    float pix = 1. / iResolution.y;
    float t = 0., d, eps, glow = 0.;
    for (int i = 0; i < 128; i++){
        d = map(RO + rd * t);
        glow += .006 / (1. + 40. * d * d);
        eps = (t * pix + 1e-4) * .6;
        if (d < eps || t > TMAX) break;
        t += d;
    }

    vec3 col = bg;
    if (d < eps){
        vec3 p = RO + rd * t;
        vec3 n = getNormal(p, max(t * pix * .7, 1e-5));
        if (dot(n, rd) > 0.) n = -n;
        col = shade(p, n, rd, t, cam, bg);
    }
    col = grade(col + haze * glow);

    vec2 vq = fragCoord / iResolution.xy - .5;

    // Vignette:
    fragColor = vec4(col * (1. - dot(vq, vq)), 1.);
}
