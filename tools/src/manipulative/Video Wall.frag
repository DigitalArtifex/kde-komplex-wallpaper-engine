// https://www.shadertoy.com/view/MlX3Rs

vec4 white = vec4(1.0,1.0,1.0,0.0);
vec4 black = vec4(0.0,0.0,0.0,1.0);

vec4 noise(vec4 c,vec2 px)
{
    vec2 uv = px / iResolution.xy;

    vec4 r = texture(iChannel0,uv+vec2(sin(iTime*10.0),sin(iTime*20.0)));

    c += r * 0.2;

    return c;
}

vec4 colorFilter(vec4 c)
{
	float g = (c.x + c.y + c.z) / 3.0;
    c = vec4(g,g,g,1.0);

    c.x *= 0.3;
    c.y *= 0.5;
    c.z *= 0.7;

    return c;
}

vec4 frame(vec4 c,vec2 px)
{
    vec2 uv = px / iResolution.xy;

    float d = 0.59;
    float e = 3.8;

    c += 0.4*pow(distance(uv,vec2(0.5,0.5)) / d,e);

	return c;
}

vec4 scanline(vec4 c, vec2 px)
{
    vec2 uv = px / iResolution.xy;

    float y = mod(-iTime / 10.0,1.1);

    float d = sqrt(abs(uv.y - y));

    float a = 1.0 - smoothstep(0.001,0.2,d);

    c = noise(noise(noise(white,px),px),px) * (a*0.5) + (c * (1.0-a));

    return c;

}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{

	vec2 uv = fragCoord.xy / iResolution.xy;

    float aspect = iResolution.x / iResolution.y;

    float squares = pow((1.0 + float(int(mod(2.0+iTime / 3.5,5.0)))),2.0);

    vec4 c = black;

    float sw = sqrt(squares) / aspect;
    float sh = sqrt(squares);


    float b = float(int(mod(uv.y*sh,2.0)));
    // a(0 || 1) selects square
	float a = float(int(mod(uv.x*sw * aspect + b,2.0)));

	// Texture coordinates
    float vx = mod(uv.x * sw * aspect, 1.0);
    float vy = mod(uv.y * sh*-1.0, 1.0);

   	c += texture(iChannel1,vec2(vx,vy)) * (1.0-a);
    c += texture(iChannel2,vec2(vx,vy)) * a;


    c = noise(c,fragCoord);
    //c = scanline(c,fragCoord);
    c = colorFilter(c);

	c = frame(c,fragCoord);

    c = clamp(black,c,white);

	fragColor = c;
}
