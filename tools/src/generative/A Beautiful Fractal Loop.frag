// Fractal base used taken from https://www.shadertoy.com/view/lslGWr and tweaked.
// 407 chars made by: Aaron1924
// 383 left with removed define
float f(vec3 p) 
{
	float a, l, t, i;

	for (;++i < 32.;) 
    {
		float m = dot(p, p);
		p = abs(p) / m + .4 * vec2(cos(iTime/4.), sin(iTime/4.)).xxy - .5;
        
		float w = exp(-.2*i);
		a += w * exp(-9.5 * pow(abs(m - l), 2.3));
		t += w, l = m;
	}
    
	return max(0., 5. * a / t - .7);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 R = iResolution, p = (vec3(fragCoord, 0) - .5 * R) / R.y;
    fragColor = pow(vec4(f(p)),vec4(1,2,3,0)) * pow(vec4(f(p*2.5)),vec4(3,2,1,0));
}