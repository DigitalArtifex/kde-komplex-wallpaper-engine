/*
	Blurring by scattering pixels

	Based on https://github.com/FlexMonkey/Filterpedia/blob/7a0d4a7070894eb77b9d1831f689f9d8765c12ca/Filterpedia/customFilters/Scatter.swift

	Simon Gladman | November 2017 | http://flexmonkey.blogspot.co.uk
*/

float noise(vec2 co) {
    vec2 seed = vec2(sin(co.x), cos(co.y));
    return fract(sin(dot(seed ,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	float radius = abs(25.0 * sin(12.0));

    vec2 offset = -radius + vec2(noise(fragCoord), noise(fragCoord.yx)) * radius * 2.0;

    vec2 uv = (fragCoord + offset ) / iResolution.xy;

	fragColor = texture(iChannel0, uv);
}
