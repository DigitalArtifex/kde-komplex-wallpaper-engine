// @license MIT
// @author ciphrd
//
// This algorithm is sort of a probabilistic quad tree construction where quad divisions are
// added if the color variation (variance) in a quad is too important.
//
// The color variation is computed by taking n samples within the quad, and then we compute the
// variance on each color component of the samples.
//
//
// Limitations
//
// If a certain area, which is large, has a small section of it being detailed while the rest
// is pretty much linear, divisions might not be added. Because this algorithm picks random
// points in the quad, the small detailed section has little to no infuence on the overall
// variations of the colors in the quad.
// You can observe this behavior on the Google logo when it appears.
//


// the number of divisions at the start
#define MIN_DIVISIONS 4.0

// the numer of possible quad divisions
#define MAX_ITERATIONS 8

// the number of samples picked fter each quad division
#define SAMPLES_PER_ITERATION 55
#define F_SAMPLES_PER_ITERATION 54.95

// useless, kept it for reference for a personal usage
#define MAX_SAMPLES 200

// threshold min, max given the mouse.x
#define THRESHOLD_MIN 0.0001
#define THRESHOLD_MAX 0.01

vec2 centrePoints[4*4*4*4*4*4];
int centrePointCount = 0;



// taken from http://glslsandbox.com/e#41197.0
vec2 hash22(vec2 p) {
    float n = sin(dot(p, vec2(41, 289)));
    return fract(vec2(262144, 32768)*n);
}


// Computes the color variation on a quad division of the space
// Basically, this method takes n random samples in a given quad, compute the average
// of each color component of the samples.
// Then, it computes the variance of the samples
// This is the way I thought for computing the color variation, there might be others,
// and there must be better ones
vec4 quadColorVariation (in vec2 center, in float size) {
    // this array will store the grayscale of the samples
    vec3 samplesBuffer[SAMPLES_PER_ITERATION];

    // the average of the color components
    vec3 avg = vec3(0);

    // we sample the current space by picking pseudo random samples in it
    for (int i = 0; i < SAMPLES_PER_ITERATION; i++) {
        float fi = float(i);
        // pick a random 2d point using the center of the active quad as input
        // this ensures that for every point belonging to the active quad, we pick the same samples
        vec2 r = hash22(center.xy + vec2(fi, 0.0)) - 0.5;
        vec3 sp = texture(iChannel0, center + r * size).rgb;
        avg+= sp;
        samplesBuffer[i] = sp;
    }

    avg/= F_SAMPLES_PER_ITERATION;

    // estimate the color variation on the active quad by computing the variance
    vec3 var = vec3(0);
    for (int i = 0; i < SAMPLES_PER_ITERATION; i++) {
    	var+= pow(samplesBuffer[i], vec3(2.0));
    }
    var/= F_SAMPLES_PER_ITERATION;
    var-= pow(avg, vec3(2.0));

    return vec4(avg, (var.x+var.y+var.z)/3.0);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    float threshold = mix(THRESHOLD_MIN, THRESHOLD_MAX, iMouse.x / iResolution.x);

    // number of space divisions
    float divs = MIN_DIVISIONS;

    // the center of the active quad - we initialze with 2 divisions
    vec2 quadCenter = (floor(uv * divs) + 0.5) / divs;
    float quadSize = 1. / divs; // the length of a side of the active quad

    // we store average and variance here
    vec4 quadInfos = vec4(0);

    for (int i = 0; i < MAX_ITERATIONS; i++) {
    	quadInfos = quadColorVariation(quadCenter, quadSize);

    	// if the variance is lower than the threshold, current quad is outputted
        if (quadInfos.w < threshold) {
            if(centrePointCount < MAX_ITERATIONS) centrePoints[centrePointCount++] = quadCenter;

            break;
        }

        // otherwise, we divide the space again
        divs*= 2.0;
        quadCenter = (floor(uv * divs) + 0.5) / divs;
        quadSize/= 2.0;
    }



    vec4 color = texture(iChannel0, uv);

    // the coordinates of the quad
    vec2 nUv = fract(uv * divs);

    // we create lines from the uv coordinates
    vec2 lWidth = vec2(0.5/iResolution.x, 0.5/iResolution.y);
    vec2 uvAbs = abs(nUv-0.5);
    float s = step(0.5-uvAbs.x, lWidth.x*divs) + step(0.5-uvAbs.y, lWidth.y*divs);

    // we smooth the color between average and texture initial
    color.rgb = mix(color.rgb, quadInfos.rgb, uv.x);

    // we smooth the lines over the x axis
    // s*= pow(1. - uv.x, 4.0);

    // for black lines, we just subtract
    color.r = mod(color.r, s);
    color.g = mod(color.g, s);
    color.b = mod(color.b, s);
    color.a = mod(color.a, s);

    // Output to screen
    fragColor = color;
}
