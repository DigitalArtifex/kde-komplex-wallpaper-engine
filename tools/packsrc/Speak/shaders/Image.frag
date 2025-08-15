/*
    "Speak" by @XorDev

    Playing with music reactive shaders
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR
*/

void mainImage(out vec4 O, vec2 I)
{
    //Animation time
    float t=iTime,
    //Raymarch depth
    z,
    //Step distance
    d,
    //Signed distance
    s,
    //Raymarch iterator
    i;
    
    //Clear fragColor and raymarch 60 steps
    for(O*=i; i++<6e1;
        //Coloring and brightness
        O+=(cos(i*.1+t+vec4(6,1,2,0))+1.)/d)
    {
        //Sample point (from ray direction)
        vec3 p = z*normalize(vec3(I+I,0)-iResolution.xyy),
        //Rotation axis
        a = normalize(cos(vec3(0,2,4)+t+.1*i));
        //Move camera back 5 units
        p.z+=9.,
        //Rotated coordinates
        a = a*dot(a,p)-cross(a,p);
        
        //Turbulence loop
        for(d=.6;d<9.;d+=d)
            a-=cos(a*d+t-.1*i).zxy/d;
        
        //Distance to hollow, distorted sphere
        z+=d=.1*abs(s=length(a)-3.- sin(texture(iChannel0,vec2(1,s)*.1).r/.1));
    }
    //Tanh tonemap
    O = tanh(O/1e3);
}