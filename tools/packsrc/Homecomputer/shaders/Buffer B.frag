// Homecomputer by nimitz 2016 (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//Rendering

/*
	This buffer renders each particles
	multiple times per frame to allow particles
	to move more than one pixel per frame while still
	leaving a solid trail.
*/

#define time iTime
const int numParticles = 100;
const int stepsPerFrame = 9;

mat2 mm2(in float a){float c = cos(a), s = sin(a);return mat2(c,s,-s,c);}
float mag(vec3 p){return dot(p,p);}

vec4 drawParticles(in vec3 ro, in vec3 rd, in float ints)
{
    vec4 rez = vec4(0);
    vec2 w = 1./iResolution.xy;
    
    for (int i = 0; i < numParticles; i++)
    {
        vec3 pos = texture(iChannel0, vec2(i,100.0)*w).rgb;
        vec3 vel = texture(iChannel0, vec2(i,0.0)*w).rgb;
        
        float st = sin(time*0.6);
        
        for(int j = 0; j < stepsPerFrame; j++)
        {
            float d = mag((ro + rd*dot(pos.xyz - ro, rd)) - pos.xyz);
            d *= 1000.;
            d = 2./(pow(d,1.+ sin(time*0.6)*0.15)+1.5);
            d *= (st+4.)*.8;

            rez.rgb += d*(sin(vec3(.7,2.0,2.5)+float(i)*.015 + time*0.3 + vec3(5,1,6))*0.45+0.55)*0.005;
            
            pos.xyz += vel*0.002*1.5;
        }
    }
    
    return rez;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{	
    vec2 q = fragCoord.xy/iResolution.xy;
	vec2 p = fragCoord.xy/iResolution.xy-0.5;
	p.x*=iResolution.x/iResolution.y;
	
	vec3 ro = vec3(0.,0.,2.7);
    vec3 rd = normalize(vec3(p,-.5));
    
    vec3 sndNFO = texture(iChannel2, vec2(0.65, 0.1)).zwx + vec3(-.5, -0.1, -0.0);
    
    vec4 cola = drawParticles(ro, rd, sndNFO.y)*10.;
    //if (mod(time+q.x*.15+q.y*0.15,28.) < 14.)cola = vec4(.9,.95,1.,1.)-cola*.9; //Invert colors
    
    vec2 mv = vec2(pow(sndNFO.z,2.)*0.05,sndNFO.x*.95);
    mv *= mm2(time*1.);
    
    vec4 colb = texture(iChannel1, q+mv);
    //vec4 colb = texture(iChannel1, q);
    
    vec4 col = mix(cola, colb, 0.91);
    if (iFrame < 5) col = vec4(0);
    
	fragColor = col;
}