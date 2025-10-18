// https://www.shadertoy.com/view/sldGW2

// Fork of "aberrating aberrations on video" by morisil. https://shadertoy.com/view/7tdGW2
// 2021-11-13 05:24:16

// Fork of "depth of field focus study 2" by morisil. https://shadertoy.com/view/flc3zX
// 2021-11-13 05:16:16

// Fork of "depth of field focus study" by morisil. https://shadertoy.com/view/sld3zB
// 2021-11-08 19:52:49

const float SHAPE_SIZE = .7;
const float CHROMATIC_ABBERATION = .02;
const float ITERATIONS = 5.;
const float INITIAL_LUMA = .6;

float getColorComponent(in vec2 st, in float modScale, in float blur) {
    vec2 modSt = mod(st, 1. / modScale) * modScale * 2. - 1.;
    float dist = length(modSt);
    float angle = atan(modSt.x, modSt.y);
    float shapeMap = smoothstep(SHAPE_SIZE + blur, SHAPE_SIZE - blur, dist);
    return shapeMap;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec2 st =
        (2.* fragCoord - iResolution.xy)
        / min(iResolution.x, iResolution.y);

    float modScale = 2.;

    vec3 color = vec3(0);
    float luma = INITIAL_LUMA;
    float blur = .2;
    for (float i = 0.; i < ITERATIONS; i++) {
        vec2 center = st + vec2(sin(iTime * .4), cos(iTime * .45)) * .3;
        //center += pow(length(center), 1.);
        vec2 modSt = mod(st, 1. / modScale) * modScale * 2. - 1.;
        vec3 shapeColor = vec3(
            getColorComponent(center - st * CHROMATIC_ABBERATION, modScale, blur),
            getColorComponent(center, modScale, blur),
            getColorComponent(center + st * CHROMATIC_ABBERATION, modScale, blur)
        ) * luma * texture(iChannel0, (center * vec2(-1, 1) + 1.) * .5).rgb;
        st *= 1.3;
        color += shapeColor;
        color = clamp(color, 0., 1.);
        if (color == vec3(1)) break;
        luma *= .63;
        blur *= .63;
    }
    fragColor = vec4(color, 1.0);
}
