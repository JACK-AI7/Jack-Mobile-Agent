#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec2 uSize;
uniform float uTime;
out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // Create a dynamic, wavy border mask
    float wave = sin(uv.x * 10.0 + uTime * 3.0) * 0.02 + sin(uv.y * 8.0 - uTime * 2.0) * 0.02;
    float border = smoothstep(0.0, 0.05 + wave, uv.x) * smoothstep(1.0, 0.95 - wave, uv.x) *
                   smoothstep(0.0, 0.05 + wave, uv.y) * smoothstep(1.0, 0.95 - wave, uv.y);
    
    // Jack's Theme Neon Color Palette
    vec3 color1 = vec3(0.61, 0.3, 0.86);  // Purple
    vec3 color2 = vec3(1.0, 0.0, 1.0);  // Magenta
    vec3 color3 = vec3(1.0, 0.16, 0.37);  // Red
    vec3 color4 = vec3(0.8, 0.0, 0.8);  // Deep Magenta
    
    // Mix colors dynamically based on screen position and time
    vec3 finalColor = mix(mix(color1, color2, uv.x), mix(color3, color4, uv.y), sin(uTime) * 0.5 + 0.5);
    
    // Apply the inverse of the border mask to leave only the glowing frame
    float alpha = (1.0 - border) * 0.8;
    fragColor = vec4(finalColor * alpha, alpha);
}
