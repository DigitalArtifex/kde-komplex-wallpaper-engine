// sleepy comments, most leftover from previous shader
// beware... i'll re-read tomorrow :D


#define T iTime

// @FabriceNeyret2 golfed this in my "Light Hall" shader
// the idea is that you pass in the movement frequency (f)
// the z offset (Z) and the radius (c), you then just do
// a sphere calc on p: length(p - offset) - radius
// the offset vec is composed of all the trig stuff below
// but it's basically just move x and y in squiggly lines
// and move z relative to iTime and the z offset
// T*3. because the camera is moving at T*3. speed as well
#define O(f,Z,c) abs( length(                 /* orb */   \
p - vec3( sin( sin(p.z*f*.5 ) +T*.7 ) * 3. ,        \
sin( sin(p.z*f*1.3) +T*.5 ) * 2.,  \
Z +8. +T*3. +cos(T*.3) *8. )  ) - c )

void mainImage(out vec4 o, vec2 u) {

    float l, // distance to light orb
    s, // spiral distance
    d, // total distance marched

    i, // raymarch iterator
    n; // noise iterator

    // p is resolution, then raymarch position
    vec3 p = iResolution;

    // scale coords
    u = (u-p.xy/2.)/p.y;


    // clear o, iterate 70 times, accumulate distance (d) and brightness (o)
    // .001+abs(min(s,l)) means take the min of the spiral and the lights,
    // and make it slightly translucent, *.7 to clean up some artifacts
    for(o*=i; i++<60.;d += s = .001+abs(min(s,l))*.5, o += 1./s/l)
        // this for-loop is the noise loop, before entering the loop body,
        // we march. the below is equivalent to p = ro + rd * d, p.z += T;
        // note that the orbs move at T*3. speed as well
        for (p = vec3(u * d, d+T*3.),

            // mirror
            p = abs(p),

             // it's just a mirrored plane with tanh wrapped around it to make it interesting
             // why tanh? i was using cos for repetition and was curious, so i tried
             // tanh, liked it, and kept it :)
             s = tanh(4.-abs(p.x)),


             // store dist to light in l
             l = .01 + .8 *  min( O(.5, 6., .4),
                                  min( O(.4, 3., .2),
                                       O(.3, 4., .3) )),


             // start noise at 1, while < 6, n *= 1.3
             // n += n works, n *= 1.x works, but keep in mind the number of iterations
             // the loop will need
             n = 1.; n < 6.; n *= 1.3 )
            // apply the noise with a scale of .3
            // add .5*T to p to make it move,
            // add p.z to make it less repetitive looking
            s += abs(dot(cos(.5*T+p.z+p*n), vec3(.3))) / n;

            // tanh tonemap, vec4 divides color by d (green and blue) for depth,
            // divide down brightness (o / 1e2),
            // divide by distance for depth
            // add a light in the center length(u),
            o = tanh(2.*abs(vec4(.1,4./d, d/3e1,0)) * o/1e2/max(d,15.) / max(length(u), .001));

            // @Shane color tip, mix o with swizzled components
            o = mix(o.zyxw, o.yxzw, smoothstep(0., 1., length(u)*2.));
}
