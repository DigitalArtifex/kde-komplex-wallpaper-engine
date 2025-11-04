#define T (iTime*.5)
#define P(z) (vec3((cos((z) * .2) * .3) * 10., \
                   (cos((z) * .15) * .3) * 10., (z)))
#define R(a) mat2(cos(a), -sin(a), sin(a), cos(a))
#define N normalize

bool hitRoot = false;

// @Shane
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001);
    n /= (n.x + n.y + n.z );  
    
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}

// @Shane:
// Commutative smooth minimum function. Provided by Tomkh, and taken 
// from Alex Evans's (aka Statix) talk: 
// http://media.lolrus.mediamolecule.com/AlexEvans_SIGGRAPH-2015.pdf
// Credited to Dave Smith @media molecule.
float smin(float a, float b, float k){

   float f = max(0., 1. - abs(b - a)/k);
   return min(a, b) - k*.25*f*f;
}


float fractal(vec3 p) {
    float s,w,l;

    p.y *= .4;
    p += cos(p.yzx*12.)*.07;
    p.x -= 1.6;
    for (s=0.,w=.7; s++ < 7.; p *= l, w *= l )
        p  = abs(sin(p))-1.,
        l = 1.5/dot(p,p);

    return length(p)/w-.0005;
}

float light(vec3 p) {
    p.xy -= P(p.z).xy;
    float t = iTime*.5;
    return length(p-vec3(
            tanh(cos(t*1.8)*2.) * .25 ,
            tanh(cos(t*1.)*3.) * .3,
            4.+T+tanh(cos(t*.4)*4.)*1.
        ))-.25;
}

float root(vec3 p){
    p.xy *= R(sin(p.z*2.)*.1 + sin(p.z*1.)*.3);
    p = mod(p, 1.) - .5;
    return .6*length(p.xy) - .01;
}

float map(vec3 p) {
    float s, r;
    r = root(p);
    
    p.xy -= P(p.z).xy;
    s = smin(fractal(p), 2. - abs(p.y), .8);
    hitRoot = r < s;
    s = min(s, r);
    return s;
}

// @iq
float AO(in vec3 pos, in vec3 nor) {
	float sca = 1.9, occ = 0.0;
    for( int i=0; i<5; i++ ){
        float hr = 0.01 + float(i)*0.5/4.0;        
        float dd = map(nor * hr + pos);
        occ += (hr - dd)*sca;
        sca *= 0.7;
    }
    return clamp( 1.0 - occ, 0.0, 1.0 );    
}

void mainImage(out vec4 o, in vec2 u) {
    float s=.1,d=0.,i=0.;
    vec3  r = iResolution;
    u = (u-r.xy/2.)/r.y;
    vec3  e = vec3(.001,0,0),
          p = P(T),ro=p,
          Z = N( P(T+1.) - p),
          X = N(vec3(Z.z,0,-Z)),
          D = vec3(R(sin(T*.2)*.4)*u, 1) 
             * mat3(-X, cross(X, Z), Z);

    o = vec4(0);
    for(;i++ < 128.;)
        p = ro + D * d * .65,
        d += s = map(p),
        o += 4e1*vec4(6,9,1,0) + 1./max(s, .001);
        
    r =  N(map(p) - vec3(map(p-e.xyy), 
                         map(p-e.yxy), 
                         map(p-e.yyx)));
    
    o.rgb *= tex3D(iChannel0, p*.5, r);
    o *= o;
    o *= hitRoot ? .2*vec4(4,3,2,0) : vec4(1);
    o *= AO(p, r);
    o = tanh(sqrt(d * o / pow(abs(light(p)), 3.) / 5e9 ));

}