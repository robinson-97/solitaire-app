#version 460 core
#include <flutter/runtime_effect.glsl>

// Atmosphere for every world: skies, glows, volumetric clouds, aurora, fog,
// light shafts. Silhouettes and particles are drawn on top by Dart code.
uniform vec2 uSize;
uniform float uTime;   // seconds, loops every 60 s (all motion uses whole cycles)
uniform float uMode;

out vec4 fragColor;

const float TAU = 6.2831853;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

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
  for (int i = 0; i < 4; i++) {
    v += a * noise(p);
    p = p * 2.02 + vec2(1.7, 9.2);
    a *= 0.5;
  }
  return v;
}

vec3 grad3(float y, vec3 a, vec3 b, vec3 c, float m) {
  return y < m ? mix(a, b, smoothstep(0.0, m, y)) : mix(b, c, smoothstep(m, 1.0, y));
}

float stars(vec2 uv, float density, float t) {
  vec2 g = uv * vec2(90.0, 160.0);
  vec2 id = floor(g);
  vec2 f = fract(g) - 0.5;
  float h = hash(id);
  float on = step(1.0 - density, h);
  float tw = 0.55 + 0.45 * sin(t * TAU * (2.0 + floor(h * 4.0)) + h * 40.0);
  float s = smoothstep(0.28, 0.0, length(f)) * on * tw;
  return s;
}

vec3 aurora(vec2 uv, float t, float y0, vec3 c1, vec3 c2) {
  vec3 acc = vec3(0.0);
  for (int k = 0; k < 3; k++) {
    float fk = float(k);
    float wob = sin(uv.x * 5.0 + t * TAU * 2.0 + fk * 1.7) * 0.05 + sin(uv.x * 11.0 - t * TAU * 3.0 + fk) * 0.018;
    float center = y0 + fk * 0.055 + wob;
    float d = (uv.y - center);
    float body = exp(-pow(d * 11.0, 2.0)) ;
    float curtain = noise(vec2(uv.x * 28.0 + fk * 9.0, t * TAU * 0.6)) * 0.6 + 0.4;
    float below = smoothstep(-0.02, 0.2, d) * exp(-d * 6.0);
    acc += mix(c1, c2, fk / 2.0 + uv.x * 0.2) * (body * 0.7 + below * 0.5) * curtain * 0.65;
  }
  return acc;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;   // y grows downward
  float aspect = uSize.x / uSize.y;
  vec2 p = vec2(uv.x * aspect, uv.y);
  float t = uTime / 60.0;                    // 0..1 loop
  vec3 col = vec3(0.0);

  if (uMode < 0.5) {
    // ---------------- Glimmerwood: twilight forest
    col = grad3(uv.y, vec3(0.035, 0.035, 0.17), vec3(0.10, 0.17, 0.40), vec3(0.10, 0.36, 0.42), 0.5);
    col = mix(col, vec3(0.07, 0.25, 0.26), smoothstep(0.62, 0.95, uv.y));
    vec2 moon = vec2(0.78 * aspect, 0.14);
    float dm = length(p - moon);
    col += vec3(1.0, 0.93, 0.75) * 0.10 / (0.05 + dm * dm * 18.0);                // halo
    // god rays fanning from the moon
    float ang = atan(p.y - moon.y, p.x - moon.x);
    float rays = pow(noise(vec2(ang * 5.0 + t * TAU * 0.5, 3.0)), 3.0) * smoothstep(1.0, 0.0, dm * 1.2);
    col += vec3(0.8, 0.85, 1.0) * rays * 0.22 * smoothstep(0.1, 0.35, dm);
    col = mix(col, vec3(1.0, 0.97, 0.88), smoothstep(0.062, 0.050, dm));          // disc
    // thin high clouds
    float cl = fbm(vec2(p.x * 2.2 + t * TAU * 0.05, p.y * 5.0));
    col += vec3(0.25, 0.30, 0.55) * smoothstep(0.55, 0.85, cl) * (1.0 - uv.y) * 0.35;
    col += vec3(stars(uv, 0.035, t)) * smoothstep(0.55, 0.1, uv.y);
    // low valley fog
    float fog = fbm(vec2(p.x * 2.0 - t * TAU * 0.1, p.y * 4.0 + 3.0));
    col += vec3(0.16, 0.30, 0.34) * smoothstep(0.55, 0.9, uv.y) * (0.35 + 0.65 * fog) * 0.55;
  } else if (uMode < 1.5) {
    // ---------------- Crystal Cavern
    col = grad3(uv.y, vec3(0.025, 0.012, 0.09), vec3(0.09, 0.04, 0.24), vec3(0.04, 0.20, 0.27), 0.5);
    vec2 q = p * 2.4 + vec2(t * TAU * 0.3, 0.0);
    float m = fbm(q + fbm(q * 1.6 + t * TAU * 0.4));
    vec3 glowA = vec3(0.10, 0.85, 0.95);
    vec3 glowB = vec3(0.75, 0.30, 1.0);
    col += mix(glowA, glowB, fbm(q * 0.7 + 4.0)) * pow(m, 3.0) * 0.55 * smoothstep(0.15, 0.9, uv.y);
    float shaft = noise(vec2(uv.x * 9.0 + t * TAU * 0.4, 1.0)) * smoothstep(0.9, 0.05, uv.y);
    col += vec3(0.45, 0.8, 1.0) * pow(shaft, 3.0) * 0.28;
    float caustic = pow(abs(sin(uv.x * 40.0 + fbm(p * 6.0 + t * TAU) * 6.0)) , 12.0) * smoothstep(0.35, 0.0, uv.y);
    col += vec3(0.5, 0.9, 1.0) * caustic * 0.18;
  } else if (uMode < 2.5) {
    // ---------------- Starfall Peak
    col = grad3(uv.y, vec3(0.02, 0.025, 0.12), vec3(0.11, 0.09, 0.34), vec3(0.62, 0.28, 0.52), 0.55);
    col += vec3(stars(uv, 0.05, t)) * smoothstep(0.7, 0.0, uv.y);
    float band = fbm(vec2(p.x * 1.2 + p.y * 1.5, p.y * 3.0 + 2.0));
    col += vec3(0.35, 0.25, 0.6) * pow(band, 3.0) * 0.6 * smoothstep(0.7, 0.2, uv.y);
    col += aurora(uv, t, 0.20, vec3(0.2, 1.0, 0.75), vec3(0.55, 0.4, 1.0));
  } else if (uMode < 3.5) {
    // ---------------- Sunbaked Dunes
    col = grad3(uv.y, vec3(0.09, 0.05, 0.22), vec3(0.65, 0.22, 0.30), vec3(1.0, 0.62, 0.30), 0.62);
    vec2 sun = vec2(0.30 * aspect, 0.64);
    float ds = length(p - sun);
    col += vec3(1.0, 0.65, 0.30) * 0.22 / (0.06 + ds * ds * 7.0);
    col = mix(col, vec3(1.0, 0.95, 0.75), smoothstep(0.07, 0.055, ds));
    float streak = fbm(vec2(p.x * 1.4 + t * TAU * 0.05, p.y * 9.0));
    col += vec3(1.0, 0.55, 0.45) * smoothstep(0.5, 0.8, streak) * smoothstep(0.7, 0.3, uv.y) * 0.3;
    col += vec3(stars(uv, 0.03, t)) * smoothstep(0.4, 0.0, uv.y);
    // heat shimmer band near the horizon
    col += vec3(1.0, 0.7, 0.4) * smoothstep(0.55, 0.7, uv.y) * 0.1 * (0.5 + 0.5 * sin(uv.y * 160.0 - t * TAU * 6.0 + noise(p * 8.0) * 6.0));
  } else if (uMode < 4.5) {
    // ---------------- Coral Deep
    col = grad3(uv.y, vec3(0.02, 0.12, 0.26), vec3(0.03, 0.30, 0.46), vec3(0.03, 0.40, 0.45), 0.55);
    float rays = 0.0;
    for (int k = 0; k < 4; k++) {
      float fk = float(k);
      float cx = 0.12 + fk * 0.27 * 1.0 + sin(t * TAU + fk * 1.9) * 0.04;
      float dx = (uv.x - cx) + uv.y * 0.35;
      rays += exp(-dx * dx * 120.0) * (1.0 - uv.y) * (0.6 + 0.4 * sin(t * TAU * 2.0 + fk));
    }
    col += vec3(0.5, 0.9, 0.95) * rays * 0.28;
    float c1 = noise(p * 9.0 + vec2(t * TAU * 0.6, t * TAU * 0.4));
    float c2 = noise(p * 9.0 * 1.3 - vec2(t * TAU * 0.5, 0.0) + 7.0);
    float caustic = pow(1.0 - abs(c1 - c2), 8.0);
    col += vec3(0.6, 1.0, 1.0) * caustic * 0.30 * smoothstep(0.9, 0.0, uv.y);
    float snow = noise(p * 40.0 + vec2(0.0, -t * TAU * 3.0));
    col += vec3(0.7, 0.95, 1.0) * smoothstep(0.86, 0.95, snow) * 0.25;
  } else if (uMode < 5.5) {
    // ---------------- Ember Crater
    col = grad3(uv.y, vec3(0.035, 0.01, 0.02), vec3(0.23, 0.05, 0.05), vec3(0.75, 0.22, 0.07), 0.6);
    float heat = fbm(vec2(p.x * 3.0, p.y * 2.0 - t * TAU * 0.5));
    col += vec3(1.0, 0.35, 0.08) * pow(heat, 2.0) * smoothstep(0.35, 1.0, uv.y) * 0.5;
    float smoke = fbm(vec2(p.x * 1.8 + 3.0, p.y * 2.2 - t * TAU * 0.35));
    col = mix(col, vec3(0.10, 0.05, 0.06), smoothstep(0.45, 0.8, smoke) * smoothstep(0.7, 0.1, uv.y) * 0.7);
    col += vec3(1.0, 0.45, 0.15) * smoothstep(0.82, 0.98, noise(p * 30.0 + vec2(0.0, -t * TAU * 6.0))) * 0.35 * uv.y;
  } else if (uMode < 6.5) {
    // ---------------- Frostwind Tundra
    col = grad3(uv.y, vec3(0.015, 0.04, 0.14), vec3(0.05, 0.18, 0.34), vec3(0.50, 0.75, 0.88), 0.6);
    col += vec3(stars(uv, 0.045, t)) * smoothstep(0.6, 0.0, uv.y);
    col += aurora(uv, t, 0.18, vec3(0.3, 1.0, 0.7), vec3(0.2, 0.6, 1.0));
    float haze = fbm(vec2(p.x * 2.0 + t * TAU * 0.1, p.y * 6.0));
    col += vec3(0.7, 0.88, 1.0) * smoothstep(0.55, 0.95, uv.y) * (0.3 + 0.7 * haze) * 0.4;
  } else if (uMode < 7.5) {
    // ---------------- Sky Gardens: volumetric clouds
    col = grad3(uv.y, vec3(0.17, 0.16, 0.48), vec3(0.62, 0.38, 0.70), vec3(1.0, 0.76, 0.52), 0.6);
    vec2 sun = vec2(0.7 * aspect, 0.72);
    float ds = length(p - sun);
    col += vec3(1.0, 0.85, 0.55) * 0.20 / (0.05 + ds * ds * 6.0);
    col = mix(col, vec3(1.0, 0.97, 0.85), smoothstep(0.075, 0.06, ds));
    vec2 toSun = normalize(sun - p);
    for (int k = 0; k < 2; k++) {
      float fk = float(k);
      vec2 q = vec2(p.x * (1.6 + fk * 0.7) + t * TAU * (0.04 + fk * 0.03), p.y * (3.2 + fk) + fk * 5.0);
      float d = fbm(q);
      float dl = fbm(q + toSun * 0.12);
      float body = smoothstep(0.48, 0.78, d) * (0.55 + fk * 0.2);
      float lit = clamp((d - dl) * 5.0 + 0.55, 0.0, 1.0);
      vec3 cc = mix(vec3(0.55, 0.40, 0.70), vec3(1.0, 0.88, 0.80), lit);
      col = mix(col, cc, body * smoothstep(0.05, 0.3, uv.y) * (1.0 - fk * 0.2));
    }
  } else if (uMode < 8.5) {
    // ---------------- Stadium Nights
    col = grad3(uv.y, vec3(0.02, 0.03, 0.09), vec3(0.06, 0.11, 0.25), vec3(0.11, 0.18, 0.36), 0.55);
    col += vec3(stars(uv, 0.03, t)) * smoothstep(0.35, 0.0, uv.y);
    for (int k = 0; k < 2; k++) {
      float side = k == 0 ? 0.14 : 0.86;
      vec2 lamp = vec2(side * aspect, 0.26);
      vec2 d = p - lamp;
      float dir = k == 0 ? 1.0 : -1.0;
      float cone = smoothstep(0.55, 1.0, dot(normalize(d + vec2(0.0001)), normalize(vec2(dir * 0.8, 0.45))));
      float haze = fbm(p * 3.0 + vec2(t * TAU * 0.2, 0.0));
      col += vec3(1.0, 0.96, 0.82) * cone * exp(-length(d) * 1.8) * (0.25 + 0.4 * haze);
      col += vec3(1.0, 0.95, 0.8) * 0.045 / (0.01 + dot(d, d) * 14.0);
    }
    col += vec3(0.25, 0.3, 0.55) * smoothstep(0.55, 0.62, uv.y) * 0.15;
  } else if (uMode < 9.5) {
    // ---------------- Neon Arcade
    float horizon = 0.66;
    col = grad3(uv.y, vec3(0.04, 0.015, 0.12), vec3(0.20, 0.04, 0.38), vec3(1.0, 0.24, 0.60), horizon);
    col += vec3(stars(uv, 0.05, t)) * smoothstep(0.45, 0.0, uv.y);
    vec2 sun = vec2(0.5 * aspect, horizon - 0.02);
    float ds = length(p - sun);
    float sr = 0.28 * aspect;
    float disc = smoothstep(sr, sr - 0.01, ds) * step(p.y, horizon);
    float stripe = step(0.5, fract((p.y - sun.y) * 22.0 - t * TAU * 0.5 * 0.0 + t * 12.0)) ;
    float cut = smoothstep(sun.y - 0.02, sun.y + sr, p.y) ;
    vec3 sunCol = mix(vec3(1.0, 0.9, 0.35), vec3(1.0, 0.25, 0.65), clamp((p.y - (sun.y - sr)) / (2.0 * sr), 0.0, 1.0));
    col = mix(col, sunCol, disc * (1.0 - cut * (1.0 - stripe)));
    col += vec3(1.0, 0.3, 0.7) * 0.12 / (0.05 + ds * ds * 6.0);
    if (uv.y > horizon) {
      float ph = (uv.y - horizon) / (1.0 - horizon);
      col = mix(vec3(0.05, 0.02, 0.14), vec3(0.10, 0.03, 0.22), ph);
      float z = 1.0 / (ph + 0.02);
      float gx = abs(fract((uv.x - 0.5) * z * 0.9 * aspect + 0.5) - 0.5);
      float gz = abs(fract(z * 0.6 + t * 12.0) - 0.5);
      float line = smoothstep(0.03 * z * 0.5 + 0.01, 0.0, min(gx, gz * 0.35));
      col += mix(vec3(1.0, 0.2, 0.7), vec3(0.2, 0.95, 1.0), ph) * line * (0.25 + ph) * 0.9;
    }
    col += vec3(1.0, 0.25, 0.65) * exp(-abs(uv.y - horizon) * 40.0) * 0.5;
  } else {
    // ---------------- Nebula Drift: domain-warped gas
    vec2 q0 = p * 2.2;
    float w1 = fbm(q0 + vec2(t * TAU * 0.20, 0.0));
    float w2 = fbm(q0 + 4.0 * w1 + vec2(0.0, t * TAU * 0.15));
    float w3 = fbm(q0 + 3.0 * w2 + 8.0);
    col = vec3(0.012, 0.008, 0.05);
    col += vec3(0.95, 0.20, 0.55) * pow(w2, 2.5) * 0.9;
    col += vec3(0.20, 0.35, 1.00) * pow(w3, 2.5) * 0.9;
    col += vec3(0.10, 0.90, 0.80) * pow(max(w1 - 0.35, 0.0), 2.0) * 0.8;
    col *= 0.55 + 0.45 * smoothstep(0.0, 0.5, w3);
    col += vec3(stars(uv, 0.07, t)) * 1.1;
    float lane = smoothstep(0.52, 0.64, fbm(q0 * 1.4 + 11.0));
    col *= 1.0 - lane * 0.55;
  }

  // vignette and tone
  float vig = smoothstep(1.25, 0.35, length((uv - 0.5) * vec2(1.0, 0.85)));
  col *= mix(0.78, 1.0, vig);
  col = col / (1.0 + col * 0.12);
  fragColor = vec4(col, 1.0);
}
