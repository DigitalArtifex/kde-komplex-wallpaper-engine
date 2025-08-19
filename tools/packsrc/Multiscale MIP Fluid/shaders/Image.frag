/* 
	Created by Cornus Ammonis (2019)
	Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
*/

/*
	This is a mipmap-based approach to multiscale fluid dynamics.

	Check the Common tab for lots of configurable parameters.

	Click to interact with your mouse. I'd recommend turning off the "pump" by
	setting PUMP_SCALE to 0.0 on line 113 of the Common tab to play around with
	just mouse interaction.

	Buffer B is a multiscale method for computing turbulence along the lines of 
	the Large Eddy Simulation method; multiscale curl is also computed in Buffer B, 
    to be passed along to Buffer C.
	
	Buffer C is a fairly conventional Vorticity Confinement method, also multiscale, 
    using the curl computed in Buffer B. It probably makes more sense to compute 
    each curl scale separately before accumulating, but for the sake of efficiency 
    and simplicity (a larger kernel would be required), I haven't done that here.

	Buffer D is a multiscale Poisson solver, which converges rapidly but not to an 
    exact solution - this nonetheless works well for the purposes of divergence 
    minimization since we only need the gradient, with allowances for the choice of
    scale weighting. 

	Buffer A computes subsampled advection and velocity update steps, sampling
    from Buffers B, C, and D with a variety of smoothing options.

	There are a number of options included to make this run faster.

	Using mipmaps in this way has a variety of advantages:

	1. The scale computations have no duplicative or dependent reads, we only need 
       that for advection.
	2. No randomness or stochastic sampling is involved.
	3. The total number of reads can be greatly reduced for a comparable level of 
       fidelity to some other methods.
	4. We can easily sample the entire buffer in one pass (on average).
	5. The computational complexity is deferred to mipmap generation (though with
       a large coefficient), because: 
	6. The algorithm itself is O(n) with a fixed number of scales (or we could 
       potentially do scale calculations in parallel with mipmap generation, 
       equalling mipmap generation complexity at O(nlogn))

	Notable downsides:

	1. Using mipmaps introduces a number of issues, namely:
       a. Mipmaps can introduce artifacts due to interpolation and downsampling. 
          Using Gaussian pyramids, or some other lowpass filtering method would 
          be better. 
       b. Using higher-order sampling of the texture buffer (e.g. bicubic) would 
          also be better, but that would limit our performance gains. 
       c. NPOT textures are problematic (as always). They can introduce weird 
          anisotropy issues among other things.
	2. Stochastic or large-kernel methods are a better approximation to the true
       sampling distribution approximated here, for a large-enough number of
       samples.
    3. We're limited in how we construct our scale-space. Is a power-of-two stride 
       length on both axes always ideal, even along diagonals? I'm not particularly 
       sure. There are clever wavelet methods out there for Navier-Stokes solvers, 
       and LES in particular, too.

*/

#define BUMP 3200.0

#define D(d) -textureLod(iChannel1, fract(uv+(d+0.0)), mip).w

vec2 diff(vec2 uv, float mip) {
    vec2 texel = 1.0/iResolution.xy;
    vec4 t = float(1<<int(mip))*vec4(texel, -texel.y, 0);

    float d =    D( t.ww); float d_n =  D( t.wy); float d_e =  D( t.xw);
    float d_s =  D( t.wz); float d_w =  D(-t.xw); float d_nw = D(-t.xz);
    float d_sw = D(-t.xy); float d_ne = D( t.xy); float d_se = D( t.xz);
    
    return vec2(
        0.5 * (d_e - d_w) + 0.25 * (d_ne - d_nw + d_se - d_sw),
        0.5 * (d_n - d_s) + 0.25 * (d_ne + d_nw - d_se - d_sw)
    );
}

vec4 contrast(vec4 col, float x) {
	return x * (col - 0.5) + 0.5;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ){
    vec2 uv = fragCoord.xy / iResolution.xy;

    vec2 dxy = vec2(0);
    float occ, mip = 0.0;
    float d   = D();
    
    // blur the gradient to reduce appearance of artifacts,
    // and do cheap occlusion with mipmaps
    #define STEPS 10.0
    #define ODIST 2.0
    for(mip = 1.0; mip <= STEPS; mip += 1.0) {	 
        dxy += (1.0/pow(2.0,mip)) * diff(uv, mip-1.0);	
    	occ += softclamp(-ODIST, ODIST, d - D(),1.0)/(pow(1.5,mip));
    }
    dxy /= float(STEPS);
    
    // I think this looks nicer than using smoothstep
    occ = pow(max(0.0,softclamp(0.2,0.8,100.0*occ + 0.5,1.0)),0.5);
 
    vec3 avd;
    vec3 ld = light(uv, BUMP, 0.5, dxy, iTime, avd);
    
    float spec = ggx(avd, vec3(0,1,0), ld, 0.1, 0.1);
    
    #define LOG_SPEC 1000.0
    spec = (log(LOG_SPEC+1.0)/LOG_SPEC)*log(1.0+LOG_SPEC*spec);    
    
    #define VIEW_VELOCITY
    
    #ifdef VIEW_VELOCITY
		vec4 diffuse = softclamp(0.0,1.0,6.0*vec4(texture(iChannel0,uv).xy,0,0)+0.5,2.0);    
    #elif defined(VIEW_CURL)
		vec4 diffuse = mix(vec4(1,0,0,0),vec4(0,0,1,0),softclamp(0.0,1.0,0.5+2.0*texture(iChannel2,uv).w,2.0));    
    #elif defined(VIEW_ADVECTION)
		vec4 diffuse = softclamp(0.0,1.0,0.0004*vec4(texture(iChannel0,uv).zw,0,0)+0.5,2.0); 
    #elif defined(VIEW_GRADIENT)
    	vec4 diffuse = softclamp(0.0,1.0,10.0*vec4(diff(uv,0.0),0,0)+0.5,4.0); 
    #else // Vorticity confinement vectors
    	vec4 diffuse = softclamp(0.0,1.0,4.0*vec4(texture(iChannel3,uv).xy,0,0)+0.5,4.0);
    #endif
    
    fragColor = (diffuse + 4.0*mix(vec4(spec),1.5*diffuse*spec,0.3));
    fragColor = mix(1.0,occ,0.7) * (softclamp(0.0,1.0,contrast(fragColor,4.5),3.0));
    
    //fragColor = vec4(occ);
    //fragColor = vec4(spec);
    //fragColor = diffuse;
    //fragColor = vec4(diffuse+(occ-0.5));
}