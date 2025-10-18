// https://www.shadertoy.com/view/ldVSW1
#define PIXEL_SIZE 5.0

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 uv = fragCoord.xy / iResolution.xy;

    float plx = iResolution.x * PIXEL_SIZE / 500.0;
    float ply = iResolution.y * PIXEL_SIZE / 275.0;

    float dx = plx * (1.0 / iResolution.x);
    float dy = ply * (1.0 / iResolution.y);

    uv.x = dx * floor(uv.x / dx);
    uv.y = dy * floor(uv.y / dy);

    fragColor = texture(iChannel0, uv);
}
