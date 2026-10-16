#version 460 core
#include <flutter/runtime_effect.glsl>

// Procedural animated backdrops for the worlds. One shader, seven looks
// (uKind), then optional layered ridges and drifting particles on top.
uniform vec2 uSize;
uniform float uTime;
uniform float uKind;
uniform float uRidge;
uniform float uPart;
uniform float uSeed;
uniform vec3 uC0;
uniform vec3 uC1;
uniform vec3 uC2;
uniform vec3 uC3;

out vec4 fragColor;

float hash(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
  float v = 0.0;
  float a = 0.5;
  mat2 m = mat2(1.6, 1.2, -1.2, 1.6);
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = m * p;
    a *= 0.5;
  }
  return v;
}

float stars(vec2 p, float t) {
  float s = 0.0;
  for (int l = 0; l < 2; l++) {
    float fl = float(l);
    vec2 g = p * (38.0 + fl * 34.0) + uSeed * 11.0;
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    float h = hash(id + fl * 9.0);
    vec2 off = (vec2(hash(id + 1.7), hash(id + 5.3)) - 0.5) * 0.6;
    float d = length(f - off);
    float tw = 0.55 + 0.45 * sin(t * (0.6 + h * 1.8) + h * 40.0);
    s += step(0.86, h) * smoothstep(0.09, 0.0, d) * tw * (1.0 - fl * 0.4);
  }
  return s;
}

vec3 nebula(vec2 p, float t) {
  vec2 q0 = p * vec2(1.3, 1.6) + uSeed * 7.0;
  vec2 q = vec2(fbm(q0 + vec2(0.0, t * 0.025)), fbm(q0 + vec2(5.2, 1.3) - t * 0.02));
  vec2 r = vec2(fbm(q0 + 3.0 * q + vec2(1.7, 9.2) + t * 0.04), fbm(q0 + 3.0 * q + vec2(8.3, 2.8) - t * 0.03));
  float f = fbm(q0 + 3.0 * r);
  vec3 col = mix(uC0, uC1, clamp(f * 1.7, 0.0, 1.0));
  col = mix(col, uC2, clamp(length(q) * 0.95 - 0.2, 0.0, 1.0) * 0.55);
  col = mix(col, uC3, clamp(r.x * r.x * 2.0, 0.0, 1.0) * 0.45);
  col += vec3(stars(p, t)) * (1.0 - clamp(f * 1.6, 0.0, 1.0));
  return col;
}

vec3 aurora(vec2 p, float t) {
  vec3 col = mix(uC0, uC1, smoothstep(0.0, 1.0, p.y));
  col += vec3(stars(p, t)) * 0.85;
  for (int i = 0; i < 3; i++) {
    float fi = float(i);
    float x = p.x * (1.1 + fi * 0.45) + fi * 3.0 + uSeed * 5.0;
    float w = sin(x * 2.0 + t * (0.12 + fi * 0.04)) + 0.5 * sin(x * 4.7 - t * 0.17) + 0.3 * sin(x * 9.0 + t * 0.3);
    float y0 = 0.30 + 0.09 * fi + 0.05 * w;
    float d = y0 - p.y;
    float fade = d > 0.0 ? exp(-d * 4.2) : exp(d * 38.0);
    float streak = 0.55 + 0.45 * noise(vec2(x * 16.0, t * 0.12 + fi));
    col += mix(uC2, uC3, clamp(fi / 2.0 + 0.25 * w, 0.0, 1.0)) * fade * streak * 0.5;
  }
  return col;
}

float caust(vec2 uv, float t) {
  vec2 p = mod(uv * 6.28318, 6.28318) - 250.0;
  vec2 i = p;
  float c = 1.0;
  float inten = 0.005;
  for (int n = 0; n < 4; n++) {
    float tt = t * (1.0 - 3.5 / float(n + 1));
    i = p + vec2(cos(tt - i.x) + sin(tt + i.y), sin(tt - i.y) + cos(tt + i.x));
    c += 1.0 / length(vec2(p.x / (sin(i.x + tt) / inten), p.y / (cos(i.y + tt) / inten)));
  }
  c /= 4.0;
  c = 1.17 - pow(c, 1.4);
  return pow(abs(c), 8.0);
}

vec3 water(vec2 p, float t) {
  vec3 col = mix(uC1, uC0, smoothstep(0.0, 1.0, p.y));
  float rays = sin(p.x * 7.0 + p.y * 2.5 + t * 0.2 + uSeed * 4.0) * 0.5 + 0.5;
  rays *= sin(p.x * 3.1 - p.y * 1.7 - t * 0.13) * 0.5 + 0.5;
  col += uC3 * pow(rays, 3.0) * (1.0 - p.y) * (1.0 - p.y) * 0.5;
  float c = caust(p * 0.55 + uSeed, t * 0.5 + 23.0);
  col += uC3 * c * 0.5 * (1.0 - p.y * 0.8);
  col += uC2 * 0.18 * smoothstep(0.55, 1.0, p.y) * (0.6 + 0.4 * noise(vec2(p.x * 3.0 + t * 0.05, p.y * 4.0)));
  return col;
}

vec3 synth(vec2 p, float t) {
  float hz = 0.58;
  vec3 col = mix(uC0, uC1, smoothstep(0.0, hz, p.y));
  col += vec3(stars(p, t)) * smoothstep(hz, 0.1, p.y);
  vec2 sc = vec2(0.5 * uSize.x / uSize.y, hz - 0.12);
  float d = length(p - sc);
  float sun = smoothstep(0.175, 0.165, d);
  float band = step(0.0, sin((p.y - sc.y) * 95.0 - t * 0.0)) ;
  float cut = smoothstep(0.0, 0.02, p.y - sc.y - 0.02) ;
  float slats = mix(1.0, step(0.4, fract((p.y - sc.y) * 22.0)), smoothstep(-0.02, 0.18, p.y - sc.y));
  vec3 sunCol = mix(uC2, uC3, smoothstep(sc.y - 0.2, sc.y + 0.2, p.y));
  col += sunCol * exp(-d * 4.5) * 0.45;
  col = mix(col, sunCol, sun * slats);
  if (p.y > hz) {
    float yy = (p.y - hz) / (1.0 - hz);
    float z = 1.0 / (yy + 0.02);
    float gx = (p.x / (uSize.x / uSize.y) - 0.5) * z * 6.0;
    float gz = z * 1.1 - t * 0.55;
    float wx = 0.02 + 0.05 * (1.0 - yy);
    float lx = 1.0 - smoothstep(0.0, wx * 1.4, 0.5 - abs(fract(gx) - 0.5));
    float lz = 1.0 - smoothstep(0.0, 0.05 + 0.04 * (1.0 - yy), 0.5 - abs(fract(gz) - 0.5));
    float g = max(lx * smoothstep(0.02, 0.2, yy), lz * smoothstep(0.0, 0.12, yy));
    vec3 floorC = mix(uC0 * 0.5, uC1 * 0.6, yy);
    col = floorC + mix(uC2, uC3, yy) * g * (0.35 + 0.65 * yy) * 1.2;
    col += sunCol * exp(-(p.y - hz) * 9.0) * 0.35;
  }
  float line = smoothstep(0.006, 0.0, abs(p.y - hz));
  col += mix(uC2, uC3, 0.5) * line * 0.9;
  return col;
}

vec3 lava(vec2 p, float t) {
  vec2 q0 = p * vec2(1.7, 2.1) + uSeed * 5.0;
  q0.y += t * 0.05;
  vec2 q = vec2(fbm(q0), fbm(q0 + vec2(5.2, 1.3)));
  vec2 r = vec2(fbm(q0 + 3.5 * q + vec2(1.7, 9.2) + t * 0.05), fbm(q0 + 3.5 * q + vec2(8.3, 2.8)));
  float f = fbm(q0 + 3.5 * r);
  float cracks = smoothstep(0.07, 0.0, abs(f - 0.5));
  vec3 col = mix(uC0, uC1, smoothstep(0.2, 0.75, f));
  col += uC2 * cracks * 1.1;
  col += uC3 * pow(clamp(f * 1.5 - 0.5, 0.0, 1.0), 3.0) * 0.6;
  col *= 0.4 + 0.4 * smoothstep(0.0, 0.5, p.y);
  return col;
}

vec3 mist(vec2 p, float t) {
  vec3 col = mix(uC0, uC1, smoothstep(0.05, 0.7, p.y));
  col += vec3(stars(p, t)) * smoothstep(0.5, 0.1, p.y) * 0.8;
  float sv = fract(uSeed * 3.7);
  vec2 orb = vec2(uSize.x / uSize.y * (0.25 + 0.5 * fract(uSeed * 5.3)), 0.2 + 0.22 * sv);
  float orbR = 0.06 + 0.05 * fract(uSeed * 2.9);
  float d = length(p - orb);
  float ang = atan(p.x - orb.x, p.y - orb.y);
  float rays = pow(noise(vec2(ang * 5.0 + t * 0.04, uSeed * 9.0)), 2.0) * exp(-d * 2.2);
  col += uC2 * rays * 0.28;
  col += uC2 * exp(-d * 5.0) * 0.5;
  col = mix(col, mix(uC2, vec3(1.0), 0.35), smoothstep(orbR + 0.007, orbR, d));
  float f = fbm(vec2(p.x * 1.6 + t * 0.018, p.y * 7.0 + uSeed * 3.0));
  col += uC1 * f * 0.35 * smoothstep(0.25, 0.75, p.y);
  return col;
}

vec3 bokeh(vec2 p, float t) {
  vec3 col = mix(uC0, uC1, smoothstep(0.0, 1.0, p.y + 0.12 * sin(p.x * 2.0 + t * 0.08)));
  col += mix(uC2, uC3, noise(p * 2.0 + t * 0.02)) * 0.1 * fbm(p * 3.0 + t * 0.03);
  for (int l = 0; l < 3; l++) {
    float fl = float(l);
    float sc = 3.2 + fl * 2.6;
    vec2 g = p * sc;
    g.y += t * (0.05 + fl * 0.04);
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    float h = hash(id + fl * 13.0 + uSeed * 3.0);
    vec2 off = (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.5;
    float d = length(f - off);
    float r = 0.1 + 0.18 * h;
    float disc = smoothstep(r, r - 0.04, d) * 0.22 + smoothstep(0.03, 0.0, abs(d - r)) * 0.35;
    col += mix(uC2, uC3, hash(id + 2.2)) * disc * step(0.35, h) * (0.6 + 0.4 * sin(t * 0.4 + h * 20.0));
  }
  return col;
}

vec3 ridges(vec3 col, vec2 p, float t) {
  float n = uRidge;
  for (int i = 0; i < 4; i++) {
    float fi = float(i);
    if (fi < n) {
      float dep = fi / max(n - 1.0, 1.0);
      float x = p.x * (1.5 + fi * 0.9) + fi * 7.3 + uSeed * 4.0 + t * (0.002 + fi * 0.002);
      float h = 0.66 + 0.075 * fi - 0.11 * (fbm(vec2(x, fi * 3.1)) + 0.25 * noise(vec2(x * 3.0, fi)));
      if (p.y > h) {
        vec3 far = mix(uC1, uC0, 0.45);
        vec3 near = uC0 * 0.22;
        vec3 c = mix(far, near, dep);
        float below = p.y - h;
        c = mix(c, uC1 * 0.9, exp(-below * 7.0) * 0.22 * (1.0 - dep));
        c += uC2 * smoothstep(0.012, 0.0, below) * 0.35 * (1.0 - dep * 0.5);
        col = c;
      }
    }
  }
  return col;
}

vec3 particles(vec3 col, vec2 p, float t) {
  float falling = uPart > 1.5 ? 1.0 : 0.0;
  for (int l = 0; l < 3; l++) {
    float fl = float(l);
    float sc = 7.0 + fl * 6.0;
    vec2 g = p * sc;
    float sp = 0.35 + fl * 0.22;
    g.y += (falling > 0.5 ? -t : t) * sp;
    g.x += falling * sin(t * 0.3 + fl) * 0.8;
    vec2 id = floor(g);
    vec2 f = fract(g) - 0.5;
    float h = hash(id + fl * 17.0 + uSeed);
    float h2 = hash(id + 4.4);
    vec2 off = (vec2(h2, hash(id + 7.7)) - 0.5) * 0.55;
    off.x += 0.18 * sin(t * (0.5 + h) + h * 30.0);
    float d = length(f - off);
    float s = 0.045 + 0.05 * h2;
    float tw = falling > 0.5 ? 1.0 : 0.35 + 0.65 * (0.5 + 0.5 * sin(t * (0.8 + h * 2.0) + h * 40.0));
    float dot = (smoothstep(s, s * 0.35, d) + exp(-d * d / (s * s * 6.0)) * 0.4) * smoothstep(0.38, 0.14, d);
    col += mix(uC2, uC3, h2) * dot * tw * step(0.8, h) * (0.9 - fl * 0.22);
  }
  return col;
}

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 uv = fc / uSize;
  float asp = uSize.x / uSize.y;
  vec2 p = vec2(uv.x * asp, uv.y);
  float t = uTime;
  vec3 col;
  if (uKind < 0.5) col = nebula(p, t);
  else if (uKind < 1.5) col = aurora(p, t);
  else if (uKind < 2.5) col = water(p, t);
  else if (uKind < 3.5) col = synth(p, t);
  else if (uKind < 4.5) col = lava(p, t);
  else if (uKind < 5.5) col = mist(p, t);
  else col = bokeh(p, t);
  if (uRidge > 0.5) col = ridges(col, p, t);
  if (uPart > 0.5) col = particles(col, p, t);
  vec2 v = uv - 0.5;
  col *= 1.0 - 0.55 * dot(v, v);
  col += (hash(fc + t) - 0.5) / 255.0;
  fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
