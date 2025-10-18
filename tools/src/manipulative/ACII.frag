/*
ASCII filter. Current version from July 7, 2024.
Based on the genius implementation by movAX13h and inspired by Acerola's video on ASCII rendering.
Original ones here:
- movAX13h : https://www.shadertoy.com/view/lssGDj
- Acerola  : https://www.youtube.com/watch?v=gg40RWiaHRY

I plan to try implementing the border detection to render ASCII borders, so expect some update someday.

For more ASCII bitmap generation: https://thrill-project.com/archiv/coding/bitmap/

For this version, I focused on understanding the basic ideas and implementing it
in a legible way for me. For this, I have implemented:
- A helper grayscale function;
- A downsampled uv function to help downsample the coordinates, therefore the image;
- The original character function, that now deals more clearly with spacing and modulates
some more the original code.
*/

#define CHAR_SIZE 5.0
#define SPACING 1.0

float grayscale(vec3 p){
    /*Convertes a given pixel to grayscale.
    Parameters
    ----------

    p : vec3
        rgb pixel.
    */
    return 0.299*p.r + 0.587*p.g + 0.114*p.b;
}

vec2 downsampled_uv(vec2 coord, float d){
    /*Maps the current position to a downsampled position

    Parameters
    ----------

    coord : vec2
        Current pixel position.
    d : float
        downsample proportion (image will be d times smaller)
    */

    // Below line maps the current position to a downsampled uv
    // mod(fragCoord.x, d) is the distance from the current position from the target
    // position, so it is just subtracted.
    return vec2( coord.x - mod(coord.x, d), coord.y - mod(coord.y, d) ) / iResolution.xy;
}

float character(uint char, vec2 p){
    /*Returns if current pixel corresponds to character bounds

    Parameters
    ----------

    char : uint
        character 2^25 (5x5) bitmap value.
    p : vec2
        fragment position.
    */
    vec2 local_p = vec2( mod(p.x + 0.5, CHAR_SIZE + 2.0*SPACING), // ALWAYS sum +0.5
                         mod(p.y + 0.5, CHAR_SIZE + 2.0*SPACING));// ALWAYS sum +0.5

    //Checks if pixel position is beyond character limits, if yes then returns 0.0
    if(local_p.x < SPACING || local_p.x >= CHAR_SIZE + (SPACING - 1.0))
        return 0.0;
    if(local_p.y < SPACING || local_p.y >= CHAR_SIZE + (SPACING - 1.0))
        return 0.0;

    //Starts at bottom-left position
    uint start = 16u; //0b0000000000000000000010000
    uint bit_pos = start >> int(local_p.x - SPACING); // x offset
    bit_pos = bit_pos << int(CHAR_SIZE*(local_p.y - SPACING)); // y offset
    uint result = bit_pos & char; // acts as a mask to filter only the pixel value

    // bitshifts to the most significant bit so it does not overflow the output
    return float(result >> int( CHAR_SIZE-(local_p.x - (SPACING - 1.0)) ) +
                           int( CHAR_SIZE*(local_p.y - (SPACING)      ) )  );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float levels_size = 8.0;

    vec2 uv = downsampled_uv(fragCoord, CHAR_SIZE + 2.0*SPACING);

  /*char levels    =        (  , .  , :     , >       , *      , o        , @        , ▄       )*/
    uint levels[8] = uint[8](0u, 16u, 65600u, 4357252u, 163153u, 15255086u, 13195790u, 1048544u);

    vec3 tex = texture(iChannel0, uv).rgb;
    float gray = grayscale(tex);

    float ds = 1.0/levels_size; //levels size

    uint final_value = 0u;
    for(float i = 0.0; i < levels_size; i++) //Runs for every intensity level
        if(gray > 0.0 + i*ds) final_value = levels[int(i)];

    fragColor = vec4( tex*character(final_value, fragCoord) , 1.0);
}
