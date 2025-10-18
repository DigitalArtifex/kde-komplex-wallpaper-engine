// https://www.shadertoy.com/view/ldKfWc
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord / iResolution.xy;
    vec2 shift = uv;
    float offset = shift.y * .2;
    shift.x -= offset - .2;
    shift.x -= mod( exp(shift.x), shift.x * .8) * .5;
    shift.x += offset - .1;
    vec3 img = texture(iChannel0,shift).rgb;
    img.bg *= uv.x * shift.x;
    img.b += uv.x * .3;
    fragColor = vec4(img ,1.0);
}
