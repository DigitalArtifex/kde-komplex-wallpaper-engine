// https://www.shadertoy.com/view/7sd3zX

//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
//

vec3 mod289(vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
    return mod289(((x*34.0)+10.0)*x);
}

float snoise(vec2 v)
{
    const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                        0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
    -0.577350269189626,  // -1.0 + 2.0 * C.x
    0.024390243902439); // 1.0 / 41.0
    // First corner
    vec2 i  = floor(v + dot(v, C.yy) );
    vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    vec4 x12 = x0.xyxy + C.xxzz;
    x12.xy -= i1;

    // Permutations
    i = mod289(i); // Avoid truncation effects in permutation
    vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
    + i.x + vec3(0.0, i1.x, 1.0 ));

    vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    vec3 x = 2.0 * fract(p * C.www) - 1.0;
    vec3 h = abs(x) - 0.5;
    vec3 ox = floor(x + 0.5);
    vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

vec4 SCREEN(in vec4 src, in vec4 dst){
    return ( src + dst ) - ( src * dst );
}

vec3 Blur(sampler2D tex, vec2 uv, float blurSize, float directions, float quality){
    float TWO_PI = 6.28318530718;

    vec2 radius = blurSize/iResolution.xy;
    vec3 res = texture(tex, uv).rgb;
    for(float i=1.0/quality; i<=1.0; i+=1.0/quality)
    {
        for( float d=0.0; d<TWO_PI; d+=TWO_PI/directions)
        {
			res += texture( tex, uv+vec2(cos(d),sin(d))*radius*i).rgb;
        }
    }
    res /= (quality-1.) * directions;
    return res;
}
vec3 Blur(sampler2D tex, vec2 uv){
    return Blur(tex,uv, 4.,16.,4.);
}

vec2 ShakeUV(vec2 uv, float time){
    uv.x += 0.002 * sin(time*3.141) * sin(time*14.14);
    uv.y += 0.002 * sin(time*1.618) * sin(time*17.32);
    return uv;
}

float filmDirt(vec2 uv, float time){
    uv += time * sin(time) * 10.;
    float res = 1.0;

    float rnd = fract(sin(time+1.)*31415.);
    if(rnd>0.3){
        float dirt =
            texture(iChannel1,uv*0.1).r *
            texture(iChannel1,uv*0.01).r *
            texture(iChannel1,uv*0.002).r *
            1.0;
        res = 1.0 - smoothstep(0.4,0.6, dirt);
    }
    return res;
}

float FpsTime(float time, float fps){
    time = mod(time, 60.0);
    time = float(int(time*fps)) / fps;
    return time;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 mUV = iMouse.xy/iResolution.xy;

    mUV = vec2(0.5,0.7); /*fix mouse pos for thumbnail*/

    vec4 col;

    float time = FpsTime(iTime, 12.);
    fragColor = vec4(mod(uv.x+time*0.5, 0.1)*10.);
    //return; /* Debug FpsTime */

    vec2 suv = ShakeUV(uv, time);
    fragColor = vec4(mod(suv.xy,0.1)*10., 0., 1.0);
    //return; /* Debug ShakeUV */

    //float grain = mix(1.0, fract(sin(dot(suv.xy+time,vec2(12.9898,78.233))) * 43758.5453), 0.25); /* random */
    float grain = mix(1.0, snoise(suv.xy*1234.), 0.15); /* simplex noise */
    fragColor = vec4(vec3(grain), 1.0);
    //return; /* Debug grain */

    vec3 color = texture(iChannel0, suv).rgb;
    color *= grain;

    float Size = mUV.x * 8.;
    float Directions = 16.0;
    float Quality = 3.0;
    vec3 blur = Blur(iChannel0, suv, Size, Directions, Quality);
    blur *= grain;

    float Threshold = mUV.y;
    vec3 FilterRGB = normalize(vec3(1.5,1.2,1.0));
    float HighlightPower = 3.0;
    HighlightPower *= 1. + fract(sin(time)*3.1415) * 0.3;
    vec3 highlight = clamp(color -Threshold,0.0,1.0)/(1.0-Threshold);
    highlight = blur * Threshold * FilterRGB * HighlightPower;

    /* dirt */
    float dirt = filmDirt(uv, time);
    fragColor = vec4(vec3(dirt), 1.0);
    //return; /* Debug dirt */

    col = SCREEN(vec4(color,1.0), vec4(highlight,1.0));
    //col = vec4(highlight,1.0);
    //col = vec4(blur,1.0);
    col *= dirt;

    vec2 v = uv * (1.0 - uv.yx);
    float vig = v.x*v.y * 15.0;
    vig = pow(vig, 0.5);

    fragColor = col * vig;
    //fragColor = uv.x>0.5 ? colR : colL;
}
