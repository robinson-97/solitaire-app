#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uMode;
uniform vec3 uC1;
uniform vec3 uC2;
uniform vec3 uC3;

out vec4 fragColor;

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
  for (int i = 0; i < 5; i++) {
    v += a * noise(p);
    p *= 2.03;
    a *= 0.5;
  }
  return v;
}

// A small photo-studio: sky gradient, a big softbox top-left, a cool rim light.
vec3 env(vec3 r) {
  r = normalize(r);
  float h = r.y * 0.5 + 0.5;
  vec3 col = mix(vec3(0.08, 0.09, 0.16), vec3(0.62, 0.74, 0.95), h);
  col += vec3(1.0, 0.95, 0.85) * smoothstep(0.80, 0.97, dot(r, normalize(vec3(-0.5, 0.75, 0.45)))) * 1.7;
  col += vec3(0.55, 0.72, 1.0) * smoothstep(0.82, 0.98, dot(r, normalize(vec3(0.85, 0.15, 0.4)))) * 0.9;
  col += vec3(0.55, 0.38, 0.22) * smoothstep(0.0, -0.9, r.y) * 0.45;
  return col;
}

vec3 icoVert(int i) {
  float t = 1.6180339;
  vec3 v = vec3(0.0);
  if (i == 0) v = vec3(-1.0, t, 0.0);
  else if (i == 1) v = vec3(1.0, t, 0.0);
  else if (i == 2) v = vec3(-1.0, -t, 0.0);
  else if (i == 3) v = vec3(1.0, -t, 0.0);
  else if (i == 4) v = vec3(0.0, -1.0, t);
  else if (i == 5) v = vec3(0.0, 1.0, t);
  else if (i == 6) v = vec3(0.0, -1.0, -t);
  else if (i == 7) v = vec3(0.0, 1.0, -t);
  else if (i == 8) v = vec3(t, 0.0, -1.0);
  else if (i == 9) v = vec3(t, 0.0, 1.0);
  else if (i == 10) v = vec3(-t, 0.0, -1.0);
  else v = vec3(-t, 0.0, 1.0);
  return normalize(v);
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize * 2.0 - 1.0;
  float r2 = dot(uv, uv);
  float dist = sqrt(r2);
  if (dist > 1.0) {
    fragColor = vec4(0.0);
    return;
  }
  float edge = smoothstep(1.0, 0.955, dist);
  float z = sqrt(1.0 - r2);
  vec3 n = vec3(uv.x, -uv.y, z);
  vec3 v = vec3(0.0, 0.0, 1.0);
  vec3 L = normalize(vec3(-0.45, 0.65, 0.6));
  vec3 H = normalize(L + v);
  float ndl = max(dot(n, L), 0.0);
  float wrap = clamp((dot(n, L) + 0.35) / 1.35, 0.0, 1.0);
  float fres = pow(1.0 - max(dot(n, v), 0.0), 3.0);
  vec3 refl = reflect(-v, n);
  vec3 e = env(refl);
  float specTight = pow(max(dot(n, H), 0.0), 90.0);
  float specSoft = pow(max(dot(n, H), 0.0), 18.0);
  float ao = 0.55 + 0.45 * smoothstep(-0.2, 0.9, n.y + 0.35);

  vec3 col;
  float alpha = 1.0;

  if (uMode < 0.5) {
    // polished marble
    vec2 q = uv * 2.2;
    float w = fbm(q * 1.4 + fbm(q * 2.0) * 2.2);
    float vein = smoothstep(0.015, 0.0, abs(w - 0.5) - 0.012) + 0.5 * smoothstep(0.05, 0.0, abs(fbm(q * 3.0 + 4.0) - 0.5) - 0.01);
    vec3 base = mix(uC1, uC2, clamp(w * 1.1, 0.0, 1.0));
    base = mix(base, uC3, clamp(vein, 0.0, 1.0) * 0.8);
    col = base * (0.30 + 0.80 * wrap) * ao + e * (0.10 + 0.35 * fres) + vec3(1.0) * specTight * 0.9 + vec3(1.0) * specSoft * 0.12;
  } else if (uMode < 1.5) {
    // glass with a glowing core
    float core = pow(z, 2.2);
    vec3 inner = uC1 * core * (0.55 + 0.25 * sin(uTime * 2.0));
    col = uC2 * 0.35 + inner + e * (0.28 + 0.9 * fres) + vec3(1.0) * specTight * 1.3 + vec3(1.0) * specSoft * 0.15;
    float caustic = smoothstep(0.55, 0.0, length(uv - vec2(0.28, -0.32) * -1.0 * vec2(-1.0, 1.0)));
    col += uC1 * caustic * 0.18;
    alpha = 0.97;
  } else if (uMode < 2.5) {
    // brushed metal
    float brush = fbm(vec2(uv.x * 40.0, uv.y * 3.0)) * 0.15;
    vec3 tint = mix(uC2, uC1, clamp(n.y * 0.5 + 0.55, 0.0, 1.0));
    col = tint * (e * 1.6 + brush) * (0.65 + 0.7 * wrap) + vec3(1.0, 0.97, 0.88) * specTight * 1.4;
  } else if (uMode < 3.5) {
    // lava crust with glowing cracks
    vec2 q = uv * 3.4;
    float c = fbm(q + vec2(uTime * 0.05, 0.0));
    float crack = smoothstep(0.07, 0.0, abs(c - 0.5));
    float crack2 = smoothstep(0.05, 0.0, abs(fbm(q * 1.9 + 7.0) - 0.5));
    float heat = clamp(crack + crack2 * 0.7, 0.0, 1.0);
    float flick = 0.85 + 0.15 * sin(uTime * 3.0 + c * 12.0);
    vec3 crust = uC3 * (0.30 + 0.75 * wrap) + e * 0.05;
    col = mix(crust, uC1 * 1.8 * flick, heat) + uC2 * pow(1.0 - z, 2.0) * 0.5 + vec3(1.0) * specSoft * 0.1;
  } else if (uMode < 4.5) {
    // faceted crystal: snap the normal to the nearest of 12 icosahedron directions
    vec3 best = vec3(0.0, 0.0, 1.0);
    float bd = -2.0;
    for (int i = 0; i < 12; i++) {
      vec3 c = icoVert(i);
      float d = dot(n, c);
      if (d > bd) {
        bd = d;
        best = c;
      }
    }
    vec3 n2 = normalize(mix(n, best, 0.82));
    float d2 = max(dot(n2, L), 0.0);
    vec3 rv = reflect(-v, n2);
    float seam = smoothstep(0.0, 0.07, bd - dot(n, n2));
    col = uC2 * (0.22 + 1.0 * d2) + env(rv) * (0.32 + 0.5 * fres) + uC1 * 0.3 * pow(z, 2.0) + vec3(1.0) * pow(max(dot(n2, H), 0.0), 36.0) * 1.2;
    col = mix(col * 1.35, col, seam);
  } else if (uMode < 5.5) {
    // satin wood
    vec2 p = uv * vec2(1.0, 1.9);
    float d = length(p * vec2(1.0, 1.0) + vec2(0.55, -0.35));
    float rings = sin(d * 26.0 + fbm(uv * 4.0) * 4.0) * 0.5 + 0.5;
    vec3 base = mix(uC2, uC3, rings * 0.65);
    col = base * (0.28 + 0.85 * wrap) * ao + e * 0.08 + vec3(1.0, 0.9, 0.75) * specSoft * 0.28 + vec3(1.0) * specTight * 0.25;
  } else {
    // pearl with colour shift
    vec3 irid = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + fres * 1.6 + n.y * 0.25 + uTime * 0.02));
    vec3 base = mix(uC1, irid, 0.42 + 0.4 * fres);
    col = base * (0.45 + 0.7 * wrap) * ao + e * 0.30 + vec3(1.0) * specTight * 1.0;
  }

  col = col / (1.0 + col * 0.18);
  col = pow(col, vec3(0.92));
  fragColor = vec4(col * alpha * edge, alpha * edge);
}
