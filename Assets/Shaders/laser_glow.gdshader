shader_type canvas_item;

// Exposed parameters to style the flare
uniform vec4 flare_color : source_color = vec4(1.0, 0.1, 0.1, 1.0); // Intense Red
uniform float core_brightness : hint_range(0.1, 5.0) = 1.5;
uniform float horizontal_streak_thickness : hint_range(0.01, 0.2) = 0.02;
uniform float vertical_spike_thickness : hint_range(0.01, 0.2) = 0.04;
uniform float core_size : hint_range(0.01, 0.4) = 0.15;

// Pulse Parameters
uniform float pulse_speed : hint_range(0.1, 10.0) = 3.0;
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.4; // 0.0 is no pulse, 1.0 is max variation

void fragment() {
    // --- 0. Calculate Pulse Modifier ---
    // sin(TIME) returns -1.0 to 1.0. We map it to a 0.0 to 1.0 range.
    float pulse_wave = sin(TIME * pulse_speed) * 0.5 + 0.5;
    
    // Mix between 1.0 (no change) and a lower/higher value based on strength
    // This scales the entire intensity uniformly without breaking the drop-off thresholds
    float pulse_factor = mix(1.0 - pulse_strength, 1.0 + pulse_strength, pulse_wave);

    // Center UV coordinates to (-0.5, 0.5)
    vec2 uv = UV - vec2(0.5);
    
    // --- 1. The Core Diamond Shape ---
    // Using Manhattan distance (abs(x) + abs(y)) creates a perfect geometric diamond
    float diamond_dist = abs(uv.x) + abs(uv.y);
    float core = smoothstep(core_size, 0.0, diamond_dist) * core_brightness;
    
    // --- 2. Horizontal Anamorphic Streak ---
    // Smoothly falls off the further away from the horizontal center line (y = 0) it gets
    float horizontal_streak = horizontal_streak_thickness / (abs(uv.y) + 0.005);
    // Fade the streak toward the screen edges so it doesn't clip harshly at the borders
    horizontal_streak *= smoothstep(0.5, 0.0, abs(uv.x));
    
    // --- 3. Vertical Cross Spikes ---
    float vertical_streak = vertical_spike_thickness / (abs(uv.x) + 0.005);
    vertical_streak *= smoothstep(0.4, 0.0, abs(uv.y)); // Fade out vertically shorter
    
    // --- 4. Combining the Rays ---
    float light_beams = horizontal_streak + vertical_streak;
    
    // --- 5. Background Glow ---
    // A soft radial glow underneath to tie the spikes together
    float radial_glow = exp(-length(uv) * 6.0) * 0.4;
    
    // Total combined light maps multiplied by our pulse timing factor
    float final_intensity = (core + light_beams + radial_glow) * pulse_factor;
    
    // Output final composition
    vec3 mixed_color = flare_color.rgb * final_intensity;
    
    // Ensure areas with low light levels drop off cleanly to transparent
    COLOR = vec4(mixed_color, clamp(final_intensity, 0.0, 1.0));
}
