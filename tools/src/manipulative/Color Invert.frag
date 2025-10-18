// https://www.shadertoy.com/view/cdcSz7

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Get the color of the video at the current pixel
    vec3 col = texture(iChannel0, uv).rgb;

    // Invert the color
    col = vec3(1.0) - col;

    // Output to screen
    fragColor = vec4(col,1.0);
}
