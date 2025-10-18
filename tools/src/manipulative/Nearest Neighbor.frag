const int half_width = 5;

// Calculate color distance
float CalcDistance(in vec3 c0, in vec3 c1) {
    vec3 sub = c0 - c1;
    return dot(sub, sub);
}

// Symmetric Nearest Neighbor
vec3 CalcSNN(in vec2 fragCoord) {
    vec2 src_size = iResolution.xy;
    vec2 inv_src_size = 1.0f / src_size;
    vec2 uv = fragCoord * inv_src_size;

    vec3 c0 = texture(iChannel0, uv).rgb;

    vec4 sum = vec4(0.0f, 0.0f, 0.0f, 0.0f);

    for (int i = 0; i <= half_width; ++i) {
        vec3 c1 = texture(iChannel0, uv + vec2(+i, 0) * inv_src_size).rgb;
        vec3 c2 = texture(iChannel0, uv + vec2(-i, 0) * inv_src_size).rgb;

        float d1 = CalcDistance(c1, c0);
        float d2 = CalcDistance(c2, c0);
        if (d1 < d2) {
            sum.rgb += c1;
        } else {
            sum.rgb += c2;
        }
        sum.a += 1.0f;
    }
    for (int j = 1; j <= half_width; ++j) {
        for (int i = -half_width; i <= half_width; ++i) {
            vec3 c1 = texture(iChannel0, uv + vec2(+i, +j) * inv_src_size).rgb;
            vec3 c2 = texture(iChannel0, uv + vec2(-i, -j) * inv_src_size).rgb;

            float d1 = CalcDistance(c1, c0);
            float d2 = CalcDistance(c2, c0);
            if (d1 < d2) {
                sum.rgb += c1;
            } else {
                sum.rgb += c2;
            }
            sum.a += 1.0f;
        }
    }
    return sum.rgb / sum.a;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 src_size = iResolution.xy;
    vec2 inv_src_size = 1.0f / src_size;
    vec2 uv = fragCoord * inv_src_size;

    float center = iMouse.x * inv_src_size.x;
    float width = 3.0f * inv_src_size.x * 0.5f;

    if (uv.x <= center - width) {
    	fragColor.rgb = CalcSNN(fragCoord);
    } else if (uv.x >= center + width) {
        fragColor.rgb = CalcSNN(fragCoord);
    } else {
        fragColor.rgb = vec3(0, 0, 0);
    }

    fragColor.a = 1.0f;
}
