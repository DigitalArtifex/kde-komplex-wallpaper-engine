#define pi 3.1415926535
#define DTR 0.01745329
#define ang(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define vmin(a, b) (a.x < b.x ? a : b)


vec2 uv=vec2(0);
vec3 cp,cn,cr,ss,oc,gl=vec3(0),vb,ro,rd,so,ld,no,on,lp;
vec4 fc=vec4(0),cc=vec4(0),vs,hs,sp;
float tt,cd,sd,md,io,oa,td=0.,li;
int sk,sc;

//3D Shapes
float bx(vec3 p,vec3 s){vec3 q=abs(p)-s;return min(max(q.x,max(q.y,q.z)),0.)+length(max(q,0.));}
float fcy(vec3 p,vec2 s){vec2 w=vec2(length(p.xy)-s.x,abs(p.z)-s.y);return min(max(w.x,w.y),0.0)+length(max(w,0.0));}

//Maths
float h11(float a){return fract(sin((a)*12.9898)*43758.5453123);}
float noise(float p){float i=floor(p),f=fract(p);return mix(h11(i)*f,h11(i+1.)*(f-1.),f*f*(3.0-2.0*f));}
vec3 rot(vec3 a,vec3 r){a.zy*=ang(r.x);a.xz*=ang(r.y);a.yx*=ang(r.z);return a;}
float sharp(float inp,float sca){return 1.-pow(1.-pow(inp,sca),sca*2.);}
vec3 thsv(vec3 c){vec4 K=vec4(0.,-1./3.,2./3.,-1.),p=mix(vec4(c.bg,K.wz),vec4(c.gb,K.xy),step(c.b,c.g)),
q=mix(vec4(p.xyw,c.r),vec4(c.r,p.yzx),step(p.x,c.r));float d=q.x-min(q.w,q.y);
return vec3(abs(q.z+(q.w-q.y)/(6.*d)),d/(q.x),q.x);}
vec3 trgb(vec3 c){vec4 K=vec4(1.,2./3.,1./3.,3.);vec3 p=abs(fract(c.xxx+K.xyz)*6.-K.www);
return c.z*mix(K.xxx,clamp(p-K.xxx,0.,1.),c.y);}

//SDF Maths
float smin(float a,float b,float k){float h=clamp(0.5+0.5*(b-a)/k,0.,1.);return mix(b,a,h)-k*h*(1.-h);}

float gyroid(vec3 pos, vec3 size) {
    return abs(dot(sin(pos * size.x), cos((pos * size.y).zxy)) - size.z) / max(size.x, size.y) * 1.8;
}


float fbm(float x, float h, float n, float o)
{    
    vec2 g = vec2(2,exp2(-h));
		vec3 f = vec3(1,1,0);
		x -= o * 0.5;
    for(float i=0.; i<n; i++){f=vec3(f.xy*g,f.z+f.y*sin(f.x*x+o));}
    return f.z;
}


float surface(vec3 p, vec3 o)
{
	float v = p.y;
	v -= fbm(p.z * 0.5, 1., 3., o.x)*o.z+0.5;
	v -= fbm(p.x * 0.5, 1., 3., o.y)*o.z+0.5;
	return abs(v)-0.1;
}


float mp(vec3 p)
{		
    //p.xz *= ang(35.*DTR);
  
    vec3 pp = p;
  
    //p.xz*=ang(tt*0.2);
  
    p.z+=tt;
  
    float surf = surface(p,vec3(tt*0.3,tt,0.1));

  
    //p.xz*=ang(tt*0.2);
  
  
    p.x+=10.;
    
  
    vec2 moid = floor((p.xz+10.)/20.);
    float hid = h11(length(moid)+floor(tt*0.1));
    p.xz = mod(p.xz+10.,20.)-10.;
    p.xy += hid-0.5;
    float slice = h11(floor(tt*5.)*7.7);
    float tree = fcy(p.xzy, vec2(3.-p.y*0.03+hid*3.,999))+fbm(p.y*2.,1.,3.,tt)*0.1;
    if(hid>0.5||length(hid-slice)<0.03) tree = abs(fcy(p.xzy,vec2(5,100)))+1.;
    
    vec3 tp = p;
    
    p=pp;
    
    p.z += tt;
    p.y -= mix(30.,50.,noise(p.x*0.05+p.z*0.05+tt*0.05));
    
    
    p.xz = mod(p.xz+10.,20.)-10.;
    
    float canopy = length(p) - 3.;
    
    for(li=0.;li<3.;li++) {
      p=abs(p)-2.9-li;
      p=rot(p,vec3(0,h11(li*2.)*10.,0));
      p+=vec3(h11(li),h11(li*2.),h11(li*3.));
      canopy = smin(canopy, length(p) - 3.+li*0.5,8.);
    }
    
   
  
    tree = min(tree, canopy);
  
    surf = abs(surf) - 0.001;
  
    sd = min(surf, tree);
    
    
  
    
    
  
		if(sd<0.05)
		{	
      if(surf<sd+0.01) {
        io=pp.y<1.05?1.1:-1.;
        oc=vec3(0.1,0.3,0.7);
        oa=0.3;
        sp=vec4(1.3,1.5,0.,0.);
        no = vec3(0,0,0);
      }
      else if(canopy<sd+0.01){
        no = vec3(noise(p.x+p.y),noise(p.y+p.z),noise(p.z+p.x))-0.5;
        io=1.;
        oc=vec3(0.1,0.8,0.)*1.-hid*0.1;
        oa=1.;
        sp=vec4(1.,5.,0.,0.);
      }
      else {
        no = vec3(0,noise(tp.x*3.+hid*5.)+noise(tp.z*3.-hid*5.),0);
        io=1.;
        oc=vec3(0.,0.5+noise(p.y)*0.1,0.);
        oa=1.;
        sp=vec4(1.5,2.,0.,0.);
      }
     
 
			ss=vec3(0);

      lp = vec3(0,50,1000);
      sk = -1;
		}
    
    vs = vec4(1.5,1.,0.1, 16);
    hs = vec4(3.,0.3,3.,-0.3);
    
		return sd;
}

void nm(){mat3 k=mat3(cp,cp,cp)-mat3(.001);cn=on=normalize(mp(cp)-vec3(mp(k[0]),mp(k[1]),mp(k[2])));cn=rot(cn,no);cn=dot(cn,-rd)>0.?cn:reflect(cn,rd);}
  
  
void tr(vec4 i){for(li=cd=0.,md=64.;li+cd<i.x;li++,td+=sd*i.w){cd+=mp(cp=ro+on*i.y+(i.w>0.?rd:-ld)*cd)*i.z;if(sd<md&&cd<128.)md=sd;if(sd<(i.w>0.?1e-4:1e-2))break;}md/=.5;cp-=rd*.005;nm();}
void tr(vec3 o, vec3 d){for(li=cd=0.;li<12.;li++){cd+=mp(o+d*cd);if(cd<1e-3||cd>32.)break;}}  
 
vec3 tone(vec4 b, float d){
  vec3 r=thsv(b.rgb);
  r.z=decim(pow(max(b.w*r.z+vs.z,0.),vs.x)*vs.y-d,vs.w);
  r.x+=pow(1.-min(r.z*0.5,1.),hs.x)*hs.y*(r.x>.19&&r.x<.69?1.:-1.);
  r.y+=pow(1.-min(r.z*0.5,1.),hs.z)*hs.w;r.y*=2.-r.z;
  return trgb(r);
}

void px(vec3 rd, int i)
{
  vec3 bg=cc.rgb=decim(vec3(0.2,0.5,0.2)-pow(length(uv),5.)*0.5,vs.w)*0.3;
  
  
  
	if(cd<128.){
    
    
    
    cc.a=oa;ld=normalize(cp-lp);
	float df=max(dot(cn,-ld),0.),ps=pow(max(1.-length(cross(rd+ld,cn)),0.),sp.y)*sp.x,
	fo=exp(-pow(0.015*td,3.)),ao=0.,
	fr=max(pow(1.-abs(dot(rd,-cn)),3.),1e-4);vec3 sc=oc;float sh=0.;
  if(sp.w>0.){tr(cp+on*0.005,on);ao=(1.-pow(clamp(cd/24.,0.,1.),0.1))*sp.w;}
  if(sp.z>0.){tr(vec4(256,0.5,0.4,0.));sh=max(pow(1.-clamp(md,0.,1.),1.5),0.)*sp.z;}

    

  
  cc.rgb=tone(vec4(sc+(fr*mix(cc.rgb,oc,0.))+ss,df+(ps*max(1.-sh,0.))+fr*0.5),sh+ao);
  cc.rgb=mix(bg,cc.rgb,fo);

     
    }else {cc.a=1.;}cc.rgb+=gl;
	cc.rgb*=max(max(cc.r,max(cc.g,cc.b)),1.);
}

vec3 refracter(vec3 I, vec3 N, float ior)
{
    float k = 1.0 - ior * ior * (1.0 - dot(N, I) * dot(N, I));
    
    k = abs(k);
    
    if (k < 0.0)
        return vec3(0);
    else
        return ior * I - (ior * dot(N, I) + sqrt(k)) * N;
        
}

void render(vec2 frag, vec2 res, float time, out vec4 col)
{
  uv=vec2(frag.x/res.x,frag.y/res.y);
  uv-=0.5;uv/=vec2(res.y/res.x,1);
  tt=mod(time, 100.);
  
  
  vec2 pix = decim(uv, 100.);
  vec2 id = vec2(h11(pix.x),h11(pix.y));

  uv.x += (length(id)*sin(uv.y*30.+tt*h11(id.x)*5.))*id.x>0.2?0.03*pow(1.1-length(uv.y),5.):0.;
	
  uv.x += fract(uv.y*0.53+tt*0.1)>0.5?0.05:0.;  
    
  uv*=1.-pow(length(uv),5.)*0.2;  
    
  ro=vec3(0,5,-20);
  rd = normalize(vec3(uv, 1));
  
	for(int i=0;i<20;i++)
  {
		tr(vec4(256,0,1,1));ro=cp-cn*(io<0.?-0.01:0.01);
		cr=refract(rd,cn,i%2==0?1./io:io);
    if(io<0.)cr=reflect(rd,cn);px(rd, i);
     if(length(cr)!=0.)rd=cr;
        
        
		if(sc<1) fc=fc+vec4(cc.rgb*cc.a,cc.a)*(1.-fc.a);
		if(fc.a>=1.)break;sc=sc==0?io<0.?0:sk:sc-1;
  }
  col=fc/fc.a;
	
	col *= 1.-pow(length(uv), 1.)*0.8;
	col = pow(col,vec4(0.9));
	
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    if(mod(float(iFrame), 60./FPS) < 1. || iFrame < 5) render(fragCoord.xy,iResolution.xy,iTime,fragColor);
    else fragColor = texture(iChannel0, fragCoord / iResolution.xy);
}