/*

Copyright (c) 2023 Roel Bartstra

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;

    // Sample input texture
	vec3 input_color = texture(iChannel0, uv).rgb;

    // The actual "posterize"
    const float color_length_steps = 5.0;
    float color_length = length(input_color.rgb);
    vec3 color_direction = input_color.rgb / color_length;
    float stepped_color_length = round(color_length * color_length_steps) / color_length_steps;
    vec3 posterized_color = stepped_color_length * color_direction;

    // Debugging: Use left mouse for image slite to compare with input.
    float debug_mask = step(uv.x, iMouse.x / iResolution.x);
    vec3 output_color = mix(posterized_color, input_color, debug_mask);

    // Output to screen
    fragColor = vec4(output_color, 1);
}
