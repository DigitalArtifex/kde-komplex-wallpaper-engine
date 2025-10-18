// by Nikos Papadopoulos, 4rknova / 2013
// WTFPL

float hash(in float n) { return fract(sin(n)*43758.5453123); }

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 p = fragCoord.xy / iResolution.xy;

	vec2 u = p * 2. - 1.;
	vec2 n = u * vec2(iResolution.x / iResolution.y, 1.0);
	vec3 c = texture(iChannel0, p).xyz;


	// flicker, grain, vignette, fade in
	c += sin(hash(iTime)) * 0.01;
	c += hash((hash(n.x) + n.y) * iTime) * 0.5;
	c *= smoothstep(length(n * n * n * vec2(0.075, 0.4)), 1.0, 0.4);
    c *= smoothstep(0.001, 3.5, iTime) * 1.5;

	c = dot(c, vec3(0.2126, 0.7152, 0.0722))
	  * vec3(0.2, 1.5 - hash(iTime) * 0.1,0.4);

	fragColor = vec4(c,1.0);
}
