shader_type canvas_item;

// Control colors and glow intensity from the Inspector
uniform vec4 star_color : source_color = vec4(0.53, 0.81, 0.94, 1.0); // Light blue
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.0;
uniform float rotation_speed : hint_range(-10.0, 10.0) = 2.0; // Positive is counter-clockwise

// Explosion Controls (Animate progress from 0.0 to 1.0)
uniform float explosion_progress : hint_range(0.0, 1.0) = 0.0;
uniform float expansion_power : hint_range(1.0, 10.0) = 5.0;

void fragment() {
    // Center the texture coordinates around (0.0, 0.0)
    vec2 uv = UV - 0.5;
    
    // 1. ANIMATE SCALE: Star expands rapidly as explosion progresses
    float scale = 1.0 + explosion_progress * expansion_power;
    uv /= scale;
    
    // Calculate rotation angle based on time
    float angle = TIME * rotation_speed;
    float sin_b = sin(angle);
    float cos_b = cos(angle);
    
    // Rotate the coordinates
    vec2 rotated_uv = vec2(
        uv.x * cos_b - uv.y * sin_b,
        uv.x * sin_b + uv.y * cos_b
    );
    
    // Calculate the mathematical distance for a 4-pointed star (astroid shape)
    float x_abs = abs(rotated_uv.x);
    float y_abs = abs(rotated_uv.y);
    
    // 2. ANIMATE DISTORTION: Star points turn into thin shockwave lines during explosion
    float shape_morph = mix(0.5, 0.2, explosion_progress);
    float star_dist = pow(x_abs, shape_morph) + pow(y_abs, shape_morph);
    
    // Define the sharp boundary of the star
    float star_edge = 0.5;
    
    // 3. ANIMATE CORE HOLLOWING: The center fades out to create a ring/shockwave effect
    float core_hollow = smoothstep(0.0, star_edge * explosion_progress, star_dist);
    float star_mask = smoothstep(star_edge, star_edge - 0.02, star_dist) * core_hollow;
    
    // Create a smooth outer glow based on distance from the star shape
    // Glow intensifies then spikes down during explosion
    float current_glow = glow_intensity * mix(1.0, 3.0, explosion_progress);
    float glow = exp(-5.0 * max(0.0, star_dist - star_edge + 0.1)) * current_glow;
    
    // Combine the solid star color and the emitting glow
    vec4 final_color = star_color * (star_mask + glow);
    
    // 4. ANIMATE FADE OUT: Entire effect vanishes completely at progress = 1.0
    float lifetime_fade = 1.0 - explosion_progress;
    
    // Ensure the alpha matches the mask intensity so it transparently fades out
    final_color.a = clamp(star_mask + (glow * 0.5), 0.0, 1.0) * star_color.a * lifetime_fade;
    
    COLOR = final_color;
}
