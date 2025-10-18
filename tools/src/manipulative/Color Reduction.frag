//https://www.shadertoy.com/view/Ml33Dl
#define CFG_QUALITY 0.1

void mainImage(out vec4 fragColor,in vec2 fragCoord)
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    vec4 col = texture(iChannel0,uv);

    float colorQuality = 2.0 + (CFG_QUALITY)*8.0; // (1-255)

    // output
    vec3 q = vec3(colorQuality);
    fragColor = vec4(floor(col.rgb*q)/q,col.a);
}
