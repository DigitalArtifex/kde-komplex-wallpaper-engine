#define TURB_CH xy
#define TURB_SAMPLER iChannel0
#define DEGREE TURBULENCE_SCALES

#define D(d) textureLod(TURB_SAMPLER, fract(uv+d), mip).TURB_CH

void tex(vec2 uv, inout mat3 mx, inout mat3 my, int degree) {
    vec2 texel = 1.0/iResolution.xy;
    float stride = float(1 << degree);
    float mip = float(degree);
    vec4 t = stride * vec4(texel, -texel.y, 0);

    vec2 d =    D( t.ww); vec2 d_n =  D( t.wy); vec2 d_e =  D( t.xw);
    vec2 d_s =  D( t.wz); vec2 d_w =  D(-t.xw); vec2 d_nw = D(-t.xz);
    vec2 d_sw = D(-t.xy); vec2 d_ne = D( t.xy); vec2 d_se = D( t.xz);
    
    mx =  mat3(d_nw.x, d_n.x, d_ne.x,
               d_w.x,  d.x,   d_e.x,
               d_sw.x, d_s.x, d_se.x);
    
    my =  mat3(d_nw.y, d_n.y, d_ne.y,
               d_w.y,  d.y,   d_e.y,
               d_sw.y, d_s.y, d_se.y);
}

float reduce(mat3 a, mat3 b) {
    mat3 p = matrixCompMult(a, b);
    return p[0][0] + p[0][1] + p[0][2] +
           p[1][0] + p[1][1] + p[1][2] +
           p[2][0] + p[2][1] + p[2][2];
}

void turbulence(vec2 fragCoord, inout vec2 turb, inout float curl)
{
	vec2 uv = fragCoord.xy / iResolution.xy;
     
    mat3 turb_xx = (2.0 - TURB_ISOTROPY) * mat3(
        0.125,  0.25, 0.125,
       -0.25,  -0.5, -0.25,
        0.125,  0.25, 0.125
    );

    mat3 turb_yy = (2.0 - TURB_ISOTROPY) * mat3(
        0.125, -0.25, 0.125,
        0.25,  -0.5,  0.25,
        0.125, -0.25, 0.125
    );

    mat3 turb_xy = TURB_ISOTROPY * mat3(
       0.25, 0.0, -0.25,  
       0.0,  0.0,  0.0,
      -0.25, 0.0,  0.25
    );
    
    const float norm = 8.8 / (4.0 + 8.0 * CURL_ISOTROPY);  // 8.8 takes the isotropy as 0.6
    float c0 = CURL_ISOTROPY;
    
    mat3 curl_x = mat3(
        c0,   1.0,  c0,
        0.0,  0.0,  0.0,
       -c0,  -1.0, -c0
    );

    mat3 curl_y = mat3(
        c0, 0.0, -c0,
       1.0, 0.0, -1.0,
        c0, 0.0, -c0
    );
    
    mat3 mx, my;
    vec2 v = vec2(0);
    float turb_wc, curl_wc = 0.0;
    curl = 0.0;
    for (int i = 0; i < DEGREE; i++) {
        tex(uv, mx, my, i);
        float turb_w = TURB_W_FUNCTION;
        float curl_w = CURL_W_FUNCTION;
    	v += turb_w * vec2(reduce(turb_xx, mx) + reduce(turb_xy, my), reduce(turb_yy, my) + reduce(turb_xy, mx));
        curl += curl_w * (reduce(curl_x, mx) + reduce(curl_y, my));
        turb_wc += turb_w;
        curl_wc += curl_w;
    }

    turb = float(DEGREE) * v / turb_wc;
    curl = norm * curl / curl_wc;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 turb;
    float curl;
    turbulence(fragCoord, turb, curl);
    fragColor = vec4(turb,0,curl);
    // Adding a very small amount of noise on init fixes subtle numerical precision blowup problems
    if (iFrame==0) fragColor=1e-6*rand4(fragCoord, iResolution.xy, iFrame);
}