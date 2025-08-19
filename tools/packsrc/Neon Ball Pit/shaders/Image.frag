void mainImage(out vec4 o, vec2 u) {
    o = sampleDof(iChannel0, iResolution.xy, vec2(.71, -.71), u);
    float r = floor(log2(iResolution.y) - 5.5) + .5;
    for(int i = 0; i < 4; i++)
        o += texture(iChannel0, u/iResolution.xy, r+float(i*2))*.03;
    vec3 x = o.rgb;
    o = vec4((x*(2.51*x+.03))/(x*(2.43*x+.59)+.14), 1.);
}