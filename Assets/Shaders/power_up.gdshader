shader_type canvas_item;

// Control panel parameters for the Godot Inspector
uniform vec4 glow_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform float dispersion_width : hint_range(1.0, 10.0) = 6.0;  // Higher = wider, softer glow
uniform float glow_intensity : hint_range(0.0, 5.0) = 2.5;

uniform float float_speed : hint_range(0.0, 10.0) = 3.0;
uniform float float_amplitude : hint_range(0.0, 20.0) = 8.0;   // Overall bobbing height
uniform float wave_frequency : hint_range(0.0, 0.2) = 0.05;    // How many ripples ripple through
uniform float wave_speed : hint_range(0.0, 20.0) = 8.0;        // Velocity of distortion ripples
uniform float wave_amplitude : hint_range(0.0, 10.0) = 3.5;    // Shaking/distortion amount

void vertex() {
    // 1. Smooth Floating Translation
    VERTEX.y += sin(TIME * float_speed) * float_amplitude;
    
    // 2. Liquid/Plasma Edge Distortion
    // warps the vertices based on their coordinates over time to make it wiggle
    VERTEX.x += cos(VERTEX.y * wave_frequency + (TIME * wave_speed)) * wave_amplitude;
    VERTEX.y += sin(VERTEX.x * wave_frequency + (TIME * wave_speed)) * wave_amplitude;
}

void fragment() {
    // 3. Keep UV padded so the massive dispersed glow doesn't hit the screen boundaries
    vec2 padded_uv = (UV - vec2(0.5)) * 1.35 + vec2(0.5);
    
    // Safety check: clip pixels outside the frame bounds
    if (padded_uv.x < 0.0 || padded_uv.x > 1.0 || padded_uv.y < 0.0 || padded_uv.y > 1.0) {
        discard;
    }

    vec4 tex_color = texture(TEXTURE, padded_uv);
    
    // Clean up your black asset background pixels
    if (tex_color.r < 0.05 && tex_color.g < 0.05 && tex_color.b < 0.05) {
        tex_color = vec4(0.0);
    }

    // 4. Multi-Sample Box Blur Matrix for Maximum Dispersion
    float total_alpha = 0.0;
    float samples = 0.0;
    
    // Steps out radically from the shield core to generate a wider gradient fog
    for (float x = -3.0; x <= 3.0; x += 1.0) {
        for (float y = -3.0; y <= 3.0; y += 1.0) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE * dispersion_width;
            vec4 neighbor = texture(TEXTURE, padded_uv + offset);
            
            // Check if neighboring pixel is part of the shield graphic or background
            if (!(neighbor.r < 0.05 && neighbor.g < 0.05 && neighbor.b < 0.05)) {
                // Diminish energy the further it gets from the center core
                float distance_weight = 1.0 - (length(vec2(x, y)) / 4.25);
                total_alpha += neighbor.a * max(0.0, distance_weight);
            }
            samples += 1.0;
        }
    }
    
    // Isolate outer haze vector
    float blurred_alpha = total_alpha / samples;
    float glow_mask = clamp(blurred_alpha * 4.0, 0.0, 1.0) - tex_color.a;
    
    // Pulsate the dispersed aura softly
    float pulse = (sin(TIME * 2.0) * 0.2 + 0.8) * glow_intensity;
    vec4 final_glow = glow_color * glow_mask * pulse;

    // 5. Final Output Composite
    COLOR = mix(final_glow, tex_color, tex_color.a);
}
