shader_type canvas_item;

uniform float speed : hint_range(0.1, 10.0) = 3.0;
uniform float noise_strength : hint_range(0.0, 0.5) = 0.08;
uniform float trail_length : hint_range(0.0, 1.0) = 0.6;
uniform vec4 core_color : source_color = vec4(0.4, 1.0, 0.95, 1.0);
uniform vec4 edge_color : source_color = vec4(0.0, 0.6, 0.8, 0.0);

// Simple hash noise
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(dot(hash(i + vec2(0,0)), f - vec2(0,0)),
            dot(hash(i + vec2(1,0)), f - vec2(1,0)), u.x),
        mix(dot(hash(i + vec2(0,1)), f - vec2(0,1)),
            dot(hash(i + vec2(1,1)), f - vec2(1,1)), u.x), u.y);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    float t = TIME * speed;

    // Layered noise for organic feel
    float n = noise(UV * 4.0 + vec2(t, 0.0)) * 0.6;
	n += noise(UV * 8.0 + vec2(t * 1.3, t * 0.4)) * 0.3;
	n += noise(UV * 16.0 + vec2(t * 0.7, -t * 0.6)) * 0.1;

    // Trail fade: left side fades out
    float trail_fade = smoothstep(0.0, trail_length, UV.x);

    // Edge glow flicker from noise
    float edge = smoothstep(0.3, 0.7, UV.y) * (1.0 - smoothstep(0.3, 0.7, UV.y));
    float flicker = 1.0 + n * noise_strength * (1.0 - UV.x);

    vec4 final_color = mix(edge_color, core_color, trail_fade * flicker);
    final_color.a = tex.a * trail_fade * (1.0 + n * noise_strength);
    final_color.a = clamp(final_color.a, 0.0, 1.0);

    COLOR = final_color;
}