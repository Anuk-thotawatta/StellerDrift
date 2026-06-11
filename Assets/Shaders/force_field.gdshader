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

// NEW: Animation Controls
uniform float appearance_progress : hint_range(0.0, 1.0) = 1.0;
uniform float explosion_progress : hint_range(0.0, 1.0) = 0.0;

// Hexagon mathematical grid helper
vec4 hexagon_grid(vec2 uv, float explode) {
    vec2 r = vec2(1.0, sqrt(3.0));
    vec2 h = r / 2.0;
    
    // 1. Calculate unique IDs for the overlapping grids to target individual cells
    vec2 id1 = floor(uv / r);
    vec2 id2 = floor((uv - h) / r);
    
    vec2 a = mod(uv, r) - h;
    vec2 b = mod(uv - h, r) - h;
    
    // Pick the closest cell center
    bool is_a = dot(a, a) < dot(b, b);
    vec2 gv = is_a ? a : b;
    vec2 cell_id = is_a ? id1 : id2;
    
    // 2. Generate a pseudo-random direction vector based on the cell ID
    // This gives each individual shard its own unique flying angle and rotation
    float random_angle = fract(sin(dot(cell_id, vec2(127.1, 311.7))) * 43758.5453) * 6.2831;
    vec2 shatter_dir = vec2(cos(random_angle), sin(random_angle));
    
    // 3. Offset the internal coordinates of the cell to make them explode outward rigidly
    gv -= shatter_dir * explode * 1.5;
    
    // Calculate distance to the edge of the hexagon
    float x = abs(gv.x);
    float y = abs(gv.y);
    float d = max(x, dot(vec2(x, y), normalize(r)));
    
    // Shrink individual cells during explosion to simulate disintegration
    d += explode * 0.4;
    
    return vec4(gv, d, 0.0);
}

void fragment() {
    // Center the UV coordinates to make a perfect circle (-0.5 to 0.5)
    vec2 center_uv = UV - vec2(0.5);
    float dist_from_center = length(center_uv);
    
    // Create the circular mask for the forcefield
    // Modified to use appearance_progress for the growing effect
    float current_radius = 0.5 * appearance_progress;
    float circle_mask = smoothstep(current_radius, current_radius * 0.7, dist_from_center);
    
    // Prevent rendering outside the max boundary during appearance scale
    circle_mask *= step(dist_from_center, current_radius);
    
    // Dynamic pulsing effect over time
    float pulse = sin(TIME * pulse_speed) * 0.05 + 0.95;
    
    // Animate and scale UVs for the honeycomb pattern
    // Blended global expansion with cell-shattering for maximum chaotic impact
    vec2 global_expansion = normalize(center_uv) * explosion_progress * 1.5;
    vec2 animated_uv = UV * hex_scale + (scroll_speed * TIME) - global_expansion;
    
    // Get hexagon grid data (passing explosion progress)
    vec4 hex = hexagon_grid(animated_uv, explosion_progress);
    float hex_dist = hex.z; 
    
    // Isolate the honeycomb lines
    // Fade out lines during explosion
    float current_thickness = line_thickness * (1.0 - explosion_progress);
    float lines = smoothstep(0.5 - current_thickness, 0.5, hex_dist);
    
    // Create an inner glow that intensifies near the edges of the circle
    // The glow cracks open along with the explosion progress
    float edge_glow = smoothstep(0.2, 0.5, dist_from_center) * 0.5 * (1.0 - explosion_progress);
    
    // Combine the base texture, lines, and glow
    vec4 final_color = mix(shield_color, glow_color, lines + edge_glow);
    
    // Apply the circle mask, pulse, and fade out completely at peak explosion
    final_color.a *= circle_mask * pulse * (1.0 - explosion_progress);
    
    COLOR = final_color;
}
