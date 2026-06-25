shader_type canvas_item;

uniform sampler2D noise_tex1 : repeat_enable, filter_linear_mipmap;

// Telegraph Colors
uniform vec3 energy_color : source_color = vec3(1.0, 0.0, 0.0); // Pure charging red
uniform vec3 core_light : source_color = vec3(1.0, 0.85, 0.85); // White-hot center

// Animatable parameters via AnimationPlayer
uniform float charge_progress : hint_range(0.0, 1.0) = 0.0;
uniform float flicker_speed = 15.0;

// Swirl Settings
uniform float swirl_speed = 4.0;
uniform float swirl_density = 3.0; // Higher values mean more tightly wrapped spirals

void fragment() {
    // 1. Center the UV coordinates to make a perfect circle math space
    vec2 center_uv = UV - vec2(0.5);
    float distance_from_center = length(center_uv);
    float angle = atan(center_uv.y, center_uv.x);
    
    // 2. Create the polar wrapping that curls inwards like a vortex
    // Adding the distance to the angle creates a spiral / swirl deformation
    float spiral_factor = angle + (distance_from_center * swirl_density);
    
    // Sample the same noise texture twice moving in offset speeds and directions
    vec2 swirl_uv1 = vec2(spiral_factor / (2.0 * 3.14159) + TIME * (swirl_speed * 0.1), distance_from_center - TIME * 0.2);
    vec2 swirl_uv2 = vec2(spiral_factor / (2.0 * 3.14159) - TIME * (swirl_speed * 0.15), distance_from_center - TIME * 0.4);
    
    float n1 = texture(noise_tex1, swirl_uv1).r;
    float n2 = texture(noise_tex1, swirl_uv2).r; // Changed noise_tex2 to noise_tex1
    float combined_noise = (n1 + n2) * 0.5;
    
    // 3. Dynamically grow the laser ball based on charge progress
    float target_radius = mix(0.1, 0.46, charge_progress);
    
    // Use the swirling noise to aggressively deform the shape lines
    float dynamic_radius = target_radius + (combined_noise - 0.5) * 0.25 * charge_progress;
    
    // Create the central glowing shape and chaotic outer plasma fringes
    float core_shape = smoothstep(dynamic_radius, 0.0, distance_from_center);
    float plasma_fringe = smoothstep(dynamic_radius + 0.05, dynamic_radius - 0.05, distance_from_center);
    
    // 4. Critical phase high-frequency flicker
    float sudden_flicker = sin(TIME * flicker_speed) * cos(TIME * (flicker_speed * 1.4));
    float active_flicker = mix(1.0, step(0.0, sudden_flicker), smoothstep(0.7, 1.0, charge_progress) * 0.6);
    
    // 5. Build up the color levels based on density
    float intensity = core_shape * (combined_noise + 0.5);
    vec3 final_rgb = mix(energy_color, core_light, smoothstep(0.2, 0.7, intensity * charge_progress));
    
    // 6. Output final composite alpha
    COLOR.rgb = final_rgb;
    
    // Clean mechanical circular hard mask cutoff
    float bounds_cutoff = smoothstep(0.49, 0.46, distance_from_center);
    
    COLOR.a = plasma_fringe * active_flicker * bounds_cutoff * mix(0.3, 1.0, charge_progress);
}