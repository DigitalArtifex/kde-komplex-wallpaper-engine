//https://www.shadertoy.com/view/tt3XDf
#define SIZE 50.1

float rand(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.y;
    vec2 ouv = fragCoord/iResolution.xy;

    float m = 0.;
    float t = iTime*2.2 + 100.;

    for(float i=0.; i<=1.0; i+=0.25){
        vec2 iuv = uv + vec2(i*.05, 0.);
        vec2 ruv = iuv*SIZE;
    	vec2 id = ceil(ruv);

        for(float y=-1.; y<=1.; y+=1.){
            for(float x=-1.; x<=1.; x+=1.0){
                vec2 nuv = ruv + vec2(x,y);
                vec2 nid = id + vec2(x,y);

                nuv.y += t*2. * (rand(vec2(nid.x))*.75+.5) * i;
                nuv.y += ceil(mod(nid.x, 3.))*0.3 * t;

                vec2 guv = fract(nuv);

                nuv = floor(nuv) ;
                float g = length(guv - vec2(x,y));

                float v = rand(nuv);
                v *= step(0.9, v);
                m += smoothstep(v,v-.8, g);
            }
        }
    }

    m = m*.2 + step(1.25, m) *.2 + step(2.0, m) *.1;


    vec3 col = texture(iChannel0, ouv + m*.125).rgb;


    fragColor = vec4(col ,1.0);
}
