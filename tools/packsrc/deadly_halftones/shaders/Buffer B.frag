//////////////////////////////////////
//     HALPHTONES POSTPROCESING
//////////////////////////////////////


float make_dot (vec2 uv, float r, float c)
{  
   return smoothstep( r - .1, r, min( length((uv - vec2(c/2.))*2.), r));   
}

float get_tex(vec2 U)
{
    vec3 tex_col = texture(iChannel0,U / R).xyz;
    return  .45 * (tex_col.x + tex_col.y + tex_col.z);
}

void mainImage( out vec4 C, in vec2 U )
{
	
   // float cel = rem(R);                                                 // float CEL = floor(R.y/70.);
     
    float  pixel_color = get_tex(ceil(U / CEL) * CEL);                  // calculate cel color
   
    float dot_radius = pixel_color ;                                    // dot radius
    
    U = mod(U , CEL);                                                   // cell grid
    
    vec4 dot_color  = vec4(make_dot(U, ceil(dot_radius * CEL ), CEL )); // make dots
 
    C = 1. - dot_color;
}