#define T iTime
#define R iResolution.xy
#define S(a, b, c) smoothstep(a, b, c)
#define PI acos(-1.)
#define CEL rem(R)
#define LOWRES 320.



float rem(vec2 iR)
{
    float slices = floor(iR.y / LOWRES);
    if(slices < 1.){
        return 4.;  
    }
    else if(slices == 1.){
        return 6.;
    }
    else if(slices == 2.){
        return 8.;
    }
    else if(slices >= 3.){
        return 10.;
    }
    else if(slices >= 4.){
        return 12.;
    }
}

/////////////////////////////////////////////
// hash2 taken from Dave Hoskins 
// https://www.shadertoy.com/view/4djSRW
/////////////////////////////////////////////

float hash2(vec2 p)
{  
	vec3 p3  = fract(vec3(p.xyx) * .2831);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

/////////////////////////////////////////////
//                 NOISE 3D
// 3D noise and fbm function by Inigo Quilez
/////////////////////////////////////////////

mat3 m = mat3( .00,  .80,  .60,
              -.80,  .36, -.48,
              -.60, -.48,  .64 );

float hash( float n )
{
    float h =  fract(sin(n) * 4121.15393);

    return  h + .444;   
}

float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);

    f = f * f * (3.0 - 2.0 * f );

    float n = p.x + p.y * 157.0 + 113.0 * p.z;

    return mix(mix(mix( hash(n + 00.00), hash(n + 1.000), f.x),
                   mix( hash(n + 157.0), hash(n + 158.0), f.x), f.y),
               mix(mix( hash(n + 113.0), hash(n + 114.0), f.x),
                   mix( hash(n + 270.0), hash(n + 271.0), f.x), f.y), f.z);
}