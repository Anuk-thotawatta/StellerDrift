shader_type canvas_item;

uniform vec4 laser_color : source_color = vec4(0.0, 0.4, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(0.8, 0.9, 1.0, 1.0);
uniform float flash_speed : hint_range(1.0, 20.0) = 8.0;
uniform float glow_intensity : hint_range(1.0, 5.0) = 2.5;

void fragment() {
    // UV.y goes from 0.0 at the top edge to 1.0 at the bottom edge of the line
    float distance_from_center = abs(UV.y - 0.5) * 2.0;
    
    // Create a sharp white core in the middle
    float core = smoothstep(0.2, 0.0, distance_from_center);
    
    // Create the outer blue glow aura
    float glow = pow(1.0 - distance_from_center, glow_intensity);
    
    // Add a moving noise texture effect along the length (UV.x)
    float wave = sin(UV.x * 20.0 - TIME * flash_speed) * 0.15 + 0.85;
    
    // Combine core, glow, and movement
    vec4 final_color = mix(laser_color * glow * wave, core_color, core);
    
    // Fade out beautifully at the tip of the trail
    final_color.a *= UV.x;
    
    COLOR = final_color;
}