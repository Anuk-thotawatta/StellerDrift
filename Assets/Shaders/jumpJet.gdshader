shader_type canvas_item;

uniform sampler2D noise_tex1: repeat_enable;
uniform sampler2D noise_tex2: repeat_enable;
uniform vec3 core_color: source_color = vec3(1.0, 0.95, 0.6);
uniform vec3 mid_color: source_color = vec3(1.0, 0.5, 0.2);
uniform vec3 tail_color: source_color = vec3(0.7, 0.3, 0.6);
uniform vec3 smoke_color: source_color = vec3(0.5, 0.4, 0.7);
uniform float effect_speed = 3.0;
uniform float flame_height = 1.0;
uniform float burst_progress: hint_range(0.0, 1.0) = 0.0;

float soft_light(float base, float blend) {
    float limit = step(0.5, blend);
    return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
               sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

float get_noise(vec2 uv, float speed_mult) {
    float noise1 = texture(noise_tex1, vec2(uv.x + TIME * effect_speed * speed_mult, uv.y * 2.0)).r;
    float noise2 = texture(noise_tex2, vec2(uv.x + TIME * effect_speed * speed_mult * 0.7, uv.y * 2.0 + 0.5)).r;
    return soft_light(noise1, noise2);
}

void fragment() {
    vec2 uv = UV;

    float burst_intensity = 1.0 - abs(burst_progress - 0.5) * 2.0;
    burst_intensity = smoothstep(0.0, 1.0, burst_intensity);

    float current_flame_height = flame_height * (0.2 + burst_intensity * 0.8);
    float current_flame_width = 0.45 * (0.3 + burst_intensity * 0.7);

    float noise_coarse = get_noise(uv, 1.0);
    float noise_fine = get_noise(uv * 2.5, 1.8);
    float noise = noise_coarse * 0.6 + noise_fine * 0.4;

    float turbulence = noise * (0.5 + burst_intensity * 0.8);

    float cone_half_width = (uv.x * current_flame_width + 0.02) * current_flame_height;
    float dist_from_center = abs(uv.y - 0.5);

    // Much softer edge — wide smoothstep range + noise barely touches it
    float edge_noise = (turbulence - 0.5) * 0.06;
    float cone_hard = smoothstep(cone_half_width + edge_noise + 0.18, cone_half_width - 0.02 + edge_noise, dist_from_center);

    // Soft feathered falloff blended heavily with the hard cone
    float cone_soft = 1.0 - smoothstep(cone_half_width - 0.12, cone_half_width + 0.22, dist_from_center);
    float cone = mix(cone_hard, cone_soft, 0.7);

    // Extra gaussian-like radial softness from center axis
    float radial_soft = exp(-dist_from_center * dist_from_center * 18.0);
    cone = max(cone, radial_soft * 0.3 * burst_intensity);

    // Shock diamonds
    float shock_diamonds = 0.0;
    if (uv.x > 0.2 && uv.x < 0.8) {
        float diamond_pos = fract(uv.x * 4.0 - TIME * 2.5);
        shock_diamonds = sin(uv.x * 15.0) * 0.2 * (1.0 - abs(diamond_pos - 0.5) * 2.0);
        shock_diamonds *= smoothstep(0.2, 0.6, uv.x) * smoothstep(0.8, 0.6, uv.x);
        shock_diamonds *= burst_intensity;
        shock_diamonds = pow(max(shock_diamonds, 0.0), 0.8);
    }

    float edge_turbulence = noise_fine * smoothstep(0.2, 0.9, dist_from_center) * burst_intensity;

    // Very soft tail fade
    float tail_wisp = smoothstep(0.0, 0.6, uv.x) * (noise_coarse * 0.4 + 0.6);
    float tail_fade = mix(tail_wisp, 1.0, smoothstep(0.0, 0.5, uv.x));

    // Softer nozzle cap
    float nozzle_cap = smoothstep(1.0, 0.75, uv.x);

    float shape = cone * tail_fade * nozzle_cap;
    shape *= (0.15 + burst_intensity * 0.85);

    // Soft gamma to avoid hard cutoffs
    shape = pow(shape, 0.75);

    float brightness = 0.5 + burst_intensity * 0.8 + turbulence * 0.3;

    vec3 color = core_color * brightness;
    color = mix(color, mid_color, smoothstep(0.85, 0.35, uv.x) * (1.0 - burst_intensity * 0.3));
    color = mix(color, tail_color, smoothstep(0.5, 0.1, uv.x) * (1.0 - burst_intensity * 0.5));
    color = mix(color, smoke_color, smoothstep(0.25, 0.0, uv.x) * noise_coarse * (1.0 - burst_intensity * 0.3));

    color += vec3(0.8, 0.5, 0.2) * shock_diamonds * burst_intensity * 0.6;
    color += core_color * edge_turbulence * 0.2;

    float streaks = smoothstep(0.3, 0.85, noise_fine) * smoothstep(0.2, 0.85, uv.x) * burst_intensity;
    color = mix(color, core_color * 1.2, streaks * 0.3);

    float glow = smoothstep(0.3, 0.0, dist_from_center) * smoothstep(0.3, 0.95, uv.x);
    color = mix(color, vec3(1.0, 1.0, 0.9), glow * 0.5 * burst_intensity);

    float outer_glow = smoothstep(0.1, 0.55, dist_from_center) * smoothstep(0.7, 0.15, uv.x);
    color += vec3(0.6, 0.3, 0.15) * outer_glow * burst_intensity * 0.3;

    float volumetric = pow(max(1.0 - dist_from_center * 1.5, 0.0), 2.0) * smoothstep(0.0, 0.7, uv.x) * burst_intensity * 0.4;
    color += vec3(0.4, 0.2, 0.1) * volumetric;

    color = pow(max(color, vec3(0.0)), vec3(0.95));

    COLOR.rgb = color;
    float visibility = smoothstep(0.0, 0.15, burst_progress) * smoothstep(1.0, 0.85, burst_progress);
	COLOR.a = shape * visibility;
}