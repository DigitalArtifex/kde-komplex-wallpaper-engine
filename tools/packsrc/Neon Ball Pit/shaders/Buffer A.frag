vec4 sphereI(vec3 pos, const vec3 dir, vec3 sPos){
    pos -= sPos;
	float b = -dot(pos, dir);
	float d = b * b - dot(pos, pos) + .2;
	if (d < 0.0) return vec4(-1.);
	b -= sqrt(d);
	return vec4(normalize(pos+b*dir), b);
}

vec4 sceneI(const vec3 pos, const vec3 dir) {
    vec3 s = sign(dir);
    float t   = max(0., -(pos.y+s.y*1.3)/dir.y);
    float end = max(0., -(pos.y-s.y*1.0)/dir.y);
    for(int i = 0; i < 16 && t < end; i++) {
        vec3 p = pos+t*dir;
        vec2 fp = floor(p.xz);
        vec2 co = cos(fp*.5+iTime);
        vec4 sI = sphereI(pos, dir, vec3(fp+.5, co.x*co.y).xzy);
        if(sI.w > 0.) return sI;
        vec2 l = (s.xz*.5+.5+fp-p.xz) / dir.xz;
        t += min(l.x, l.y) + .1;
    }
    return vec4(-1.);
}

void mainImage(out vec4 o, vec2 u) {
    mat3 rot = rotationMatrix(vec3(-.7, iTime*.15, 0.));
    o = vec4(0.);
    for(int y = 1; y <= AA; y++) {
        for(int x = 1; x <= AA; x++) {
            vec2 uv = (floor(u)+vec2(x, y)/float(AA+1)-iResolution.xy*.5) / iResolution.y;
            vec3 pos = vec3(0., 0., 7.) * rot;
            vec3 dir = normalize(vec3(uv, -1.)) * rot;
            pos.x += iTime*2.;
            float att = 1.;
            float d = 10.;
            for(int i = 0; i < 2; i++) {
                vec4 t = sceneI(pos, dir);
                if(t.w < 0.) break;
                if(i == 0) d = t.w;
                pos += t.w*dir;
                vec3 orientation = normalize(vec3(cos(floor(pos.xz) - iTime), .5).xzy);
                vec3 emission = abs(dot(t.xyz, orientation)) < .2 ? (orientation.yxz+1.) : vec3(.0);
                emission *= 4.*abs(fract(orientation.y*5.)*2.-1.);
                float f = fresnel(dir, t.xyz);
                o.rgb += att*(1.-f) * emission;
                att *= f;
                dir = reflect(dir, t.xyz);
            }
            o += vec4(att*vec3(1., 1.5, 2.)*step(0., dir.y), d);
        }
    }
    o /= float(AA*AA);
}