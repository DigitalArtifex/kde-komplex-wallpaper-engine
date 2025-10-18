// fastMedian
//
// Somewhat inspired by Oilify effect in oilArt shader
// https://www.shadertoy.com/view/lsKGDW
//
// Once in a while there is a need to perform median filtering in
// real-time at high frame rate on the GPU. Exact solution can be
// quite complicated and involves array sorting.
// However, if the exact solution is not needed, it is possible
// to estimate median using histogram only. Also, it turns out
// that you can get away with relatively low bin count if histogram
// is built knowing minimum and maximum values upfront via pre-pass.
//
// In real-world applications when shared/thread local storage
// is available such histogram calculation is trivial. In this
// shader due to WebGL limitations the inner loop is unrolled.
//
// Created by Dmitry Andreev - and'2019
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

//#define RADIUS 2 //  5x5
#define RADIUS 4 //  9x9
//#define RADIUS 6 // 13x13

#define ADAPTIVE_QUANTIZATION

//#define BIN_COUNT 4
//#define BIN_COUNT 8
#define BIN_COUNT 12
//#define BIN_COUNT 24
//#define BIN_COUNT 48

//

#if BIN_COUNT == 4
	#define UNROLL(X) X(0)X(1)X(2)X(3)

#elif BIN_COUNT == 8
	#define UNROLL(X) X(0)X(1)X(2)X(3)X(4)X(5)X(6)X(7)

#elif BIN_COUNT == 12
	#define UNROLL(X) X(0)X(1)X(2)X(3)X(4)X(5)X(6)X(7)X(8)X(9)X(10)X(11)

#elif BIN_COUNT == 24
	#define U00_11(X) X(0)X(1)X(2)X(3)X(4)X(5)X(6)X(7)X(8)X(9)X(10)X(11)
	#define U12_23(X) X(12)X(13)X(14)X(15)X(16)X(17)X(18)X(19)X(20)X(21)X(22)X(23)
	#define UNROLL(X) U00_11(X)U12_23(X)

#elif BIN_COUNT == 48
	#define U00_11(X) X(0)X(1)X(2)X(3)X(4)X(5)X(6)X(7)X(8)X(9)X(10)X(11)
	#define U12_23(X) X(12)X(13)X(14)X(15)X(16)X(17)X(18)X(19)X(20)X(21)X(22)X(23)
	#define U24_35(X) X(24)X(25)X(26)X(27)X(28)X(29)X(30)X(31)X(32)X(33)X(34)X(35)
	#define U36_47(X) X(36)X(37)X(38)X(39)X(40)X(41)X(42)X(43)X(44)X(45)X(46)X(47)
	#define UNROLL(X) U00_11(X)U12_23(X)U24_35(X)U36_47(X)

#endif

vec3 readInput(vec2 uv, int dx, int dy)
{
    // Force nearest sampling for demonstration purposes
    vec2 img_res = iChannelResolution[0].xy;
    uv = (0.5 + floor(uv * img_res)) / img_res;

	return texture(iChannel0, uv + vec2(dx, dy) / img_res, -10.0).rgb;
}

//

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Fit image to touch screen from outside
    vec2 img_res = iChannelResolution[0].xy;
    vec2 res = iResolution.xy / img_res;
    vec2 img_size = img_res * max(res.x, res.y);
    vec2 img_org = 0.5 * (iResolution.xy - img_size);
    vec2 uv = (fragCoord - img_org) / img_size;

    vec3 ocol = readInput(uv, 0, 0);
    vec3 col = ocol;

    const int r = RADIUS;

	vec4 bins[BIN_COUNT];
	#define INIT(n) bins[n] = vec4(0);
    UNROLL(INIT)

#ifdef ADAPTIVE_QUANTIZATION
	float vmin = 1.0;
	float vmax = 0.0;

	for (int y = -r; y <= r; y++)
	for (int x = -r; x <= r; x++)
	{
        vec3 img = readInput(uv, x, y);
		float v = (img.r + img.g + img.b) / 3.0;

		vmin = min(vmin, v);
		vmax = max(vmax, v);
	}

#else
   	float vmin = 0.0;
	float vmax = 1.0;

#endif

	for (int y = -r; y <= r; y++)
	for (int x = -r; x <= r; x++)
	{
        vec3 img = readInput(uv, x, y);
		float v = (img.r + img.g + img.b) / 3.0;

		int i = int(0.5 + ((v - vmin) / (vmax - vmin)) * float(BIN_COUNT));

		#define UPDATE(n) if (i == n) bins[n] += vec4(img.rgb, 1.0);
        UNROLL(UPDATE)
	}

	float mid = floor((float(r * 2 + 1) * float(r * 2 + 1)) / 2.0);
	float pos = 0.0;

    #define M1(i) col.rgb = pos <= mid && bins[i].a > 0.0 ?
    #define M2(i) bins[i].rgb / bins[i].aaa : col.rgb;
    #define M3(i) pos += bins[i].a;
    #define MEDIAN(i) M1(i)M2(i)M3(i)
    UNROLL(MEDIAN)

    // Show original image on click
    if (iMouse.w > 0.0) col = ocol;

    fragColor = vec4(col, 1.0);
}
