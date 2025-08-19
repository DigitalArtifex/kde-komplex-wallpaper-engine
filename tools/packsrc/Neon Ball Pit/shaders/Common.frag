// uncomment this line for a faster version
//#define LOW_QUALITY


#ifdef LOW_QUALITY
#define AA 1
#define DOF_SAMPLES 3
#else
#define AA 2
#define DOF_SAMPLES 6
#endif


#define APERTURE .01
#define DOF_CLAMPING .7
#define FOCAL_DISTANCE 8.

vec4 sampleDof(sampler2D channel, vec2 channelDim, vec2 dir, vec2 u) {
    float screenAperture = channelDim.y*APERTURE;
    float sampleToRad = screenAperture * DOF_CLAMPING / float(DOF_SAMPLES);
    vec4 o = vec4(0);
    float sum = 0.;
    for(int i = -DOF_SAMPLES; i <= DOF_SAMPLES; i++) {
        float sRad = float(i)*sampleToRad;
        vec4 p = texture(channel, (u+dir*sRad)/channelDim);
        float rad = min(abs(p.a-FOCAL_DISTANCE)/p.a, DOF_CLAMPING);
        float influence = clamp((rad*screenAperture - abs(sRad)) + .5, 0., 1.) / (rad*rad+.001);
        o += influence * p;
        sum += influence;
    }
    return o/sum;
}

float fresnel(const vec3 dir, const vec3 n) {
    const float ior = 1.8;
    const float r0 = ((1. - ior) / (1. + ior)) * ((1. - ior) / (1. + ior));
    float x = 1.+dot(n, dir);
    return r0 + (1.-r0) * x*x*x*x*x;
}

mat3 rotationMatrix(const vec3 rotation) {
    vec3 c = cos(rotation), s = sin(rotation);
    mat3 rx = mat3(1, 0, 0, 0, c.x, -s.x, 0, s.x, c.x);
    mat3 ry = mat3(c.y, 0, -s.y, 0, 1, 0, s.y, 0, c.y);
    mat3 rz = mat3(c.z, -s.z, 0, s.z, c.z, 0, 0, 0, 1);
    return rz * rx * ry;
}