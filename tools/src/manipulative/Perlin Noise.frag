// https://www.shadertoy.com/view/43c3zf

vec2 GetGradient(vec2 intPos, float t) {

    // Uncomment for calculated rand
    //float rand = fract(sin(dot(intPos, vec2(12.9898, 78.233))) * 43758.5453);;

    // Texture-based rand (a bit faster on my GPU)
    float rand = texture(iChannel0, intPos / 64.0).r;

    // Rotate gradient: random starting rotation, random rotation rate
    float angle = 6.283185 * rand + 4.0 * t * rand;
    return vec2(cos(angle), sin(angle));
}

float Pseudo3dNoise(vec3 pos) {
    vec2 i = floor(pos.xy);
    vec2 f = pos.xy - i;
    vec2 blend = f * f * (3.0 - 2.0 * f);
    float noiseVal =
        mix(
            mix(
                dot(GetGradient(i + vec2(0, 0), pos.z), f - vec2(0, 0)),
                dot(GetGradient(i + vec2(1, 0), pos.z), f - vec2(1, 0)),
                blend.x),
            mix(
                dot(GetGradient(i + vec2(0, 1), pos.z), f - vec2(0, 1)),
                dot(GetGradient(i + vec2(1, 1), pos.z), f - vec2(1, 1)),
                blend.x),
        blend.y
    );
    return noiseVal / 0.7; // normalize to about [-1..1]
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
	vec2 noise_uv = fragCoord.xy/iResolution.y;
    float noiseVal = 0.5 + 0.5 * Pseudo3dNoise(vec3(noise_uv * 10.0, iTime));

    vec2 uv = fragCoord/iResolution.xy;
    float noiseWeight = 0.05;
    uv.x += noiseVal * noiseWeight;
    uv.y += noiseVal * noiseWeight;
    vec3 col = texture(iChannel0,uv).rgb;

    fragColor.rgb = vec3(col);

}
