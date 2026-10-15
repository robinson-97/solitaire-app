#version 460 core
#include <flutter/runtime_effect.glsl>

// Studio lighting laid over a peg's artwork. Pass 0 is multiplied in (shadow
// side, ambient occlusion); pass 1 is added on top (reflections, highlights).
uniform vec2 uSize;
uniform float uPass;
uniform float uShine;

out vec4 fragColor;

vec3 env(vec3 r) {
  r = normalize(r);
  float h = r.y * 0.5 + 0.5;
  vec3 col = mix(vec3(0.08, 0.09, 0.16), vec3(0.62, 0.74, 0.95), h);
  col += vec3(1.0, 0.95, 0.85) * smoothstep(0.80, 0.97, dot(r, normalize(vec3(-0.5, 0.75, 0.45)))) * 1.7;
  col += vec3(0.55, 0.72, 1.0) * smoothstep(0.82, 0.98, dot(r, normalize(vec3(0.85, 0.15, 0.4)))) * 0.9;
  col += vec3(0.55, 0.38, 0.22) * smoothstep(0.0, -0.9, r.y) * 0.4;
  return col;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize * 2.0 - 1.0;
  float dist = length(uv);
  if (dist > 1.0) {
    fragColor = vec4(0.0);
    return;
  }
  float edge = smoothstep(1.0, 0.955, dist);
  float z = sqrt(1.0 - dot(uv, uv));
  vec3 n = vec3(uv.x, -uv.y, z);
  vec3 v = vec3(0.0, 0.0, 1.0);
  vec3 L = normalize(vec3(-0.45, 0.65, 0.6));
  vec3 H = normalize(L + v);
  float wrap = clamp((dot(n, L) + 0.45) / 1.45, 0.0, 1.0);
  float fres = pow(1.0 - z, 3.0);

  if (uPass < 0.5) {
    float shade = mix(0.62, 1.06, wrap);
    shade *= 0.86 + 0.14 * smoothstep(-0.2, 0.9, n.y + 0.35);
    vec3 tint = mix(vec3(0.86, 0.90, 1.0), vec3(1.0), wrap);
    fragColor = vec4(tint * shade * edge, edge);
  } else {
    vec3 e = env(reflect(-v, n));
    float specTight = pow(max(dot(n, H), 0.0), 80.0);
    float specSoft = pow(max(dot(n, H), 0.0), 16.0);
    vec3 light = e * (0.06 + 0.55 * fres) * uShine;
    light += vec3(1.0, 0.98, 0.94) * specTight * (0.35 + 0.9 * uShine);
    light += vec3(1.0) * specSoft * 0.08;
    light += vec3(0.5, 0.65, 1.0) * pow(1.0 - z, 4.0) * 0.12;
    fragColor = vec4(light * edge, edge);
  }
}
