// https://www.shadertoy.com/view/ddXBR7

// EGA palette colors
vec4 egaPalette[17] = vec4[](
    vec4(0.000, 0.000, 0.000, 1.), // black
    vec4(0.000, 0.000, 0.667, 1.), // dk blue
    vec4(0.000, 0.667, 0.000, 1.), // dk green
    vec4(0.000, 0.667, 0.667, 1.), // dk teal
    vec4(0.667, 0.000, 0.000, 1.), // dk red
    vec4(0.667, 0.000, 0.667, 1.), // magenta
    vec4(0.667, 0.333, 0.000, 1.), // brown
    vec4(0.33, 0.33, 0.33, 1.),    // lt gray
    vec4(0.333, 0.333, 0.333, 1.), // gray
    vec4(0.333, 0.333, 1.000, 1.), // lt blue
    vec4(0.333, 1.000, 0.333, 1.), // lt green
    vec4(0.333, 1.000, 1.000, 1.), // lt cyan
    vec4(1.000, 0.333, 0.333, 1.), // lt red (pink?)
    vec4(1.000, 0.333, 1.000, 1.), // lt magenta
    vec4(1.000, 1.000, 0.333, 1.), // lt yellow
    vec4(1.000, 1.000, 1.000, 1.),  // white
    vec4(0.28, 0.7, 0.2, 1.) // clear index color for green bg
);

vec4 indexToEGA(vec3 color)
{
    // Find the closest color in the EGA palette
    float minDistance = distance(color, egaPalette[0].rgb);
    vec4 closestColor = egaPalette[0];

    for (int i = 1; i < 16; i++) {
        float distanceToColor = distance(color, egaPalette[i].rgb);
        if (distanceToColor < minDistance) {
            minDistance = distanceToColor;
            closestColor = egaPalette[i];
        }
    }

    return closestColor;
}

vec4 background(vec4 indexedColor, vec2 uv) {
    float threshold = 0.35;
    if (distance(indexedColor, vec4(0.28, 0.7, 0.2, 1.)) < threshold) {
        indexedColor = egaPalette[11];
        if (uv.y < .5) {
            indexedColor = egaPalette[12];
        }
        if (uv.x < .5) {
           indexedColor = egaPalette[14];
           if (uv.y < .5) {
               indexedColor = egaPalette[13];
           }
        }
    }
    return indexedColor;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalize fragment coordinates to the range [0, 1]
    vec2 uv = fragCoord / iResolution.xy;

    // Sample video texture from iChannel0
    vec4 videoColor = texture(iChannel0, uv);

    // Index each color channel to the EGA palette
    vec4 indexedColor = indexToEGA(videoColor.rgb);

    vec4 background = background(indexedColor, uv);

    // Set the fragment color using the indexed color
    fragColor = background;
}
