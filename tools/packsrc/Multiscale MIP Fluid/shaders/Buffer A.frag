#define TURBULENCE_SAMPLER iChannel3
#define CONFINEMENT_SAMPLER iChannel2
#define POISSON_SAMPLER iChannel1
#define VELOCITY_SAMPLER iChannel0

#define V(d) texture(TURBULENCE_SAMPLER, fract(uv+(d+0.))).xy

vec2 gaussian_turbulence(vec2 uv) {
    vec2 texel = 1.0/iResolution.xy;
    vec4 t = vec4(texel, -texel.y, 0);

    vec2 d =    V( t.ww); vec2 d_n =  V( t.wy); vec2 d_e =  V( t.xw);
    vec2 d_s =  V( t.wz); vec2 d_w =  V(-t.xw); vec2 d_nw = V(-t.xz);
    vec2 d_sw = V(-t.xy); vec2 d_ne = V( t.xy); vec2 d_se = V( t.xz);
    
    return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
}

#define C(d) texture(CONFINEMENT_SAMPLER, fract(uv+(d+0.))).xy

vec2 gaussian_confinement(vec2 uv) {
    vec2 texel = 1.0/iResolution.xy;
    vec4 t = vec4(texel, -texel.y, 0);

    vec2 d =    C( t.ww); vec2 d_n =  C( t.wy); vec2 d_e =  C( t.xw);
    vec2 d_s =  C( t.wz); vec2 d_w =  C(-t.xw); vec2 d_nw = C(-t.xz);
    vec2 d_sw = C(-t.xy); vec2 d_ne = C( t.xy); vec2 d_se = C( t.xz);
    
    return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
}

#define D(d) texture(POISSON_SAMPLER, fract(uv+d)).x

vec2 diff(vec2 uv) {
    vec2 texel = 1.0/iResolution.xy;
    vec4 t = vec4(texel, -texel.y, 0);

    float d =    D( t.ww); float d_n =  D( t.wy); float d_e =  D( t.xw);
    float d_s =  D( t.wz); float d_w =  D(-t.xw); float d_nw = D(-t.xz);
    float d_sw = D(-t.xy); float d_ne = D( t.xy); float d_se = D( t.xz);
    
    return vec2(
        0.5 * (d_e - d_w) + 0.25 * (d_ne - d_nw + d_se - d_sw),
        0.5 * (d_n - d_s) + 0.25 * (d_ne + d_nw - d_se - d_sw)
    );
}

#define N(d) texture(VELOCITY_SAMPLER, fract(uv+(d+0.)))

vec4 gaussian_velocity(vec2 uv) {
    vec2 texel = 1.0/iResolution.xy;
    vec4 t = vec4(texel, -texel.y, 0);

    vec4 d =    N( t.ww); vec4 d_n =  N( t.wy); vec4 d_e =  N( t.xw);
    vec4 d_s =  N( t.wz); vec4 d_w =  N(-t.xw); vec4 d_nw = N(-t.xz);
    vec4 d_sw = N(-t.xy); vec4 d_ne = N( t.xy); vec4 d_se = N( t.xz);
    
    return 0.25 * d + 0.125 * (d_e + d_w + d_n + d_s) + 0.0625 * (d_ne + d_nw + d_se + d_sw);
}

vec2 vector_laplacian(vec2 uv) {
    const float _K0 = -20.0/6.0, _K1 = 4.0/6.0, _K2 = 1.0/6.0;
    vec2 texel = 1.0/iResolution.xy;
    vec4 t = vec4(texel, -texel.y, 0);

    vec4 d =    N( t.ww); vec4 d_n =  N( t.wy); vec4 d_e =  N( t.xw);
    vec4 d_s =  N( t.wz); vec4 d_w =  N(-t.xw); vec4 d_nw = N(-t.xz);
    vec4 d_sw = N(-t.xy); vec4 d_ne = N( t.xy); vec4 d_se = N( t.xz);
    
    return (_K0 * d + _K1 * (d_e + d_w + d_n + d_s) + _K2 * (d_ne + d_nw + d_se + d_sw)).xy;
}

    


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec2 tx = 1.0/iResolution.xy;

    
    vec2 turb, confine, div, delta_v, offset, lapl = vec2(0);
    vec4 vel, adv = vec4(0);
    vec4 init = N();

    #ifdef RECALCULATE_OFFSET
        for (int i = 0; i < ADVECTION_STEPS; i++) {
            #ifdef BLUR_TURBULENCE
            turb = gaussian_turbulence(uv + tx * offset);
            #else
            turb = V(tx * offset);
            #endif

            #ifdef BLUR_CONFINEMENT
            confine = gaussian_confinement(uv + tx * offset);
            #else
            confine = C(tx * offset);
            #endif

            #ifdef BLUR_VELOCITY
            vel = gaussian_velocity(uv + tx * offset);
            #else
            vel = N(tx * offset);
            #endif

            // an alternative, but seems to give less smooth results:
            // offset += (1.0 / float(ADVECTION_STEPS)) * ...
            offset = (float(i+1) / float(ADVECTION_STEPS)) * - ADVECTION_SCALE * (ADVECTION_VELOCITY * vel.xy + ADVECTION_TURBULENCE * turb - ADVECTION_CONFINEMENT * confine + ADVECTION_DIVERGENCE * div);

            div = diff(uv + tx * DIVERGENCE_LOOKAHEAD * offset);

            lapl = vector_laplacian(uv + tx * LAPLACIAN_LOOKAHEAD * offset);

            adv += N(tx * offset);

            delta_v += VELOCITY_LAPLACIAN * lapl + VELOCITY_TURBULENCE * turb + VELOCITY_CONFINEMENT * confine - DAMPING * vel.xy - DIVERGENCE_MINIMIZATION * div;
        }
        adv /= float(ADVECTION_STEPS);
        delta_v /= float(ADVECTION_STEPS);
    #else
        #ifdef BLUR_TURBULENCE
        turb = gaussian_turbulence(uv);
        #else
        turb = V();
        #endif

        #ifdef BLUR_CONFINEMENT
        confine = gaussian_confinement(uv);
        #else
        confine = C();
        #endif

        #ifdef BLUR_VELOCITY
        vel = gaussian_velocity(uv);
        #else
        vel = N();
        #endif
    
    	offset = - ADVECTION_SCALE * (ADVECTION_VELOCITY * vel.xy + ADVECTION_TURBULENCE * turb - ADVECTION_CONFINEMENT * confine + ADVECTION_DIVERGENCE * div);
        
    	div = diff(uv + tx * DIVERGENCE_LOOKAHEAD * offset);
        
    	lapl = vector_laplacian(uv + tx * LAPLACIAN_LOOKAHEAD * offset);
    	
    	delta_v += VELOCITY_LAPLACIAN * lapl + VELOCITY_TURBULENCE * turb + VELOCITY_CONFINEMENT * confine - DAMPING * vel.xy - DIVERGENCE_MINIMIZATION * div;
    
        for (int i = 0; i < ADVECTION_STEPS; i++) {
            adv += N((float(i+1) / float(ADVECTION_STEPS)) * tx * offset);   
        }   
        adv /= float(ADVECTION_STEPS);
    #endif
    

    
    // define a pump, either at the center of the screen,
    // or alternating at the sides of the screen.
    vec2 pq = 2.0*(uv*2.0-1.0) * vec2(1,tx.x/tx.y);
    #ifdef CENTER_PUMP
    	vec2 pump = sin(PUMP_CYCLE*iTime)*PUMP_SCALE*pq.xy / (dot(pq,pq)+0.01);
    #else
    	vec2 pump = vec2(0);
    	#define AMP 15.0
    	#define SCL -50.0
        float uvy0 = exp(SCL*pow(pq.y,2.0));
        float uvx0 = exp(SCL*pow(uv.x,2.0));
        pump += -AMP*vec2(max(0.0,cos(PUMP_CYCLE*iTime))*PUMP_SCALE*uvx0*uvy0,0);
    
    	float uvy1 = exp(SCL*pow(pq.y,2.0));
        float uvx1 = exp(SCL*pow(1.0 - uv.x,2.0));
        pump += AMP*vec2(max(0.0,cos(PUMP_CYCLE*iTime + 3.1416))*PUMP_SCALE*uvx1*uvy1,0);

        float uvy2 = exp(SCL*pow(pq.x,2.0));
        float uvx2 = exp(SCL*pow(uv.y,2.0));
        pump += -AMP*vec2(0,max(0.0,sin(PUMP_CYCLE*iTime))*PUMP_SCALE*uvx2*uvy2);
    
    	float uvy3 = exp(SCL*pow(pq.x,2.0));
        float uvx3 = exp(SCL*pow(1.0 - uv.y,2.0));
        pump += AMP*vec2(0,max(0.0,sin(PUMP_CYCLE*iTime + 3.1416))*PUMP_SCALE*uvx3*uvy3);
    #endif
    
    fragColor = mix(adv + vec4(VELOCITY_SCALE * (delta_v + pump), offset), init, UPDATE_SMOOTHING);
    
    if (iMouse.z > 0.0) {
        vec4 mouseUV = iMouse / iResolution.xyxy;
        vec2 delta = normz(mouseUV.zw - mouseUV.xy);
        vec2 md = (mouseUV.xy - uv) * vec2(1.0,tx.x/tx.y);
        float amp = exp(max(-12.0,-dot(md,md)/MOUSE_RADIUS));
        fragColor.xy += VELOCITY_SCALE * MOUSE_AMP * clamp(amp * delta,-1.0,1.0);
    }
    
    // Adding a very small amount of noise on init fixes subtle numerical precision blowup problems
    if (iFrame==0) fragColor=1e-6*rand4(fragCoord, iResolution.xy, iFrame);
}
