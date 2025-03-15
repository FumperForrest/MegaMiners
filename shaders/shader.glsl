extern number time;           // Current time for pulsing effect
extern vec2 textureSize;      // Size of the texture in pixels

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Sample the current pixel color
    vec4 pixel = Texel(texture, texture_coords);

    // --- Ore Glow Effect ---
    // Calculate the size of one pixel in texture coordinates
    vec2 pixelSize = 1.0 / textureSize;
    number glowSize = 2.0;

    // Determine ore type and set glow color
    vec4 glowColor = vec4(0.0); // Default glow color (no glow)
    if (pixel.r > 0.5 && pixel.b > 0.5 && pixel.g < 0.5) {
        glowColor = vec4(0.5, 0.0, 0.5, 0.5); // Amethyst (purple)
    } else if (pixel.g > 0.5 && pixel.b < 0.5 && pixel.r < 0.5) {
        glowColor = vec4(0.0, 1.0, 0.0, 0.5); // Forrestite (green)
    }

    // Check neighboring pixels
    for (int i = 0; i < 4; i++) {
        vec2 offset = vec2(0.0);
        if (i == 0) {
            offset = vec2(glowSize * pixelSize.x, 0.0); // Right
        } else if (i == 1) {
            offset = vec2(0.0, glowSize * pixelSize.y); // Down
        } else if (i == 2) {
            offset = vec2(-glowSize * pixelSize.x, 0.0); // Left
        } else if (i == 3) {
            offset = vec2(0.0, -glowSize * pixelSize.y); // Up
        }

        vec4 neighbor = Texel(texture, texture_coords + offset);
        if (neighbor.r > 0.5 && neighbor.b > 0.5 && neighbor.g < 0.5) {
            glowColor = vec4(0.5, 0.0, 0.5, 0.2); // Amethyst (purple)
        } else if (neighbor.g > 0.5 && neighbor.b < 0.5 && neighbor.r < 0.5) {
            glowColor = vec4(0.0, 1.0, 0.0, 0.2); // Forrestite (green)
        }
    }

    // Pulsing effect for the glow
    float pulse = sin(time * 3.0) * 0.5 + 0.5; // Oscillates between 0 and 1
    float glowIntensity = 1.0 * pulse; // Apply pulsing to the glow intensity

    // Blend the glow color with the original pixel color
    vec4 finalColor = pixel; // Start with the original pixel color
    finalColor.rgb += glowIntensity * glowColor.rgb * glowColor.a; // Add glow with transparency
    finalColor.a = pixel.a; // Preserve the original pixel's alpha

    // --- Vignette Effect ---
    vec2 center = vec2(0.5, 0.5); // Center of the screen
    float dist = distance(texture_coords, center); // Distance from the center

    // Vignette intensity
    float vignette = smoothstep(0.3, 0.8, dist); // Smooth transition from center to edges

    // Mist effect (optional)
    float mist = sin(time * 1.5 + texture_coords.x * 10.0) * 0.1;
    mist += cos(time * 1.2 + texture_coords.y * 12.0) * 0.1;
    vignette = clamp(vignette + mist, 0.0, 1.0); // Combine vignette and mist

    // Apply vignette to the final color
    finalColor.rgb *= mix(vec3(1.0), vec3(0.5), vignette); // Darken edges

    // Return the final pixel color
    return finalColor * color;
}