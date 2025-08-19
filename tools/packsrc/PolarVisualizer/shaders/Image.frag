#define time iTime
#define PI 3.14159265359

#define NUM_BANDS 32

//#define REVERSED

float noise3D(vec3 p)
{
	return fract(sin(dot(p ,vec3(12.9898,78.233,12.7378))) * 43758.5453)*2.0-1.0;
}

vec3 mixc(vec3 col1, vec3 col2, float v)
{
    v = clamp(v,0.0,1.0);
    return col1+v*(col2-col1);
}

vec3 drawBands(vec2 uv)
{
  	uv = 2.0*uv-1.0;
    uv.x*=iResolution.x/iResolution.y;
    uv = vec2(length(uv), atan(uv.y,uv.x));
    
    //uv.x-=0.25;
    //uv.x = max(0.0,uv.x);
    
    uv.y -= PI*0.5;
    vec2 uv2 = vec2(uv.x, uv.y*-1.0);
    uv.y = mod(uv.y,PI*2.0);
    uv2.y = mod(uv2.y,PI*2.0);
    
    vec3 col = vec3(0.0);
    vec3 col2 = vec3(0.0);
    
    float nBands = float(NUM_BANDS);
    float i = floor(uv.x*nBands);
    float f = fract(uv.x*nBands);
    float band = i/nBands;
   	float s;
   	
    #ifdef REVERSED
    band = 1.0-band;
    #endif 
    
    //cubic easing
    band *= band*band; 
    
    band = band*0.99;
    band += 0.01;
    
    s = texture( iChannel0, vec2(band,0.25) ).x;  
    
    if(band<0.0||band>=1.0){
        s = 0.0;
    }
    
    /* Gradient colors and amount here */
    const int nColors = 4;
    vec3 colors[nColors];  
    colors[0] = vec3(0.05,0.05,1.0);
    colors[1] = vec3(0.05,1.00,1.00);
    colors[2] = vec3(0.50,1.00,0.25);
    colors[3] = vec3(1.00,0.75,0.25);
 
    vec3 gradCol = colors[0];
    float n = float(nColors)-1.0;
    for(int i = 1; i < nColors; i++)
    {
		gradCol = mixc(gradCol,colors[i],(s-float(i-1)/n)*n);
    }
    
    float h = PI*0.5;
    
    col += vec3(1.0-smoothstep(-0.5,0.0,uv.y-s*h));
    col *= gradCol;

    col2 += vec3(1.0-smoothstep(-0.5,0.0,uv2.y-s*h));
    col2*= gradCol;
    
    col = mix(col,col2,step(0.0,uv.y-PI));

    col *= smoothstep(0.125,0.375,f);
    col *= smoothstep(0.875,0.625,f); 
    
    col = clamp(col,0.0,1.0);
    
    return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 p = vec2(uv.x, uv.y+0.2);
	vec3 col = vec3(0.0);
    col += drawBands(p);//*smoothstep(1.0,0.5,uv.y);;
    
    vec3 ref = vec3(0.0);
    vec2 eps = vec2(0.0025,-0.0025);

    ref += drawBands(vec2(p.x,1.0-p.y)+eps.xx);
    ref += drawBands(vec2(p.x,1.0-p.y)+eps.xy);
    ref += drawBands(vec2(p.x,1.0-p.y)+eps.yy);
    ref += drawBands(vec2(p.x,1.0-p.y)+eps.yx);
    
    ref += drawBands(vec2(p.x+eps.x,1.0-p.y));
    ref += drawBands(vec2(p.x+eps.y,1.0-p.y));
    ref += drawBands(vec2(p.x,1.0-p.y+eps.x));
    ref += drawBands(vec2(p.x,1.0-p.y+eps.y));

    ref /= 8.0;
     
    float colStep = length(smoothstep(0.0,0.1,col));
    
    vec3 cs1 = drawBands(vec2(0.5,0.51));
    vec3 cs2 = drawBands(vec2(0.5,0.93));
        
    vec3 plCol = mix(cs1,cs2,length(p*2.0-1.0))*0.15*smoothstep(0.75,-0.25,length(p*2.0-1.0));
    vec3 plColBg = vec3(0.05)*smoothstep(1.0,0.0,length(p*2.0-1.0));
    vec3 pl = (plCol+plColBg)*smoothstep(0.5,0.65,1.0-uv.y);
    
    col += clamp(pl*(1.0-colStep),0.0,1.0);
    
    col += ref*smoothstep(0.125,1.6125,p.y); 
    
    col = clamp(col, 0.0, 1.0);

    float dither = noise3D(vec3(uv,time))*2.0/256.0;
    col += dither;
    
	fragColor = vec4(col,1.0);
}