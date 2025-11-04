// This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0
// Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ 
// or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
// =========================================================================================================

#define AA // Comment to deactivate antialiasing
#define sat(a) clamp(a, 0., 1.)
#define PI 3.141592653

mat2 r2d(float a) { float c = cos(a), s = sin(a); return mat2(c, -s, s, c); }

vec2 _min(vec2 a, vec2 b)
{
    if (a.x < b.x)
        return a;
    return b;
}

// Stolen from 0b5vr here https://www.shadertoy.com/view/ss3SD8
float hash11(float p)
{
    return (fract(sin((p)*114.514)*1919.810));
}