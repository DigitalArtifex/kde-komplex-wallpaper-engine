/*
 * Andor Salga
 * March 2014
 *
 * Simple demo showing mirror effects.
 */

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p = fragCoord.xy/iResolution.xy;
    p.y += step(0.5, p.y) * (0.5-p.y) * 2.0;

    fragColor = texture(iChannel0, p);
}
