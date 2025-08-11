// https://www.shadertoy.com/view/lcl3Rs

// This function returns an integer to use as the modulus value for a given pixel. 
//  The brighter this pixel, the smaller this integer is, relative to the width of the image (so that a black pixel returns
//  the image width as an integer)
int ditherModFactor(float val, vec2 imgSize){
    return int(floor((1.0-pow(val,0.01)) * imgSize.x));
    //The pow here applies an aggressive log curve to the greyscale colour of the image. This is needed due to 
    // multiplying the 0-1 greyscale value by such a large number (screen width in pixels). An exponent of 0.01 happens to work 
    // very well here, but playing around with the exponent can be interesting. 
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    //Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    
    //Load a pixel from the image and write it to a variable
    vec4 pix = texture(iChannel0,uv);
    
    //If the green channel of this pixel is more than a small value, and the red and blue are less than a threshold, make this 
    // pixel black.
    if(pix.y > 0.01 && pix.x < 0.2 && pix.z < 0.2){pix = vec4(0.0,0.0,0.0,1.0);} //uncomment to chroma key (for black background) 
    
    //Store a float of the average value of all three colour channels of this pixel
    float pixVal = (pix.x+pix.y+pix.z)/3.0;
    
    //Work out what number/index pixel this is in the image. It is also interesting to use the x or y coordinate of the current
    // pixel (not normalised) in place of i (**try replacing i on line 39 with fragCoord.x or fragCoord.y!**).
    float i = uv.x + (uv.y * iResolution.y);
    
    //Get the modulo value for this pixel
    int shadeMod = ditherModFactor(pixVal, iResolution.xy);
        
    //Compare the modulo value for this pixel with it's number/index - if the pixel index is a multiple of the modulo, 
    // output a white pixel - if not, black. This means that brighter pixels in the original image both have more white 
    // neighbours and are more likely to be white themselves, based on where they fall in the image. This is why it's important
    // to scale the modulo to the image width so that no repeating patterns of white appear in parts of the image that should be 
    // black. When this is done, the only black/dark pixels in the original image that will return white in the modulo check are 
    // the pixels that have the "address" (index or x or y coord) equal to the max value in range of values that address can be. 
    if(int(i) % shadeMod == 0){
        fragColor = vec4(1.0);
    } else {
        fragColor = vec4(0.0,0.0,0.0,1.0);
    }
    //if((1.0-uv.x) < uv.y){fragColor = vec4(pixVal,pixVal,pixVal,1.0);} //uncommenting shows undithered b&w image on half of screen
}