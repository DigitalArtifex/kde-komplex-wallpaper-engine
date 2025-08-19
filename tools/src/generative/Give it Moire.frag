#ifdef GL_ES
    precision mediump float;
#endif

#define PI 3.14159265359
#define HALF_PI 1.57079632675
#define TWO_PI 6.283185307

#define SECONDS 60.0

float random(vec2 st){ return fract(sin(dot(st.yx,vec2(14.7891,43.123)))*312991.41235); }
float random (in float x) { return fract(sin(x)*43758.5453123); }

float cell_random(float x,float scale)
{   
    float iPos = floor(x*scale);
    return mix(random(iPos), random(iPos + 1.0), smoothstep(0.,1.,fract(x*scale)));
}

mat2 rotate(float angle)
{
    return mat2( cos(angle),-sin(angle),sin(angle),cos(angle) );
}

vec2 center(vec2 st)
{
    float aspect = iResolution.x/iResolution.y;
    st.x = st.x * aspect - aspect * 0.5 + 0.5;
    return st;
}

float lines(vec2 st)
{
    st -= st.y-st.x;    // go diagonal
    return sin(st.x*10.0);
}

vec2 map(vec2 st, float t)
{
    vec2 pos = vec2(0.0);
        pos += vec2(0.4)*rotate(TWO_PI*t);
    
    st = st-pos;

    float freq = mix(1.5,2.25,cell_random(sin(PI + iTime*.15),5.0));
    float amount = mix(0.08,0.35,cell_random(sin(TWO_PI*.75+iTime*.0025),10.0));
    float c = length(st);
    float sq = mix(1.0,10.0, cell_random(sin(PI + iTime*.005),50.0));
    float scale = mix(sq,4.0,0.5+0.5*sin(st.x*st.y*st.y*4.0));
    vec2 uv = st + (c)*freq*cos(c*scale-TWO_PI*4.0)*amount;

    return uv;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 st = fragCoord/iResolution.xy;
    float t = fract(iTime/SECONDS);

    st = center(st);
    st = st * 2.0 - 1.0;
    st *= rotate(PI*0.25);
	st *= rotate(TWO_PI*iTime*0.0015);

    vec2 m = map(st,t);

    float r = cell_random(length(m)+iTime*0.023,10.0);

    float stripes = sin(m.x*50.0);
    float d = dot(m,st)+0.1;

    float c_repeats = mix(20.0,100.0,cell_random(sin(iTime*.035),10.0));

    vec3 c_sin = cos(vec3(0.15,.32,0.3)+d*c_repeats + iTime );
    vec3 color = c_sin-d-stripes;
        color += r;

    fragColor = vec4(color,1.0);
}