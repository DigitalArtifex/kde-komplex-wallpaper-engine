// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

vec3 rdrImg(vec2 uv)
{
    vec3 col = pow(texture(iChannel0, uv).xyz,vec3(1.3));
    col += pow(texture(iChannel0, uv).xyz,vec3(.9))*.35;
    return col;
}

vec3 rdrChroma(vec2 uv)
{
    vec3 col = vec3(0.);
    vec2 off = vec2(.002);
    col.r = rdrImg(uv+off).r;
    col.g = rdrImg(uv).g;
    col.b = rdrImg(uv-off).b;
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy/iResolution.xy;
    
    vec3 col = rdrChroma(uv);

    fragColor = vec4(col,1.0);
}