void mainImage(out vec4 o, vec2 u) {
    o = sampleDof(iChannel0, iResolution.xy, vec2(.71, .71), u);
}