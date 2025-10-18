/*

  Video Transitions v2.0 by Mark Craig (Copyright © 2022)

    I originally wrote this as a "filter" to create transition frames
  for videos (C program which outputted PPM files).  But eventually,
  I figured it could be relatively easily ported to GLSL - this is the
  result.

*/

int n = 100;           // number of "frames" in transition
float sa = .05;        // smooth amount - size of smooth edges
bool roto = true;      // if true, rotate transitions that can optionally rotate
float rota = 360.0;    // amount of rotation from start to end of transition
int rn = 1, rd = 0;    // select based on whether to start with full
//int rn = 0, rd = -1; //   frame of source1 (only for some transitions)
//bool altdir = false;   // if true, change direction of rolls
bool altdir = true;   // if true, change direction of rolls
int alttype = 0;       // alternate slide up center type (0-8 or 9-17 for slide in)

#define SPEEDADJ .375
//#define NEEDMOD 1
//#define SELECTTRANS // uncomment to enable @morimea's transition selector mods
                      // If selector mods are chosen, click and hold down left
                      // mouse button on desired transition

#define imod(a,b) (int((float(a)-(float(b)*floor(float(a)/float(b))))))

#define iGlobalTime (iTime / SPEEDADJ)

#define num_transitions 38

// macros for selecting/mixing the textures

#define MEM2 col = alt ? col1 : col2;
#define MEM1 col = alt ? col2 : col1;
#define MEM12 col = alt ? v1 * col2 + v2 * col1 : v1 * col1 + v2 * col2;
#define MEM1S { col = alt ? texture2D(iChannel1, uv2).xyz : texture2D(iChannel0, uv2).xyz; }
#define MEM2S { col = alt ? texture2D(iChannel0, uv2).xyz : texture2D(iChannel1, uv2).xyz; }

// Solve some incompatibilities

#define atan2 atan
#define fmod mod
#define texture2D texture

// Useful values

#define _TWOPI 6.283185307
#define M_PI 3.141592654

float intersect(vec2, vec2, vec2, vec2);

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
vec2 uv = fragCoord.xy / iResolution.xy, uv2;
#ifdef SELECTTRANS
// I modified @morimea's mod to make effects start at top and progress in order to bottom
uv.y = 1.0 - uv.y;
uv *= vec2(6.,7.); int idx = int(floor(uv.x) + floor(uv.y) * 6.);
vec2 im = iMouse.xy / iResolution.xy; im.y = 1.0 - im.y;
if (iMouse.z > 0.) { im *= vec2(6., 7.); idx = int(floor(im.x) + floor(im.y) * 6.); uv /= vec2(6., 7.); }
else { uv = fract(uv); }
uv.y = 1.0 - uv.y;
#endif
bool alt = false;
int type, i, i2, j, v;
vec3 col, col3;
float v1, v2;
float ye, yfe, dx, dy, cx, cy, rad, slope, theta, xc1, yc1, b, rad0, rad2;
float xc2, yc2, b2, cx2, cy2, r1, vy1, vy2, dx2, dy2, ro, ri, ang, a, a1;
float r, r2, l, l2, theta2, theta3, tang, ang1, ang2, angt, angs, c1, s1;
float xc0, yc0;
vec2 p1, p2, po, pd;

float aspect = iResolution.y / iResolution.x;
vec3 col1 = texture2D(iChannel0, uv).xyz;
vec3 col2 = texture2D(iChannel1, uv).xyz;
#ifdef NEEDMOD
i = imod(int(iGlobalTime * 20.0) , n);
#ifndef SELECTTRANS
type = imod((int(iGlobalTime * 20.0) / n) , num_transitions);
if (imod(type , 2) == 1) { alt = true; } else { alt = false; }
#else
type = idx;
if (imod(int(iGlobalTime * 20.0) , (n*2)) < n) { alt = true; } else { alt = false; }
#endif
#else
i = int(iGlobalTime * 20.0) % n;
#ifndef SELECTTRANS
type = (int(iGlobalTime * 20.0) / n) % num_transitions;
if (type % 2 == 1) { alt = true; } else { alt = false; }
#else
type = idx;
if (int(iGlobalTime * 20.0) % (n*2) < n) { alt = true; } else { alt = false; }
#endif
#endif

//type = 32;

// some of these equations are long, so I'll forego extra spaces

// was a switch, but some GPUs won't do switch

		if (type==0) // fade in/out
			{
			v1=float(n-(i+1))/float(n-1); v2=1.0-v1;
			MEM12
			}
		else if (type==1) // window down with soft edge
			{
			ye=1.0-float(i)/float(n-1);
			yfe=ye+sa;
			if (uv.y<=ye) MEM1
			else if (uv.y>yfe) MEM2
			else
				{
				v2=float(uv.y-ye)/sa; if (v2>1.0) { v2=1.0; } v1=1.0-v2;
				MEM12
				}
			}
		else if (type==2) // increasing box
			{
			cx=.5; cy=.5;
			dx=cx*float(i+rn)/float(n+rd);
			dy=cy*float(i+rn)/float(n+rd);
			if ((uv.x>=cx-dx)&&(uv.x<=cx+dx)&&(uv.y>=cy-dy)&&(uv.y<=cy+dy)) MEM2
			else MEM1
			}
		else if (type==3) // increasing diamond
			{
			cx=.5; cy=.5;
			rad=sqrt(cx*cx+cy*cy)*(float(i+rn)/float(n+rd));
			slope=-cy/cx;
			theta=atan(-slope);
			xc1=rad*cos(theta); yc1=rad*sin(theta);
			b=yc1-slope*xc1;
			cy=b; cx=(-b/slope);
			dy=abs(.5-uv.y);
			dx=abs(.5-uv.x);
			if (dx>cx) MEM1
			else if (dy>slope*dx+cy) MEM1
			else MEM2
			}
		else if (type==4) // increasing circle
			{
			cx=.5; cy=.5;
			rad=sqrt(cx/aspect*cx/aspect+cy*cy)*(float(i+rn)/float(n+rd));
			if (sqrt((uv.x-cx)/aspect*(uv.x-cx)/aspect+(uv.y-cy)*(uv.y-cy))>rad) MEM1
			else MEM2
			}
		else if (type==5) // increasing and decreasing diamonds
			{
			cx=.5; cy=.5;
			rad0=sqrt(cx*cx+cy*cy)/2.0;
			rad=sqrt(cx*cx+cy*cy)*(float(n-(i+1))/float(n+rd))/2.0;
			rad2=rad0+(rad0-rad);
			slope=-cy/cx;
			theta=atan(-slope);
			xc1=rad*cos(theta); yc1=rad*sin(theta);
			xc2=rad2*cos(theta); yc2=rad2*sin(theta);
			b=yc1-slope*xc1;
			b2=yc2-slope*xc2;
			cy=b; cx=(-b/slope);
			cy2=b2; cx2=(-b2/slope);
			dy=abs(.5-uv.y);
			dx=abs(.5-uv.x);
			if (dx>cx) MEM2
			else if (dy>slope*dx+cy) MEM2
			else MEM1
			if (dy>slope*dx+cy2) MEM1
			}
		else if (type==6) // four corner vanish
			{
			cx=.5; cy=.5;
			dx=cx*float(i+rn)/float(n+rd);
			dy=cy*float(i+rn)/float(n+rd);
			if ((uv.x>cx-dx)&&(uv.x<cx+dx)&&(uv.y>cy-dy)&&(uv.y<cy+dy)) MEM2
			else if ((uv.y<cy)&&(uv.x>cx-dx)&&(uv.x<cx+dx)) MEM2
			else if ((uv.y>cy)&&(uv.x>cx-dx)&&(uv.x<cx+dx)) MEM2
			else if ((uv.x<cx)&&(uv.y>cy-dy)&&(uv.y<cy+dy)) MEM2
			else if ((uv.x>cx)&&(uv.y>cy-dy)&&(uv.y<cy+dy)) MEM2
			else MEM1
			}
		else if (type==7) // increasing circle with soft edge
			{
			cx=.5; cy=.5;
			rad=sqrt(cx/aspect*cx/aspect+cy*cy)*(float(i+rn)/float(n+rd));
			//rad2=rad+10.0*sa;
			rad2=rad+sa;
			r1=sqrt((uv.x-cx)/aspect*(uv.x-cx)/aspect+(uv.y-cy)*(uv.y-cy));
			if (r1>rad2) MEM1
			else if (r1>rad) { v1=(r1-rad)/(rad2-rad); v2=1.0-v1; MEM12 }
			else MEM2
			}
		else if (type==8) // increasing diamond with soft edge
			{
			cx=.5; cy=.5;
			rad=sqrt(cx*cx+cy*cy)*(float(i+rn)/float(n+rd));
			//rad2=rad+7.0*sa;
			rad2=rad+.7*sa;
			slope=-cy/cx;
			theta=atan(-slope);
			xc1=rad*cos(theta); yc1=rad*sin(theta);
			xc2=rad2*cos(theta); yc2=rad2*sin(theta);
			b=yc1-slope*xc1;
			b2=yc2-slope*xc2;
			cy=b; cx=(-b/slope);
			cy2=b2; cx2=(-b2/slope);
			dy=abs(.5-uv.y);
			dx=abs(.5-uv.x);
			if (dx>cx2) MEM1
			else if (dy>slope*dx+cy2) MEM1
			else if (dy>slope*dx+cy)
				{
				vy1=slope*dx+b;
				vy2=slope*dx+b2;
				v1=(dy-vy1)/(vy2-vy1); v2=1.0-v1;
				MEM12
				}
			else MEM2
			}
		else if (type==9) // increasing & decreasing diamonds w/ soft edge
			{
			float xc1s,yc1s,xc2s,yc2s,rads,rad2s,bs,b2s,cxs,cys,cx2s,cy2s;

			cx=.5; cy=.5;
			rad0=sqrt(cx*cx+cy*cy)/2.0;
			rad=sqrt(cx*cx+cy*cy)*(float(n-(i+1))/float(n+rd))/2.0;
			//rads=rad+7.0*sa;
			rads=rad+.7*sa;
			rad2=rad0+(rad0-rad);
			//rad2s=rad2-7.0*sa;
			rad2s=rad2-.7*sa;
			slope=-cy/cx;
			theta=atan(-slope);
			xc1=rad*cos(theta); yc1=rad*sin(theta);
			xc2=rad2*cos(theta); yc2=rad2*sin(theta);
			xc1s=rads*cos(theta); yc1s=rads*sin(theta);
			xc2s=rad2s*cos(theta); yc2s=rad2s*sin(theta);
			b=yc1-slope*xc1;
			b2=yc2-slope*xc2;
			bs=yc1s-slope*xc1s;
			b2s=yc2s-slope*xc2s;
			cy=b; cx=(-b/slope);
			cy2=b2; cx2=(-b2/slope);
			cys=bs; cxs=(-bs/slope);
			cy2s=b2s; cx2s=(-b2s/slope);
			dy=abs(.5-uv.y);
			dx=abs(.5-uv.x);
			if (dx>cxs) MEM2
			else if (dy>slope*dx+cys) MEM2
			else if (dy>slope*dx+cy)
				{
				vy1=slope*dx+b;
				vy2=slope*dx+bs;
				v2=(dy-vy1)/(vy2-vy1); v1=1.0-v2;
				MEM12
				}
			else MEM1
			if (dy>slope*dx+cy2) MEM1
			else if (dy>slope*dx+cy2s)
				{
				vy1=slope*dx+b2;
				vy2=slope*dx+b2s;
				v2=(dy-vy1)/(vy2-vy1); v1=1.0-v2;
				MEM12
				}
			}
		else if (type==10) // increasing box with soft edge
			{
			cx=.5; cy=.5;
			dx=(cx*float(i+rn)/float(n+rd));
			dy=(cy*float(i+rn)/float(n+rd));
			dx2=(cx*float(i+rn)/float(n+rd)+sa);
			dy2=(cy*float(i+rn)/float(n+rd)+sa);
			if ((uv.x>=cx-dx)&&(uv.x<=cx+dx)&&(uv.y>=cy-dy)&&(uv.y<=cy+dy)) MEM2
			else if ((uv.x>=cx-dx2)&&(uv.x<=cx+dx2)&&(uv.y>=cy-dy2)&&(uv.y<=cy+dy2))
				{
				if ((abs(uv.x-cx)>dx)&&(abs(uv.y-cy)>dy))
					{
					if (abs(uv.y-cy)-dy>abs(uv.x-cx)-dx) v1=float(abs(uv.y-cy)-dy)/(sa);
					else v1=float(abs(uv.x-cx)-dx)/(sa);
					}
				else if (abs(uv.x-cx)>dx) { v1=float(abs(uv.x-cx)-dx)/(sa); }
				else if (abs(uv.y-cy)>dy) { v1=float(abs(uv.y-cy)-dy)/(sa); }
				v2=1.0-v1; MEM12
				}
			else MEM1
			}
		else if (type==11) // rotating vanishing (gets smaller) square with fade in new/fade out old
			{
			theta=-_TWOPI*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			rad=max(0.00001,(float(n-(i+1))/float(n+rd)));
			xc1=(uv.x-.5)*iResolution.x; yc1=(uv.y-.5)*iResolution.y;
			xc2=(xc1*c1-yc1*s1)/rad;
			yc2=(xc1*s1+yc1*c1)/rad;
			uv2.x=xc2+iResolution.x/2.0; uv2.y=yc2+iResolution.y/2.0;
			if ((uv2.x>=0.0)&&(uv2.x<=iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<=iResolution.y))
				{
				uv2/=iResolution.xy;
				col3 = alt ? texture2D(iChannel1, uv2).xyz : texture2D(iChannel0, uv2).xyz;
				}
			else { col3 = vec3(0,0,0); }
			v1=float(n-(i+1))/float(n-1); v2=1.0-v1;
			col = alt ? v1*col3+v2*col1 : v1*col3+v2*col2;
			}
		else if (type==12) // rotating vanishing (gets smaller) square with fade out old
			{
			theta=-_TWOPI*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			rad=max(0.00001,(float(n-(i+1))/float(n+rd)));
			xc1=(uv.x-.5)*iResolution.x; yc1=(uv.y-.5)*iResolution.y;
			xc2=(xc1*c1-yc1*s1)/rad;
			yc2=(xc1*s1+yc1*c1)/rad;
			uv2.x=xc2+iResolution.x/2.0; uv2.y=yc2+iResolution.y/2.0;
			if ((uv2.x>=0.0)&&(uv2.x<=iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<=iResolution.y))
				{
				uv2/=iResolution.xy;
				col3 = alt ? texture2D(iChannel1, uv2).xyz : texture2D(iChannel0, uv2).xyz;
				}
			else { col3 = alt ? col1 : col2; }
			v1=float(n-(i+1))/float(n-1); v2=1.0-v1;
			col = alt ? v1*col3+v2*col1 : v1*col3+v2*col2;
			}
		else if (type==13) // increasing flower with soft edge
			{
			cx=.5; cy=.5;
			ang=36.0*M_PI/180.0;
			ro=(1.0/aspect)/.731*(float(i+rn)/float(n+rd));
			a1=234.0*M_PI/180.0;
			l=(sqrt((ro*cos(a1)*ro*cos(a1))+((ro*sin(a1)-ro)*(ro*sin(a1)-ro))))/2.0;
			a1=162.0*M_PI/180.0;
			l2=((ro*cos(a1)*ro*cos(a1))+((ro*sin(a1)-ro)*(ro*sin(a1)-ro)));
			ri=(ro-sqrt(l2-l*l))/cos(36.0*M_PI/180.0);
			if (roto) { vy1=float(i+rn-1)/float(n+rd)*rota*M_PI/180.0; }
			else { vy1=0.0; }
			yc1=1.0-uv.y-cy;
			xc1=(uv.x-cx)/aspect;
			theta=atan2(xc1,yc1)+vy1;
			theta2=fmod(abs(theta),ang);
			i2=int((180.0*theta/M_PI)/36.0);
#ifdef NEEDMOD
			if (imod(i2,2)==0) { r=theta2/ang*(ro-ri)+ri; }
#else
			if (i2%2==0) { r=theta2/ang*(ro-ri)+ri; }
#endif
			else { r=(1.0-theta2/ang)*(ro-ri)+ri; }
			r2=sqrt(xc1*xc1+yc1*yc1);
			if (r2>r+sa) { MEM1 } else if (r2>r) { v1=(r2-r)/(sa); v2=1.0-v1; MEM12 } else { MEM2 }
			}
		else if (type==14) // increasing star with soft edge
			{
			cx=.5; cy=.5;
			ang=36.0*M_PI/180.0;
			ro=(1.0/aspect)/.731*(float(i+rn)/float(n+rd));
			a1=234.0*M_PI/180.0;
			l=(sqrt((ro*cos(a1)*ro*cos(a1))+((ro*sin(a1)-ro)*(ro*sin(a1)-ro))))/2.0;
			a1=162.0*M_PI/180.0;
			l2=((ro*cos(a1)*ro*cos(a1))+((ro*sin(a1)-ro)*(ro*sin(a1)-ro)));
			ri=(ro-sqrt(l2-l*l))/cos(36.0*M_PI/180.0);
			if (roto) { vy1=float(i+rn-1)/float(n+rd)*rota*M_PI/180.0; }
			else { vy1=0.0; }
			po.x=po.y=0.0;
			yc1=1.0-uv.y-cy;
			xc1=(uv.x-cx)/aspect;
			theta=atan2(xc1,yc1)+vy1;
			theta2=fmod(abs(theta),ang);
			i2=int((180.0*theta/M_PI)/36.0);
#ifdef NEEDMOD
			if (imod(i2,2)==0) { p1.x=ri; p1.y=0.0; p2.x=ro*cos(ang); p2.y=ro*sin(ang); }
#else
			if (i2%2==0) { p1.x=ri; p1.y=0.0; p2.x=ro*cos(ang); p2.y=ro*sin(ang); }
#endif
			else { p1.x=ro; p1.y=0.0; p2.x=ri*cos(ang); p2.y=ri*sin(ang); }
			pd.x=cos(theta2); pd.y=sin(theta2);
			r=intersect(po,pd,p1,p2);
			r2=sqrt(xc1*xc1+yc1*yc1);
			if (r2>r+sa) { MEM1 } else if (r2>r) { v1=(r2-r)/(sa); v2=1.0-v1; MEM12 } else { MEM2 }
			}
		else if (type==15) // dissolve
			{
			// easier to use this common shadertoy random number gen rather than the one I used in original
			int v=int(fract(sin(dot(uv, vec2(12.9898, 78.233)))* 43758.5453)*float(n-1));
			if (i>v) MEM2 else MEM1
			}
		else if (type==16) // split horizontal
			{
			cy=.5;
			ye=1.0/2.0*float(i+rn)/float(n+rd);
			if (uv.y<cy-ye) MEM1
			else if (uv.y>=cy+ye) MEM1
			else MEM2
			}
		else if (type==17) // split vertical
			{
			cx=.5;
			ye=1.0/2.0*float(i+rn)/float(n+rd);
			if (uv.x<cx-ye) MEM1
			else if (uv.x>=cx+ye) MEM1
			else MEM2
			}
		else if (type==18) // slide
			{
			ye=float(i+rn)/float(n+rd);
			uv2.x=uv.x;
			uv2.y=uv.y+ye;
			if (uv.y>=1.0-ye) MEM2
			else MEM1S
			}
		else if (type==19) // window right with soft edge
			{
			ye=float(i)/float(n-1);
			yfe=ye+(10.0*sa);
			if (uv.x<=ye) MEM2
			else if (uv.x>yfe) MEM1
			else
				{
				v1=(uv.x-ye)/(10.0*sa); if (v1>1.0) { v1=1.0; } v2=1.0-v1;
				MEM12
				}
			}
		else if (type==20) // inset down right
			{
			dx=float(i+rn)/float(n+rd);
			dy=float(i+rn)/float(n+rd);
			if (uv.x>=dx) MEM1
			else if (1.0-uv.y>=dy) MEM1
			else MEM2
			}
		else if (type==21) // inset down left
			{
			dx=float(i+rn)/float(n+rd);
			dy=float(i+rn)/float(n+rd);
			if ((1.0-uv.x)>dx) MEM1
			else if (1.0-uv.y>=dy) MEM1
			else MEM2
			}
		else if (type==22) // inset up right
			{
			dx=float(i+rn)/float(n+rd);
			dy=float(i+rn)/float(n+rd);
			if (uv.x>=dx) MEM1
			else if (uv.y>dy) MEM1
			else MEM2
			}
		else if (type==23) // inset up left
			{
			dx=float(i+rn)/float(n+rd);
			dy=float(i+rn)/float(n+rd);
			if ((1.0-uv.x)>dx) MEM1
			else if ((uv.y)>dy) MEM1
			else MEM2
			}
		else if (type==24) // pixelate
			{
			// this is simpler (not as good) as my original non-glsl code
			v1=float(n-(i+1))/float(n-1); v2=1.0-v1;
			if (i<n/2) { j=int(float(i)/(float(n)/2.0)*50.0); }
			else { j=int(float(n-i-1)/(float(n)/2.0)*50.0); }
			if (j<1) { j=1; }
			uv2.x=float(int(uv.x*iResolution.x/float(j))*j)/iResolution.x;
			uv2.y=float(int(uv.y*iResolution.y/float(j))*j)/iResolution.y;
			col = v1 * (alt ? texture2D(iChannel1, uv2).xyz : texture2D(iChannel0, uv2).xyz) + v2 * (alt ? texture2D(iChannel0, uv2).xyz : texture2D(iChannel1, uv2).xyz);
			}
		else if (type==25) // fan in
			{
			theta2=M_PI*float(i+rn)/float(n+rd);
			dy=1.0/4.0; dx=1.0/2.0; dy2=1.0*3.0/4.0;
			xc1=M_PI/180.0*sa; cy=.5;
			theta=atan2(abs(dx-uv.x),dy-uv.y);
			theta3=atan2(abs(dx-uv.x),uv.y-dy2);
			if ((theta<theta2)||(theta3<theta2)) MEM2
			else if (abs(theta2-M_PI)<=.00001) MEM2
			else if ((theta<theta2+xc1)&&(uv.y<=cy)) { v1=(theta-theta2)/xc1; v2=1.0-v1; MEM12 }
			else if (theta3<theta2+xc1) { v1=(theta3-theta2)/xc1; v2=1.0-v1; MEM12 }
			else MEM1
			}
		else if (type==26) // fan out
			{
			theta2=_TWOPI*float(i+rn)/float(n+rd);
			dx=1.0/4.0; dy=.5; dx2=1.0*3.0/4.0; cx=.5;
			xc1=M_PI/180.0*sa;
			theta=M_PI+atan2(1.0-uv.y-dy,dx-uv.x);
			theta3=M_PI+atan2(1.0-uv.y-dy,uv.x-dx2);
			if (theta2<=M_PI)
				{
				if ((theta<theta2)&&(theta3<theta2)) MEM2
				else if ((theta<theta2+xc1)&&(uv.x<=cx)) { v1=(theta-theta2)/xc1; v2=1.0-v1; MEM12 }
				else if ((theta3<theta2+xc1)&&(uv.x>=cx)) { v1=(theta3-theta2)/xc1; v2=1.0-v1; MEM12 }
				else MEM1
				}
			else
				{
				if ((theta>theta2+xc1)&&(uv.x<=cx)) MEM1
				else if ((theta3>theta2+xc1)&&(uv.x>=cx)) MEM1
				else if (!((theta>theta2)&&(theta3>theta2))) MEM2
				else if (uv.x<=cx) { v1=(theta-theta2)/xc1; v2=1.0-v1; MEM12 }
				else { v1=(theta3-theta2)/xc1; v2=1.0-v1; MEM12 }
				}
			}
		else if (type==27) // fan up
			{
			theta2=M_PI/2.0*float(i+rn)/float(n+rd);
			dy=0.0; dx=1.0/2.0; xc1=M_PI/180.0*sa;
			theta=atan2(abs(dx-uv.x),1.0-uv.y);
			if (theta<theta2) MEM2
			else if (theta<theta2+xc1) { v1=(theta-theta2)/xc1; v2=1.0-v1; MEM12 }
			else MEM1
			}
		else if (type==34) // roll
			{
			theta=(altdir?M_PI:-M_PI)/2.0*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			uv2.x=((1.0-uv.x)*iResolution.x*c1-uv.y*iResolution.y*s1);
			uv2.y=((1.0-uv.x)*iResolution.x*s1+uv.y*iResolution.y*c1);
			if ((uv2.x>=0.0)&&(uv2.x<iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<iResolution.y))
				{ uv2/=iResolution.xy; uv2.x=1.0-uv2.x; MEM1S }
			else { MEM2 }
			}
		else if (type==35) // roll2
			{
			theta=(altdir?M_PI:-M_PI)/2.0*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			uv2.x=(uv.x*iResolution.x*c1-uv.y*iResolution.y*s1);
			uv2.y=(uv.x*iResolution.x*s1+uv.y*iResolution.y*c1);
			if ((uv2.x>=0.0)&&(uv2.x<iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<iResolution.y))
				{ uv2/=iResolution.xy; MEM1S }
			else { MEM2 }
			}
		else if (type==36) // roll3
			{
			theta=(altdir?-M_PI:M_PI)/2.0*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			uv2.x=(uv.x*iResolution.x*c1-(1.0-uv.y)*iResolution.y*s1);
			uv2.y=(uv.x*iResolution.x*s1+(1.0-uv.y)*iResolution.y*c1);
			if ((uv2.x>=0.0)&&(uv2.x<iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<iResolution.y))
				{ uv2/=iResolution.xy; uv2.y=1.0-uv2.y; MEM1S }
			else { MEM2 }
			}
		else if (type==37) // roll4
			{
			theta=(altdir?-M_PI:M_PI)/2.0*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			uv2.x=((1.0-uv.x)*iResolution.x*c1-(1.0-uv.y)*iResolution.y*s1);
			uv2.y=((1.0-uv.x)*iResolution.x*s1+(1.0-uv.y)*iResolution.y*c1);
			if ((uv2.x>=0.0)&&(uv2.x<iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<iResolution.y))
				{ uv2/=iResolution.xy; uv2=1.0-uv2; MEM1S }
			else { MEM2 }
			}
		else if (type==28) // bars
			{
			int v=int(fract(sin(dot(vec2(uv.y,0), vec2(12.9898, 78.233)))* 43758.5453)*float(n-1));
			if (i>v) MEM2 else MEM1
			}
		else if (type==33) // slide up center
			{
			bool In=false;
			if (alttype>8) { v=alttype-9; In=true; } else { v=alttype; }
			if (In) { rad=(float(i+1)/float(n+rd)); }
			else { rad=(float(n-(i+1))/float(n+rd)); }
			if (v==0) { cx=.5; cy=0.0; xc1=.5-rad/2.0; yc1=0.0; }
			else if (v==1) { cx=1.0; cy=.5; xc1=1.0-rad; yc1=.5-rad/2.0; }
			else if (v==2) { cx=.5; cy=1.0; xc1=.5-rad/2.0; yc1=1.0-rad; }
			else if (v==3) { cx=0.0; cy=.5; xc1=0.0; yc1=.5-rad/2.0; }
			else if (v==4) { cx=1.0; cy=0.0; xc1=1.0-rad; yc1=0.0; }
			else if (v==5) { cx=cy=1.0; xc1=1.0-rad; yc1=1.0-rad; }
			else if (v==6) { cx=0.0; cy=1.0; xc1=0.0; yc1=1.0-rad; }
			else if (v==7) { cx=cy=0.0; xc1=0.0; yc1=0.0; }
			else if (v==8) { cx=cy=.5; xc1=.5-rad/2.0; yc1=.5-rad/2.0; }
			uv.y=1.0-uv.y;
			if ((uv.x>=xc1)&&(uv.x<=xc1+rad)&&(uv.y>=yc1)&&(uv.y<=yc1+rad))
				{
				uv2.x=(uv.x-xc1)/rad;
				uv2.y=1.0-(uv.y-yc1)/rad;
				if (In) { MEM2S } else { MEM1S }
				}
			else if (In) { MEM1 } else { MEM2 }
			}
		else if (type==29) // diagonal down right
			{
			rad=sqrt(2.0+2.0)*(1.0-(float(i+rn)/float(n+rd)));
			slope=-1.0/1.0;
			theta=atan(-slope);
			xc1=rad*cos(theta); yc1=rad*sin(theta);
			b=yc1-slope*xc1-sa;
			cy=b; cx=(-b/slope);
			dy=abs(uv.y);
			dx=abs(1.0-uv.x);
			//if (dx>cx-sa) MEM2
			if (dy>slope*dx+cy+sa) MEM2
			else if (dy>slope*dx+cy) { v2=(dy-(slope*dx+cy))/(sa); v1=1.0-v2; MEM12 }
			else MEM1
			}
		else if (type==30) // diagonal cross out
			{
			cx=.5; cy=.5;
			rad=sqrt(cx*cx+cy*cy)/2.0*(float(i+rn)/float(n+rd));
			slope=-cy/cx;
			theta=atan(-slope);
			xc1=rad*cos(theta); yc1=rad*sin(theta);
			b=yc1-slope*xc1;
			cy=b; cx=(-b/slope); vy1=sa;
			dy=(uv.y-.5);
			dx=(uv.x-.5);
			if (!(((dy>slope*dx+cy)||(dy<slope*dx-cy))&&((dy>(-slope)*dx+cy)||(dy<(-slope)*dx-cy)))) MEM2
			else if ((sa!=0.0)&&(!(((dy>slope*dx+cy+vy1)||(dy<slope*dx-cy-vy1))&&
				((dy>(-slope)*dx+cy+vy1)||(dy<(-slope)*dx-cy-vy1)))))
				{
				if ((dx>=0.0)&&(dy>=0.0))
					{
					v1=v2=0.0;
					if (dy>-slope*dx) { v1=(dy-(-slope*dx+cy))/vy1; v2=1.0-v1; }
					else { v1=((-slope*dx-cy)-dy)/vy1; v2=1.0-v1; }
					MEM12
					}
				else if ((dx<0.0)&&(dy<0.0))
					{
					v1=v2=0.0;
					if (dy>-slope*dx) { v1=(dy-(-slope*dx+cy))/vy1; v2=1.0-v1; }
					else { v1=((-slope*dx-cy)-dy)/vy1; v2=1.0-v1; }
					MEM12
					}
				else if ((dx>=0.0)&&(dy<0.0))
					{
					v1=v2=0.0;
					if (dy>slope*dx) { v1=(dy-(slope*dx+cy))/vy1; v2=1.0-v1; }
					else { v1=((slope*dx-cy)-dy)/vy1; v2=1.0-v1; }
					MEM12
					}
				else if ((dx<0.0)&&(dy>=0.0))
					{
					v1=v2=0.0;
					if (dy>slope*dx) { v1=(dy-(slope*dx+cy))/vy1; v2=1.0-v1; }
					else { v1=((slope*dx-cy)-dy)/vy1; v2=1.0-v1; }
					MEM12
					}
				}
			else MEM1
			}
		else if (type==31) // increasing gear with soft edge
			{
			cx=.5; cy=.5;
			ro=sqrt(cx*cx+cy*cy)/.9*float(i+rn)/float(n+rd);
			if (roto) { vy1=float(i+rn-1)/float(n+rd)*rota*M_PI/180.0; }
			else { vy1=0.0; }
			ri=ro*.9;
			po.x=po.y=0.0;
			angt=5.0;
			angs=2.5;
			tang=(angt+angs)*2.0;
			ang=tang*M_PI/180.0;
			yc1=uv.y-cy;
			xc1=(uv.x-cx)/aspect;
			theta=atan2(xc1,yc1);
			theta2=fmod(theta+M_PI+vy1,ang);
			if (theta2<=angt*M_PI/180.0) { r1=r2=ri; ang2=angt; ang1=theta2; }
			else if (theta2<=(angt+angs)*M_PI/180.0) { r1=ri; r2=ro; ang2=angs; ang1=theta2-angt*M_PI/180.0; }
			else if (theta2<=(angt+angs+angt)*M_PI/180.0) { r1=r2=ro; ang2=angt; ang1=theta2-(angt+angs)*M_PI/180.0; }
			else { r1=ro; r2=ri; ang2=angs; ang1=theta2-(angt+angs+angt)*M_PI/180.0; }
			ang2*=(M_PI/180.0);
			p1.x=r1; p1.y=0.0; p2.x=r2*cos(ang2); p2.y=r2*sin(ang2);
			pd.x=cos(ang1); pd.y=sin(ang1);
			r=intersect(po,pd,p1,p2);
			r2=sqrt(xc1*xc1+yc1*yc1);
			if (r2>r+sa) { MEM1 } else if (r2>r) { v1=(r2-r)/(sa); v2=1.0-v1; MEM12 } else { MEM2 }
			}
		else if (type==32) // rotating expanding square with fade in new/fade out old
			{
			theta=-_TWOPI*(float(i+rn)/float(n+rd));
			c1=cos(theta); s1=sin(theta);
			rad=(float(n-(i+1))/float(n+rd));
			xc1=(uv.x-.5)*iResolution.x; yc1=(uv.y-.5)*iResolution.y;
			xc2=rad*(xc1*c1-yc1*s1);
			yc2=rad*(xc1*s1+yc1*c1);
			uv2.x=xc2+iResolution.x/2.0; uv2.y=yc2+iResolution.y/2.0;
			if ((uv2.x>=0.0)&&(uv2.x<=iResolution.x)&&(uv2.y>=0.0)&&(uv2.y<=iResolution.y))
				{
				uv2/=iResolution.xy;
				col3 = alt ? texture2D(iChannel1, uv2).xyz : texture2D(iChannel0, uv2).xyz;
				}
			else { col3 = alt ? col1 : col2; }
			v1=float(n-(i+1))/float(n-1); v2=1.0-v1;
			//col=col3;
			col = alt ? v1*col3+v2*col1 : v1*col3+v2*col2;
			}

fragColor = vec4(col, 1.0);
}

float intersect(vec2 origin, vec2 direction, vec2 point1, vec2 point2)
{
vec2 v1, v2, v3;
float dot, t1, t2;

v1.x = origin.x - point1.x;
v1.y = origin.y - point1.y;
v2.x = point2.x - point1.x;
v2.y = point2.y - point1.y;
v3.x = -direction.y;
v3.y = direction.x;
dot = v2.x * v3.x + v2.y * v3.y;
if (abs(dot) < 0.000001) return(-1000.0);
t1 = (v2.x * v1.y - v2.y * v1.x) / dot;
t2 = (v1.x * v3.x + v1.y * v3.y) / dot;
if ((t1 >= 0.0) && (t2 >= 0.0) && (t2 <= 1.0)) return(t1);
return(-1000.0);
}
