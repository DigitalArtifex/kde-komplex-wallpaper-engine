//const float gridSize = iResolution.x*0.1;

bool circleTest(vec2 pos, vec2 size, vec2 uv){
    if(distance(pos,uv) < size.x){
        return true;
    } else {
        return false;
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.y;

    float gridSize = iResolution.x*0.05;

    uv = fract(uv*gridSize);

    vec4 cam = texture(iChannel0, floor((fragCoord/iResolution.xy)*gridSize)*(1.0/gridSize));

    vec3 col = vec3(0.0);

    bool circleR = circleTest(vec2(0.7,0.7),vec2(cam.x*0.5), uv);
    bool circleG = circleTest(vec2(0.3,0.5),vec2(cam.y*0.5), uv);
    bool circleB = circleTest(vec2(0.7,0.3),vec2(cam.z*0.5), uv);

    // Output to screen
    if(circleR){
        col.x = 1.0;
    } else {
        col.x = 0.0;
    }

    if(circleG){
        col.y = 1.0;
    } else {
        col.y = 0.0;
    }

    if(circleB){
        col.z = 1.0;
    } else {
        col.z = 0.0;
    }

    fragColor = vec4(col,1.0);

}
