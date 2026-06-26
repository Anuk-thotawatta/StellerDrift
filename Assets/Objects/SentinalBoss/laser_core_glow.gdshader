shader_type canvas_item;

// Textures and Colors
uniform sampler2D noise_texture : repeat_enable, filter_linear;
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Pure white core
uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.1, 1.0); // Intense red/magenta glow

// Tuning Parameters
uniform float laser_speed = 4.0;             // How fast the noise cycles down the beam
uniform float core_thickness : hint_range(0.0, 1.0) = 0.15; // Width of the white core
uniform float glow_falloff : hint_range(0.1, 4.0) = 1.8;    // Higher = softer blending at edges
uniform float noise_strength : hint_range(0.0, 1.0) = 0.35; // How much the noise distorts the beam

void fragment() {
    // 1. Calculate standard top-to-bottom coordinates (0.0 at center, 1.0 at edges)
    float distance_from_center = abs(UV.y - 0.5) * 2.0;
    
    // 2. Sample the noise texture sliding horizontally over time
    vec2 noise_uv = vec2(UV.x - TIME * laser_speed, UV.y);
    float noise_val = texture(noise_texture, noise_uv).r;
    
    // 3. Inject the noise directly into our edge tracking calculation
    // This crinkles and distorts the shape of the laser dynamically
    float distorted_dist = distance_from_center + (noise_val - 0.5) * noise_strength;
    distorted_dist = clamp(distorted_dist, 0.0, 1.0);
    
    // 4. Create a beautifully soft falloff curve for the red glow gradient
    float glow_intensity = pow(1.0 - distorted_dist, glow_falloff);
    
    // 5. Create a sharp, intense cutoff mask for the inner white core
    float core_intensity = smoothstep(core_thickness + 0.05, core_thickness, distorted_dist);
    
    // 6. Blend colors together
    vec4 final_color = mix(glow_color * glow_intensity, core_color, core_intensity);
    
    // Smoothly fade out alpha values right at the absolute physical edge of the Line2D canvas
    final_color.a *= smoothstep(1.0, 0.7, distance_from_center);
    
    COLOR = final_color;
}