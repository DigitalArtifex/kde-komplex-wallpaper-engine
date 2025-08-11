vec3 palette( float t ) {
    vec3 a = vec3(0.2, 0.2, 0.5); // blue has a greater default
    vec3 b = vec3(0.5, 0.5, 0.5); // all channels contribute
    vec3 c = vec3(0.1, 0.1, 0.4); // dampen blue oscillations
    vec3 d = vec3(0.0,0.33,0.67); // phase shifting by 0.33

    return a + b*cos( 6.28318*(c*t+d) );
}

float sdEquilateralTriangle( in vec2 p, in float r )
{
    const float k = sqrt(3.0);
    p.x = abs(p.x) - r;
    p.y = p.y + r/k;
    if( p.x+k*p.y>0.0 ) p = vec2(p.x-k*p.y,-k*p.x-p.y)/2.0;
    p.x -= clamp( p.x, -2.0*r, 0.0 );
    return -length(p)*sign(p.y);
}
float norm( in vec2 p )
{
    return sdEquilateralTriangle(p*1.5, 0.1);
}

void mainImage( out vec4 fragColour, in vec2 fragCoord ) {
    vec2 uv = (fragCoord *2.0 - iResolution.xy) / iResolution.y;
    uv = floor(uv*100.0f)/100.0f;
    vec2 uv0 = uv;
    vec3 finalColour = vec3(0.0);

    for (float i = 0.0; i < 4.0; i++) {
        uv = fract(uv * 1.5) - 0.5;

        float d = norm(uv) * exp(-norm(uv0));

        vec3 col = palette(norm(uv0) + i*.4 + iTime*.4);

        d = sin(d*8. + iTime)/8.;
        d = abs(d);
        d = pow(0.009 / d, 1.6);

        finalColour += col * d;
    }

    fragColour = vec4(finalColour, 1.0);
}
