void mainImage( out vec4 O, vec2 I )
{
    I/=iResolution.xy;
    I.y-=.04;
    O = I.y<0. ? texture(iChannel1, I) : texture(iChannel0, I);
}