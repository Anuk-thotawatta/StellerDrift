shader_type canvas_item;

// Controls the color of the flash (default is white)
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

// Controls how strong the flash is (0.0 = normal texture, 1.0 = solid color)
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // Get the original pixel color from the texture
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Mix the original color with the flash color based on the modifier strength
    vec3 mixed_color = mix(texture_color.rgb, flash_color.rgb, flash_modifier);
    
    // Keep the original transparency (alpha) channel so the shape doesn't change
    COLOR = vec4(mixed_color, texture_color.a);
}
