/*
    "Phosphor 3" by @XorDev

    https://x.com/XorDev/status/1949897576435581439
    
    <512 playlist:
    https://www.shadertoy.com/playlist/N3SyzR
*/

void mainImage(out vec4 O, vec2 I)
{
    //Animation time
    float t = iTime,
    //Raymarch depth
    z,
    //Step distance
    d,
    //Signed distance
    s,
    //Raymarch iterator
    i;
    
    
    //Clear fragColor and raymarch 80 steps
    for(O*=i; i++<8e1;
        //Coloring and brightness
        O+=(cos(s+vec4(0,1,8,0))+1.)/d)
    {
        //Sample point (from ray direction)
        vec3 p = z*normalize(vec3(I+I,0)-iResolution.xyy),
        //Rotation axis
        a = normalize(cos(vec3(5,0,1)+t-d*4.));
        //Move camera back 5 units
        p.z+=5.,
        //Rotated coordinates
        a = a*dot(a,p)-cross(a,p);
        
        //Turbulence loop
        for(d=1.;d++<9.;)
            a-=sin(a*d+t).zxy/d;
        
        //Distance to ring
        z+=d=.1*abs(length(p)-3.)+.07*abs(cos(s=a.y));
    }
    //Tanh tonemap
    O = tanh(O/5e3);
}