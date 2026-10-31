// Вода, лёд, лава: бегущие блики и лёгкие волны.
shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec4 water_color : source_color = vec4(0.1, 0.45, 0.8, 0.75);
uniform float flow_speed = 0.6;
uniform float glow = 0.0;
uniform float wave = 0.04;
uniform float stripes = 6.0;

void vertex() {
    VERTEX.y += sin(TIME * 1.5 + VERTEX.x * 0.8 + VERTEX.z * 0.6) * wave;
    UV = UV * vec2(1.0, stripes) + vec2(0.0, -TIME * flow_speed);
}

void fragment() {
    float g = sin(UV.y * 18.0 + sin(UV.x * 12.0) * 2.0) * 0.5 + 0.5;
    float sparkle = pow(g, 8.0);
    ALBEDO = water_color.rgb + vec3(0.28) * sparkle;
    EMISSION = water_color.rgb * glow * (0.6 + 0.4 * g);
    ALPHA = water_color.a;
    ROUGHNESS = 0.12;
    METALLIC = 0.25;
}
