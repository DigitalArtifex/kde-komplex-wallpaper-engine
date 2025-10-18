// https://www.shadertoy.com/view/lXBczw

vec3 thermal(vec3 color)
{
vec3 invColor = vec3(1.)- color;
float len = pow((length(invColor*2.2))/3.,2.);
vec3 col = vec3(len,len*pow((1.-color.r),2.),0.);
return vec3(len*1.5,len*pow((1.-color.r),2.),0)+dot(col,vec3(0,1,0))/1.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec3 inColor = texture(iChannel0, uv).xyz;
    // Output to screen
    fragColor = vec4(thermal(inColor),1.0);
}
