// Трава и листва, колышущиеся на ветру (вершинная анимация, без текстур).
shader_type spatial;
render_mode cull_disabled;

uniform float wind_strength = 0.28;
uniform float wind_speed = 2.0;
varying vec4 inst_col;
varying float tip;

void vertex() {
    inst_col = COLOR;
    tip = clamp(VERTEX.y + 0.5, 0.0, 1.0);
    vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    float w = sin(TIME * wind_speed + wp.x * 0.6 + wp.z * 0.45);
    VERTEX.x += w * wind_strength * tip;
    VERTEX.z += cos(TIME * wind_speed * 0.8 + wp.x * 0.3) * wind_strength * 0.5 * tip;
}

void fragment() {
    ALBEDO = inst_col.rgb * mix(0.55, 1.15, tip);
    ROUGHNESS = 0.9;
}
