// "deadly_halftones"
// by Julien Vergnaud @duvengar-2018
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
//////////////////////////////////////////////////////////////////////////////////////

void mainImage(out vec4 C, in vec2 U)
{
    
    // sound amplitude
    float amp = .0;
    amp += .5 - texelFetch(iChannel1,ivec2(20,0),0).x + .5
       *texelFetch(iChannel1,ivec2(400,0),0).x;
     
    
   	// glitch offset 
    vec2 V  = 1. - 2. * U / R;  
    vec2 off = vec2(S(.0, amp * CEL * .5, cos(T + U.y / R.y  *5.0 )), .0) - vec2(.5, .0);
	
    // colorize
    float r = texture(iChannel0, .03 * off + U/ R).x;
    float g = texture(iChannel0, .04 * off + U/ R).x;
    float b = texture(iChannel0, .05 * off + U/ R).x;
    C = vec4(.0,.1,.2,1.);
    
    C += .06 * hash2(T + V * vec2(1462.439, 297.185));  // animated grain (hash2 function in common tab)
    C += vec4(r, g, b, 1.);
    C *= 1.25 *vec4(1. - S(.1, 1.8, length(V * V))); // vigneting
    
    U = mod(U,  CEL);
    C *= .4+sign(S(.99, 1., U.y));
    C += .14 * vec4(pow(1. - length(V*vec2(.5, .35)), 3.), .0,.0,1.);
}