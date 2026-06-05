shader_type canvas_item;

uniform sampler2D noise_tex1 : repeat_enable;
uniform sampler2D noise_tex2 : repeat_enable;
uniform vec3 core_color : source_color = vec3(1.0, 1.0, 0.9);
uniform vec3 mid_color : source_color = vec3(1.0, 0.5, 0.0);
uniform vec3 outer_color : source_color = vec3(0.8, 0.1, 0.0);
uniform vec3 smoke_color : source_color = vec3(0.15, 0.15, 0.15);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale = 1.2;

float soft_light(float base, float blend) {
    float limit = step(0.5, blend);
    return mix(
        2.0 * base * blend + base * base * (1.0 - 2.0 * blend),
        sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend),
        limit
    );
}

float ring(float dist, float radius, float thickness, float noise_offset) {
    return 1.0 - smoothstep(0.0, thickness, abs(dist - radius + noise_offset));
}

// Fake sparks using noise
float sparks(vec2 uv, float prog, float seed) {
    vec2 dir = uv - vec2(0.5);
    float angle = atan(dir.y, dir.x);
    float dist = length(dir);
    float spark_noise = texture(noise_tex1, vec2(angle * 0.3 + seed, prog * 0.5)).r;
    float spark_dist = prog * 0.55 * (0.8 + spark_noise * 0.4);
    float spark = 1.0 - smoothstep(0.0, 0.03, abs(dist - spark_dist));
    spark *= smoothstep(0.0, 0.2, prog) * (1.0 - smoothstep(0.5, 1.0, prog));
    spark *= step(0.65, spark_noise); // only some directions get sparks
    return spark;
}

void fragment() {
    vec2 centered = UV - vec2(0.5);
    float dist = length(centered);

    float noise1 = texture(noise_tex1, UV * noise_scale + vec2(TIME * 0.2)).r;
    float noise2 = texture(noise_tex2, UV * noise_scale - vec2(TIME * 0.15)).r;
    float noise = soft_light(noise1, noise2);
    float noise_offset = (noise - 0.5) * 0.12;

    // --- Multiple shockwave rings ---
    float ring1 = ring(dist, progress * 0.55, 0.04 + progress * 0.02, noise_offset);
    float ring2 = ring(dist, progress * 0.45 - 0.05, 0.03, noise_offset * 0.8);
    float ring3 = ring(dist, progress * 0.3, 0.025, noise_offset * 0.5);
    ring2 *= smoothstep(0.15, 0.05, progress); // ring2 fades early
    ring3 *= smoothstep(0.1, 0.0, progress);   // ring3 only at start

    // --- Fireball body ---
    float fireball_radius = progress * 0.45;
    float fireball = 1.0 - smoothstep(fireball_radius * 0.5, fireball_radius, dist + noise_offset * 0.5);
    fireball *= smoothstep(0.6, 0.2, progress); // shrinks and fades

    // --- Core flash ---
    float core = smoothstep(0.35, 0.0, dist) * smoothstep(0.0, 0.1, 1.0 - progress);
    core *= smoothstep(0.25, 0.0, progress); // very brief

    // --- Smoke ---
    float smoke_radius = progress * 0.6;
    float smoke = 1.0 - smoothstep(smoke_radius * 0.4, smoke_radius, dist);
    smoke *= noise * smoothstep(0.3, 0.8, progress); // smoke appears late

    // --- Sparks ---
    float spark1 = sparks(UV, progress, 0.0);
    float spark2 = sparks(UV, progress, 0.3);
    float spark3 = sparks(UV, progress, 0.6);
    float all_sparks = clamp(spark1 + spark2 + spark3, 0.0, 1.0);

    // --- Color ---
    vec3 color = core_color;
    color = mix(color, mid_color, smoothstep(0.0, 0.25, dist));
    color = mix(color, outer_color, smoothstep(0.2, 0.45, dist));
    color = mix(color, smoke_color, smoothstep(0.3, 0.7, progress) * smoke);
    color = mix(color, core_color, all_sparks); // sparks are bright

    // --- Alpha ---
    float alpha = clamp(ring1 + ring2 + ring3 + fireball + core + all_sparks + smoke * 0.6, 0.0, 1.0);
    alpha *= 1.0 - smoothstep(0.75, 1.0, progress); // global fade out

    COLOR = vec4(color, alpha);
}