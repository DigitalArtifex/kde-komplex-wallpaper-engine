#define CURL_CH w
#define CURL_SAMPLER iChannel0
#define DEGREE VORTICITY_SCALES

#define CURL(d) textureLod(CURL_SAMPLER, fract(uv+(d+0.0)), mip).CURL_CH
#define D(d) abs(textureLod(CURL_SAMPLER, fract(uv+d), mip).CURL_CH)

void tex(vec2 uv, inout mat3 mc, inout float curl, int degree) {
    vec2 texel = 1.0/iResolution.xy;
    float stride = float(1 << degree);
    float mip = float(degree);
    vec4 t = stride * vec4(texel, -texel.y, 0);

    float d =    D( t.ww); float d_n =  D( t.wy); float d_e =  D( t.xw);
    float d_s =  D( t.wz); float d_w =  D(-t.xw); float d_nw = D(-t.xz);
    float d_sw = D(-t.xy); float d_ne = D( t.xy); float d_se = D( t.xz);
    
    mc =  mat3(d_nw, d_n, d_ne,
               d_w,  d,   d_e,
               d_sw, d_s, d_se);
    
    curl = CURL();
    
}

float reduce(mat3 a, mat3 b) {
    mat3 p = matrixCompMult(a, b);
    return p[0][0] + p[0][1] + p[0][2] +
           p[1][0] + p[1][1] + p[1][2] +
           p[2][0] + p[2][1] + p[2][2];
}

vec2 confinement(vec2 fragCoord)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    float k0 = CONF_ISOTROPY;
    float k1 = 1.0 - 2.0*(CONF_ISOTROPY);

    mat3 conf_x = mat3(
       -k0, -k1, -k0,
        0.0, 0.0, 0.0,
        k0,  k1,  k0
    );

    mat3 conf_y = mat3(
       -k0,  0.0,  k0,
       -k1,  0.0,  k1,
       -k0,  0.0,  k0
    );
    
    mat3 mc;
    vec2 v = vec2(0);
    float curl;
    
    float cacc = 0.0;
    vec2 nacc = vec2(0);
    float wc = 0.0;
    for (int i = 0; i < DEGREE; i++) {
        tex(uv, mc, curl, i);
        float w = CONF_W_FUNCTION;
        vec2 n = w * normz(vec2(reduce(conf_x, mc), reduce(conf_y, mc)));
        v += curl * n;
        cacc += curl;
        nacc += n;
        wc += w;
    }

    #ifdef PREMULTIPLY_CURL
        return v / wc;
    #else
    	return nacc * cacc / wc;
    #endif

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    fragColor = vec4(confinement(fragCoord),0,0);
    // Adding a very small amount of noise on init fixes subtle numerical precision blowup problems
    if (iFrame==0) fragColor=1e-6*rand4(fragCoord, iResolution.xy, iFrame);
}