#define DTR 0.01745329
#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))


vec2 uv=vec2(0);
vec3 cp,cn,cr,ss,oc,gl=vec3(0),vb,ro,rd,so,ld;
vec4 fc=vec4(0),cc=vec4(0);
float tt,cd,sd,md,io,oa,td=0.,li;
int es=0,ec=0,fi=1;


float bx(vec3 p,vec3 s){vec3 q=abs(p)-s;return min(max(q.x,max(q.y,q.z)),0.)+length(max(q,0.));}
float cy(vec3 p, vec2 s){p.y+=s.x/2.;p.y-=clamp(p.y,0.,s.x);return length(p)-s.y;}
float tor(vec3 p,vec2 t){return length(vec2(length(p.xz)-t.x,p.y))-t.y;}
float gy(vec3 p, vec3 s){return (abs(dot(sin(p*s.x),cos((p*s.y).zxy)))-s.z)/(max(s.x,s.y)*1.8);}
float smin(float a, float b, float k){float h=clamp(0.5+0.5*(b-a)/k,0.,1.);return mix(b,a,h)-k*h*(1.-h);}

float h11 (float a){return fract(sin((a)*12.9898)*43758.5453123);}

#define pi 3.1415926535
vec3 pal( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d ){
    return a + b*cos(2.*pi*(c*t+d));
}

vec3 mpal(vec3 pt)
{
		vec3 e = vec3(0.5); return pal(length(vec3(pt.z,sin(pt.y)*0.5,cos(pt.x)*0.5)), e*0.8,e-0.1,e,vec3(0.11,0.33,0.66));
}

float mid()
{
	float s = pow(sin(tt)*0.5+0.5,1.5);
	return sin(s + tt*0.1)*pi;
}

float mp(vec3 p)
{	
		vec3 pp = p;
	
		p.xy *= rot(tt*0.1);
		p.xy += sin(p.z*0.1);
	
		p.z += tt*4.;
		p.z=mod(p.z,30.)-15.;
	
		for(float i = 0.; i < 4.; i++)
		{
			p.xy = abs(p.xy) - 1.7;
			p.xy *= rot(i + tt*0.1);
			p.z=abs(p.z)-3.;
		}
		
		
		sd = bx(p,vec3(1.5,1.5,1));
		sd = max(-cy(pp.yzx, vec2(100,5)),sd);
		sd = min(sd,bx(pp+vec3(0,0,-15),vec3(10,10,1)));
		//sd = min(sd, length(pp-vec3(0,0,-50))-5.);
	
		sd=abs(sd)-0.001;
	

		
		if(sd<0.01)
		{	
			io=-1. + length(pp.xy)*0.35 > 1. ? length(pp.xy)*0.5 : -1.;
			oc=vec3(0.);
			oa=0.2;
			ss=mpal(vec3(p.xy,mid())) * (sin(p.x + p.y*1.1 + p.z*1.3)*0.5+0.5);
			ec=2;	

		}
		return sd;
}

void nm(){mat3 k=mat3(cp,cp,cp)-mat3(.001);cn=normalize(mp(cp)-vec3(mp(k[0]),mp(k[1]),mp(k[2])));cn=normalize(cn);}
void shtr(){so=cp+cn*0.05;md=64.;for(li=cd=0.;cd<64.;li++,cd+=mp(cp=ro+cn*0.05-ld*cd)){if(sd<md&&sd<cd)md=sd;if(sd<0.001||li>64.)break;}}
void tr(){for(li=cd=0.;cd<128.;){li++;cd+=mp(cp=ro+rd*cd);td+=sd;if(sd<0.0001||li>512.)break;}nm();}


void px(vec3 rd)
{
  vec3 bg=cc.rgb=mpal(vec3(2,0,mid()))*0.5 -pow(length(uv),4.)*0.8+gl;
	if(cd<128.)
	{cc.a=oa;ld=normalize(cp-vec3(0, 0, -40));
	float df=max(dot(cn,-ld),0.),sp=max(1.-length(cross(rd+ld,cn)),0.)*(1.2-oa),
	fo = exp(-pow(0.001*td,10.)),ao=1.-clamp(mp(cp+cn*.1)/.1,0.,1.);
	vec3 fr=pow(1.-abs(dot(rd,-cn)),3.)*mix(cc.rgb,oc,0.);
  cc.rgb=(oc*df+fr+sp+ss)-ao*0.;
	shtr();cc.rgb-=(1.-clamp(md/0.05,0.,1.))*0.3;
	cc.rgb = mix(bg, cc.rgb, fo);}
	else cc.a=1.;cc.rgb+=gl;
	cc.rgb*=max(max(cc.r,max(cc.g,cc.b)),1.);
}

void render(vec2 frag, vec2 res, float time, out vec4 col)
{
  uv=vec2(frag.x/res.x,frag.y/res.y);
  uv-=0.5;uv/=vec2(res.y/res.x,1);
	tt=mod(time+10.,100.);
	
  ro=vec3(cos(tt)*0.3,sin(tt)*0.3,-45. + (length(uv)+0.1)*pow(sin(tt)*0.5+0.5,1.5)*50.);
	rd=normalize(vec3(uv*(cos(tt*0.5)*0.1+0.9),1.));
	
	for(int i=0;i<10;i++)
  {
		tr();ro=cp-cn*(io<0.?-0.01:0.01);
		cr=refract(rd,cn,i%2==0?1./io:io);
    if((length(cr)==0.&&es<=0)||io<0.)
		{i++;cr=reflect(rd,cn);es=(io<0.?es:ec);}
		px(rd);if(max(es,0)%3==0) rd=cr;
		es--;fc=fc+vec4(cc.rgb*cc.a,cc.a)*(1.-fc.a);
		if(fc.a>=1.)break;
  }
  col=fc/fc.a;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if(mod(float(iFrame), 60./FPS) < 1. || iFrame < 5) render(fragCoord.xy,iResolution.xy,iTime,fragColor);
    else fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}