shader_type canvas_item;

// Control the color and overall transparency
uniform vec4 shield_color : source_color = vec4(0.0, 0.7, 1.0, 0.6);
uniform vec4 glow_color : source_color = vec4(0.5, 0.9, 1.0, 1.0);

// Hexagon adjustments
uniform vec2 hex_scale = vec2(15.0, 15.0);
uniform float line_thickness : hint_range(0.0, 0.2) = 0.05;

// Animation speeds
uniform vec2 scroll_speed = vec2(0.05, 0.02);
uniform float pulse_speed = 2.0;

// Hexagon mathematical grid helper (Cleaned up from explosion offsets)
vec4 hexagon_grid(vec2 uv) {
    vec2 r = vec2(1.0, sqrt(3.0));
    vec2 h = r / 2.0;
    
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    
    bool is_a = dot(a, a) < dot(b, b);
    vec2 gv = is_a ? a : b;
    
    float x = abs(gv.x);
    float y = abs(gv.y);
    float d = max(x, dot(vec2(x, y), normalize(r)));
    
    return vec4(gv, d, 0.0);
}

void fragment() {
    // Center the UV coordinates to make a perfect circle (-0.5 to 0.5)
    vec2 center_uv = UV - vec2(0.5);
    float dist_from_center = length(center_uv);
    
    // Create the clean, constant circular mask for the forcefield
    float circle_mask = smoothstep(0.5, 0.35, dist_from_center);
    circle_mask *= step(dist_from_center, 0.5);
    
    // Dynamic background pulsing effect over time
    float pulse = sin(TIME * pulse_speed) * 0.05 + 0.95;
    
    // Animate and scale UVs for the constant honeycomb scroll pattern
    vec2 animated_uv = UV * hex_scale + (scroll_speed * TIME);
    
    // Get hexagon grid data
    vec4 hex = hexagon_grid(animated_uv);
    float hex_dist = hex.z; 
    
    // Isolate the honeycomb lines consistently
    float lines = smoothstep(0.5 - line_thickness, 0.5, hex_dist);
    
    // Create an inner glow that intensifies near the edges of the circle
    float edge_glow = smoothstep(0.2, 0.5, dist_from_center) * 0.5;
    
    // Combine the base texture, lines, and glow constants
    vec4 final_color = mix(shield_color, glow_color, lines + edge_glow);
    
    // Apply the circle mask and passive pulse
    final_color.a *= circle_mask * pulse;
    
    COLOR = final_color;
}
