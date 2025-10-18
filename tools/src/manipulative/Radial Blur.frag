// by Nikos Papadopoulos, 4rknova / 2017
// WTFPL

#define JITTER
#define MOUSE

float hash(in vec2 p) { return fract(sin(dot(p,vec2(283.6,127.1))) * 43758.5453);}

#ifdef MOUSE
	#define CENTER (iMouse.xy/iResolution.xy)
#else
	#define CENTER vec2(.5)
#endif

#define SAMPLES 10
#define RADIUS  .01

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec3  res = vec3(0);
    for(int i = 0; i < SAMPLES; ++i) {
        res += texture(iChannel0, uv).xyz;
        vec2 d = CENTER-uv;
#ifdef JITTER
        d *= .5 + .01*hash(d*iTime);
#endif
        uv += d * RADIUS;
    }

    fragColor = vec4(res/float(SAMPLES), 1);
}
