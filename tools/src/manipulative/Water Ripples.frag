#define CORRECT_TEXTURE_SIZE 0
#define TEXTURE_DOWNSCALE 2.0

#define VIEW_HEIGHT 0
#define VIEW_NORMALS 0
#define CHEAP_NORMALS 0

#define nsin(x) (sin(x) * 0.5 + 0.5)

float rand(vec2 uv, float t) {
    float seed = dot(uv, vec2(12.3435, 25.3746));
    return fract(sin(seed) * 234536.3254 + t);
}

vec2 scale_uv(vec2 uv, vec2 scale, vec2 center) {
	return (uv - center) * scale + center;
}

vec2 scale_uv(vec2 uv, vec2 scale) {
    return scale_uv(uv, scale, vec2(0.5));
}

float create_ripple(vec2 coord, vec2 ripple_coord, float scale, float radius, float range, float height) {
	float dist = distance(coord, ripple_coord);
    return sin(dist / scale) * height * smoothstep(dist - range, dist + range, radius);
}

vec2 get_normals(vec2 coord, vec2 ripple_coord, float scale, float radius, float range, float height) {
    return vec2(
        create_ripple(coord + vec2(1.0, 0.0), ripple_coord, scale, radius, range, height) -
        create_ripple(coord - vec2(1.0, 0.0), ripple_coord, scale, radius, range, height),
        create_ripple(coord + vec2(0.0, 1.0), ripple_coord, scale, radius, range, height) -
        create_ripple(coord - vec2(0.0, 1.0), ripple_coord, scale, radius, range, height)
    ) * 0.5;
}

vec2 get_center(vec2 coord, float t) {
    t = round(t + 0.5);
    return vec2(
        nsin(t - cos(t + 2354.2345) + 2345.3),
        nsin(t + cos(t - 2452.2356) + 1234.0)
    ) * iResolution.xy;
}

void mainImage(out vec4 color, vec2 coord) {
    vec2 ps = vec2(1.0) / iResolution.xy;
    vec2 uv = coord * ps;

    #if CORRECT_TEXTURE_SIZE
    vec2 tex_size = vec2(textureSize(iChannel0, 0));
    uv = scale_uv(uv, (iResolution.xy / tex_size) * float(TEXTURE_DOWNSCALE));
    #endif

    float timescale = 1.0;
    float t = fract(iTime * timescale);

    vec2 center = (iMouse.z > 0.0) ? iMouse.xy : get_center(coord, iTime * timescale);

    #if CHEAP_NORMALS
    float height = create_ripple(coord, center, t * 100.0 + 1.0, 100.0, 200.0, 1000.0);
    vec2 normals = vec2(dFdx(height), dFdy(height));
    #else
    vec2 normals = get_normals(coord, center, t * 100.0 + 1.0, 100.0, 200.0, 1000.0);
    #endif

    #if VIEW_HEIGHT
    color = vec4(height);
    #elif VIEW_NORMALS
    color = vec4(normals, 0.5, 1.0);
    #else
    color = texture(iChannel0, uv + normals * ps);
    #endif

    //t = round(iTime) * 20.0;

    //t = iTime;
    //color = vec4(rand(uv, t));
}
