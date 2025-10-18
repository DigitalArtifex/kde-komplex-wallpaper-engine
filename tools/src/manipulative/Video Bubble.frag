//https://www.shadertoy.com/view/3d2BWz

//The MIT License
//Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

float smooth_max(in float x, in float y, in float s) {
    float bridge =
    clamp(abs(x-y)/s, 0.0, 1.0);
    return max(x,y) + 0.25 * s * (bridge - 1.0) * (bridge - 1.0);
}

vec3 smooth_max(in vec3 x, in vec3 y, float s) {
    return vec3(smooth_max(x.x, y.x, s),
                smooth_max(x.y, y.y, s),
                smooth_max(x.z, y.z, s));
}

float smooth_min(in float x, in float y, in float s) {

    float bridge =
    clamp(abs(x-y)/s, 0.0, 1.0);
    return min(x,y) - 0.25 * s * (bridge - 1.0) * (bridge - 1.0);
}


vec3 smooth_min(in vec3 x, in vec3 y, float s) {
    return vec3(smooth_min(x.x, y.x, s),
                smooth_min(x.y, y.y, s),
                smooth_min(x.z, y.z, s));
}

#define MAX_DIST 8.0

#define SUPERSAMPLE 1 // per IQ, enable at your own risk
// #define SUPERSAMPLE 1 // it's a boolean

float length_1 = 0.4;
const float crinkle = 0.01375; // make this smaller to make grid finer

vec2 bright_clamp = vec2(0.0, 1.0); // ramp brightness values in this range to 0.0,1.0

#define HOLES_OR_RODS 1 // 1 for holes, 0 for rods

const vec3 light_dir = normalize(vec3(0.05, 0.05, -0.15));

float do_bright_clamp(in float x) {
#if !HOLES_OR_RODS
    // return clamp((x-bright_clamp.y)/(bright_clamp.x - bright_clamp.y), 0.0, 1.0);
	return smoothstep(bright_clamp.y, bright_clamp.x, x);
#else
    // return clamp((x-bright_clamp.x)/(bright_clamp.y - bright_clamp.x), 0.0, 1.0);
    return smoothstep(bright_clamp.x, bright_clamp.y, x);
#endif
}

float core_sdf(in vec3 pt) {
    const vec3 p1 = vec3(0.0, 0.45, 0.7);
    const vec3 p2 = -vec3(0.0, -0.1, 0.7);
    float d1 = length((pt - p1)* vec3(1.6)) - 3.1 * length_1;
    // float d1 = dot(pt - p1, normalize(p2 - p1)) - 1.85 * length_1;
    // float d2 = length((pt - p2) * vec3(1.6)) - 3.0 *  length_1;
    float d2 = dot(pt - p2, normalize(p1 - p2)) - 1.9 * length_1;
    // float d1 =  length((pt.xy + vec2(0.0, -0.15))) -0.8 *  length_1;
    return smooth_max(d1, d2, 0.05);
}

float wavefront(vec3 p) {
    return (1.0 - length_1) * smoothstep(0.0, length_1, abs(mod(p.x, 2.0 * length_1) - length_1))
        + length_1 * smoothstep(0.0, length_1, p.y * (p.x + p.y));
}

float sdf(in vec3 pt) {
    float result = core_sdf(pt);
    if (abs(result) < 14.0 * crinkle) {
        vec3 cell_rel = mod(pt, vec3(2.0 * crinkle)) - 1.0 * vec3(crinkle);
        cell_rel.z = 0.5 * result;
        vec3 cell_center = pt - cell_rel;
        cell_rel.xy = abs(cell_rel.xy);
        vec2 uv = cell_center.xy * 2.0 * iResolution.yx/iResolution.x + vec2(0.5, 0.0);
        float max_hole_size = crinkle * 1.0;
        float hole_size = max_hole_size * do_bright_clamp(dot(texture(iChannel0, uv).rgb, 0.8 * vec3(1.0, 0.75, 0.75)));
        float in_image = step(0.0, uv.x) * step(0.0, uv.y) * step(uv.x, 1.0) * step(uv.y, 1.0);
        hole_size = mix(max_hole_size, hole_size, in_image);
        cell_rel.xy = max(vec2(0.0), cell_rel.xy - vec2(0.5 * hole_size));
        float hole_dist = 0.5 * hole_size - length(cell_rel.xy);
#if HOLES_OR_RODS
        result = smooth_max(result, hole_dist, 0.05 * max_hole_size);
#else
        result = smooth_max(result, -hole_dist, 0.05 * max_hole_size);
#endif
       // result -= crinkle * smoothstep(0.0, 0.8, simple_noise(32.0 * pt, 28.1));
    }
    return result;
}

vec3 sdf_grad(in vec3 pt) {
    float f = sdf(pt);
    const float h = 0.001;
    const float h_inv = 1000.0;

    return h_inv *
        vec3(sdf(pt + vec3(h, 0.0, 0.0)) - f,
             sdf(pt + vec3(0.0, h, 0.0)) - f,
             sdf(pt + vec3(0.0, 0.0, h)) - f);
}



float raymarch(in vec3 pt, in vec3 dir, out float sumdist) {
    vec3 d = normalize(dir);
    vec3 p = pt;
    float accum = 0.0;
    float s = sdf(pt);
    sumdist = 0.0;
    for(int i = 0; i < 512; ++i) {
        if (accum > MAX_DIST || s < 1.0e-3) {
            return accum;
        }
        accum += 0.25 * s;
        p = pt + accum * d;
        s = sdf(p);
        sumdist = sumdist + 0.25 * s / max(s, 1.0e-3);
    }
    if (s > 1.0e-3) {
        return MAX_DIST + 1.0;
    }
    return accum;
}

float raymarch_out(in vec3 pt, in vec3 dir) {
    vec3 d = normalize(dir);
    vec3 p = pt;
    float total_step = 0.0;
    float accum = 0.0;
    float s = core_sdf(pt);
    for(int i = 0; i < 256; ++i) {
        if (total_step > MAX_DIST) {
            return accum;
        }
        float curr_step = 0.75 * max(abs(s), 1.0e-3);
        total_step += curr_step;
        accum += curr_step * step(s, 0.0);
        p = pt + total_step * d;
        s = core_sdf(p);
    }
    return accum;
}

float ramp(in float a, in float b, in float x) {
    float p = (x-a)/(b-a);
    return clamp(p, 0.0, 1.0);
}

vec4 color_at(in vec2 fragCoord ) {
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = (2.0 * fragCoord - iResolution.xy) / iResolution.y;

    vec3 dir = normalize(vec3(uv, 6.0));

    vec3 orig = vec3(0.0, 0.25, -1.5);

    float theta = 0.0625 * sin(0.25 * iTime) + 3.141592654;
    float ct = cos(theta);
    float st = sin(theta);

    mat3 spin = mat3(ct, 0.0, st,
                     0.0, 1.0, 0.0,
                     -st, 0.0, ct);

    theta = 0.25 * sin(iTime);
    vec2 trigs = cos(vec2(theta, theta + 0.5 * 3.141592654));
    ct = 0.8 * trigs.x - 0.6 * trigs.y;
    st = 0.6 * trigs.x + 0.8 * trigs.y;
	theta = 0.25 * sin(1.21 * iTime);
    trigs = cos(vec2(theta, theta + 0.5 * 3.141592654));
    ct = 0.6 * trigs.x - 0.8 * trigs.y;
    st = 0.8 * trigs.x + 0.6 * trigs.y;


    theta = 0.25 * sin(0.93 * iTime);
    trigs = cos(vec2(theta, theta + 0.5 * 3.141592654));
    ct = 0.8 * trigs.x - 0.6 * trigs.y;
    st = 0.6 * trigs.x + 0.8 * trigs.y;

    orig = spin * orig;
    dir = spin * dir;

    float cloud_integral = 0.0;

    float dist = raymarch(orig, dir, cloud_integral);

    vec3 color_mul = vec3(1.0);


    vec3 col = vec3(0.0);
    vec3 refl_color = 1.0 * vec3(0.8, 1.0, 0.5);
    vec3 trans_color = 1.0 * vec3(1.0, 0.1, 0.5); // 1.0 , 0.5, 0.4);
    float thru_dist = 1000.0;
    vec3 n = dir;
    if (dist < MAX_DIST) {
        vec3 pt = orig + dir * dist;
        thru_dist = raymarch_out(pt, light_dir);
        n = normalize(sdf_grad(pt));
        dir = normalize(reflect(dir, n));



    	col = (0.8 * smoothstep(0.99, 1.0, dot(dir, light_dir)) + 0.5 * smoothstep(0.2, 1.0, dot(n, light_dir)))*
        	refl_color;

	    float pen_length = 0.1 * length_1; //  10.25 * crinkle;
    	float soften_subsurface = 1.0;

	    col += ( soften_subsurface * pen_length / max(abs(soften_subsurface *  thru_dist), pen_length)) * trans_color;

    }
    float sweep = 20.0 * fragCoord.x / iResolution.x + smoothstep(0.0, iResolution.y, fragCoord.y);
    float cloud_modulate = 0.25; //  + 0.25 * sin(1.71 * iTime + sweep);
    float cloud_contrib =  0.05 * cloud_modulate * cloud_integral;
    // cloud_contrib *= smoothstep(0.4, 0.6, cloud_contrib);
    col +=  1.0 * vec3(-1.0, 1.0, 1.0) * cloud_contrib;

    // col = vec3(freckles, 0.0);
    // Output to screen
    return  vec4(color_mul * col,1.0);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // length_1 += 0.05 * length_1 * sin(0.11 * iTime);


	vec4 col_out = color_at(fragCoord);
#if SUPERSAMPLE
    col_out *= 0.25;
    const float scatter_scale = 0.8;
    col_out += 0.25 * color_at(fragCoord + scatter_scale * vec2(0.6, 0.8));
    col_out += 0.25 * color_at(fragCoord + scatter_scale * vec2(-1.0, 0.0));
    col_out += 0.25 * color_at(fragCoord + scatter_scale * vec2(0.0, -1.0));
#endif
    fragColor = col_out;
}
