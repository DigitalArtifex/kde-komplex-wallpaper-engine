// The MIT License
// Copyright © 2017 Michael Schuresko
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 blend_uv = fragCoord.xy / iResolution.xy;
    vec2 uv = vec2(1.0 - blend_uv.x, blend_uv.y);
    vec3 intensity = 1.0 - texture(iChannel1, uv).rgb;
    
    float vidSample = dot(vec3(1.0), texture(iChannel1, uv).rgb);
    float delta = 0.005;
    float vidSampleDx = dot(vec3(1.0),
                            texture(iChannel1, uv + vec2(delta, 0.0)).rgb);
    float vidSampleDy = dot(vec3(1.0),
                            texture(iChannel1, uv + vec2(0.0, delta)).rgb);
    
    vec2 flow = delta * vec2 (vidSampleDy - vidSample, vidSample - vidSampleDx);
    
    intensity = 0.005 * intensity + 0.995 *
        (1.0 - texture(iChannel0,
               	               blend_uv + vec2(-1.0, 1.0) * flow).rgb);
    fragColor = vec4(1.0 - intensity,1.0);
}