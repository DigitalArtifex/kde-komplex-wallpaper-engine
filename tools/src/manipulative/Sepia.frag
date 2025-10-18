// Writer : Rasool Ghana <rasool.ghana@gmail.com>
// Sepia effect gives your images a warm brownish tone.
// Sepia filter improves the general look and feel of your image.
// Sepia tone photos appear hazy, warm, and a bit sentimental.

// this code is written based on FFMPEG's colorchannelmixer filter
// FFMPEG command line for same effect :
// colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 xy = fragCoord.xy / iResolution.xy;
    vec4 texColor = texture(iChannel0,xy);

    float rr = .3;
    float rg = .769;
    float rb = .189;
    float ra = 0.0;

    float gr = .3;
    float gg = .686;
    float gb = .168;
    float ga = 0.0;

    float br = .272;
    float bg = .534;
    float bb = .131;
    float ba = 0.0;

    float red = (rr * texColor.r) + (rb * texColor.b) + (rg * texColor.g) + (ra * texColor.a);
    float green = (gr * texColor.r) + (gb * texColor.b) + (gg * texColor.g) + (ga * texColor.a);
    float blue = (br * texColor.r) + (bb * texColor.b) + (bg * texColor.g) + (ba * texColor.a);

    texColor = vec4(red,green,blue,1.0);

    fragColor = texColor;

}
