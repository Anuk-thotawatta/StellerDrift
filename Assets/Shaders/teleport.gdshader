shader_type canvas_item;

uniform vec4 beam_color : source_color = vec4(0.3, 0.75, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.8, 0.95, 1.0, 1.0);

// 0.0 = completely hidden, 1.0 = full intense beam
uniform float teleport_progress : hint_range(0.0, 1.0) = 0.0;

// Fine-tune the look
uniform float ring_frequency = 25.0; // How many horizontal bands
uniform float noise_speed = 15.0;    // Speed of the energetic jitter

float pseudo_noise(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    // Center UV coordinates horizontally (-0.5 to 0.5)
    float centered_x = UV.x - 0.5;
    
    // --- 1. Vertical Light Beam Shape ---
    // Squeeze the beam horizontally depending on teleport progress (pinches shut as it leaves)
    float beam_width = 0.15 * (1.0 - (teleport_progress * 0.8));
    float beam_glow = exp(-abs(centered_x) / beam_width);
    
    // --- 2. Energetic Horizontal Scanning Rings (Like the reference image) ---
    // Stack horizontal lines moving over time with high-frequency noise jittering
    float ring_y = UV.y * ring_frequency - (TIME * noise_speed);
    float vertical_rings = step(0.4, fract(ring_y));
    
    // Inject pixel noise glitches to make the rings flicker organically
    float glitch = pseudo_noise(vec2(floor(UV.y * 40.0), floor(TIME * 24.0)));
    if (glitch > 0.7) {
        vertical_rings += 0.4;
    }
    
    // --- 3. Progress Animation Control ---
    // A clean vertical wipe mask that cuts the beam down or expands it up smoothly
    float vertical_mask = smoothstep(teleport_progress + 0.05, teleport_progress - 0.05, UV.y);
    
    // --- 4. Combining Layers ---
    // Mix the base blue glow with a bright white center core
    vec4 final_color = mix(beam_color, core_color, pow(beam_glow, 4.0));
    
    // Apply the ring slicing mask
    final_color.rgb *= (0.3 + vertical_rings * 0.7);
    
    // Intense energy flare frame right at the advancing tip of the teleport beam
    float edge_flare = smoothstep(teleport_progress - 0.02, teleport_progress, UV.y) * 
                       smoothstep(teleport_progress + 0.02, teleport_progress, UV.y);
    final_color.rgb += core_color.rgb * edge_flare * 3.0;
    
    // Master transparency control tied to progress
    final_color.a *= beam_glow * vertical_mask * (1.0 - step(0.99, teleport_progress));
    
    COLOR = final_color;
}
