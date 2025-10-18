// https://www.shadertoy.com/view/4dl3z8

const float blurAmount=.00017;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
 	vec2 xy = fragCoord.xy/iResolution.xy;
	vec2 center=iResolution.xy/2.;
	vec2 diff=xy-center;
	float dist=dot(diff,diff)*0.0004;
	vec2 amount=vec2((center.x-xy.x)*blurAmount*dist,0.);
	vec4 tx;

	tx=texture(iChannel0, xy+amount*-0.02)*vec4(0.666,0.0,0.0,0.2);
	tx+=texture(iChannel0, xy+amount*-0.01)*vec4(0.333,0.25,0.0,0.2);
	tx+=texture(iChannel0, xy)*vec4(0.0,0.5,0.0,0.2);
	tx+=texture(iChannel0, xy+amount*0.01)*vec4(0.0,0.25,0.333,0.2);
	tx+=texture(iChannel0, xy+amount*0.02)*vec4(0.0,0.0,0.667,0.2);

	fragColor = tx;
}
