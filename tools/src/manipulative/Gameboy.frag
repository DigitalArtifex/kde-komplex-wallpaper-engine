float size = 128.; // Pixelated resolution x-component
float threshold = .006; // Threshold for dithering (0.0045 found to be optimal)
mat2 dither_2 = mat2(0.,1.,1.,0.);

struct dither_tile {
    float height;
};


vec3[4] gb_colors() {
 	vec3 gb_colors[4];
    gb_colors[0] = vec3(15., 56., 15.)		/255.;
    gb_colors[1] = vec3(48., 98., 48.)		/255.;
    gb_colors[2] = vec3(139., 172., 15.)	/255.;
    gb_colors[3] = vec3(155., 188., 15.)	/255.;
    return gb_colors;
}

float[4] gb_colors_distance(vec3 color) {
    float distances[4];
    distances[0] = distance(color, gb_colors()[0]);
    distances[1] = distance(color, gb_colors()[1]);
    distances[2] = distance(color, gb_colors()[2]);
    distances[3] = distance(color, gb_colors()[3]);
    return distances;
}

vec3 closest_gb(vec3 color) {
    int best_i = 0;
    float best_d = 2.;

    vec3 gb_colors[4] = gb_colors();

    for (int i = 0; i < 4; i++) {
        float dis = distance(gb_colors[i], color);;
        if (dis < best_d) {
            best_d = dis;
            best_i = i;
        }
    }


    return gb_colors[best_i];
}

vec2 get_tile_sample(vec2 coords, vec2 res) {
    return floor(coords * res / 2.) * 2. / res;
}

vec3[2] gb_2_closest(vec3 color) {
 	float distances[4] = gb_colors_distance(color);

    int first_i = 0;
    float first_d = 2.;

    int second_i = 0;
    float second_d = 2.;

    for (int i = 0; i < distances.length(); i++) {
        float d = distances[i];
        if (distances[i] <= first_d) {
            second_i = first_i;
            second_d = first_d;
            first_i = i;
            first_d = d;
        } else if (distances[i] <= second_d) {
            second_i = i;
            second_d = d;
        }
    }
    vec3 colors[4] = gb_colors();
    vec3 result[2];
    if (first_i < second_i) {
        result = vec3[2](colors[first_i], colors[second_i]);
    } else {
     	result = vec3[2](colors[second_i], colors[first_i]);
    }


    return result;
}

bool needs_dither(vec3 color) {
    float distances[4] = gb_colors_distance(color);

    int first_i = 0;
    float first_d = 2.;

    int second_i = 0;
    float second_d = 2.;

    for (int i = 0; i < distances.length(); i++) {
        float d = distances[i];
        if (d <= first_d) {
            second_i = first_i;
            second_d = first_d;
            first_i = i;
            first_d = d;
        } else if (d <= second_d) {
            second_i = i;
            second_d = d;
        }
    }
    return abs(first_d - second_d) <= threshold;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec2 resolution = vec2(size, iResolution.y / iResolution.x * size);
    vec2 uv = floor(fragCoord/iResolution.xy * resolution) / resolution;

    vec2 tileSample = get_tile_sample(uv, resolution);
    vec3 sampleColor = texture(iChannel0, tileSample).xyz;

    vec3 colors[2] = vec3[2](vec3(1.,1.,1.), vec3(0.,0.,0.));

    if (needs_dither(sampleColor)) {
        ivec2 ti = ivec2(floor((uv - tileSample) * 2. * resolution));
        //fragColor = vec4(closest_gb(texture(iChannel0, uv).xyz),1.0);
        fragColor = vec4(gb_2_closest(sampleColor)[int(dither_2[ti.x][ti.y])], 1.);

        //fragColor = vec4(colors[int(dither_2[ti.x][ti.y])], 1.);
    } else {
        fragColor = vec4(closest_gb(texture(iChannel0, uv).xyz),1.0);
    }

    // Output to screen

}
