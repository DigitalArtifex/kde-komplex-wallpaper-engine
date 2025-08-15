/////////////////////////////////////////////////////////////////////
//     raymarch scene
/////////////////////////////////////////////////////////////////////
// more infos about modeling with distance functions:
// https://iquilezles.org/articles/distfunctions
/////////////////////////////////////////////////////////////////////


#define IT   64    // raycasting iterations
#define PR   .0005 // raycasting precision

//==========================================================
//            signed DISTANCE FIELD PRIMITIVES 
//==========================================================
//
// distance field primitives by Inigo Quilez
// https://www.shadertoy.com/view/Xds3zN
//
//==========================================================

//-----------------------------------------------------------
//                       SPHERE            
//
float sdSphere( vec3 p, float s )
{
  return length(p) - s;
}

//-----------------------------------------------------------
//                     RECTANGLE
//
float sdBox( vec3 p, vec3 b )
{   
  vec3 d = abs(p) - b ;   
  return max(min(d.x, min(d.y, d.z)), .0) + length(max(d, .0));
}

//==========================================================
//                     OPERATIONS
//==========================================================
//
// distance field primitives by Inigo Quilez
// https://www.shadertoy.com/view/Xds3zN
//
//==========================================================

// polynomial smooth min
// add shapes smoother.

float smin( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * (b - a) / k, 0.0, 1.0 );
    return mix( b, a, h ) - k * h * (1.0 - h);
}

// polynomial smooth min to add shapes smoother.
// sustract shapes smoother.

float smax( float a, float b, float k )
{
    float h = clamp( 0.5 + 0.5 * (a - b) / k, 0.0, 1.0 );
    return mix( b, a, h ) + k * h * (1.0 - h);
}


//==========================================================
//          SKULL SIGNED DISTANCE FIELD 
//==========================================================


float sdSkull( vec3 p, float s )
{
    
    
  // --------------------------------------------------------
  // domain deformation on radius (s) brings some interesting
  // results this deformation sould be applied to big shapes 
  // in order to preserve details. 
    
  float ss = noise(p * 9.);
  ss = mix(s,ss *.5,.1);
  
  
  // sp is using symetry on z axis
  vec3 sp = vec3(p.x, p.y, abs(p.z));
    
      
  // kind of morphing effect 
  //s = clamp(cos(iTime*.5), .20,.35);

  float shape = sdSphere(p - vec3(.0,.05,.0), s * .95 * cos(cos(p.y*11.)* p.z * 2.3) );
  //---------------------------------------------------------  
  // first part external skull top
  // --------------------------------------------------------
    
  // globe front 
  shape = smin(shape,  sdSphere (p - vec3(.10, 0.23, 0.00), s * .82), .09);
    
  // globe back 
  shape = smin(shape,  sdSphere (p - vec3(-.1, 0.24, 0.00), s * .82), .09);
    
  // eye brow
  shape = smin(shape,  sdSphere (sp - vec3(.25, 0.07, 0.10), s * .36 * cos(p.y * 7.0)), .02);
    
  // lateral holes - symmetry
  shape = smax(shape, -sdSphere (sp - vec3(.15, -.01, 0.31), s * .28 * cos(p.x * .59)), .02);  
    
  //checkbones - symmetry
  shape = smin(shape, sdSphere(sp-vec3(.22,-.13,.18), s*.11),.09);
  
  // empty the skull
  shape = max(shape, -sdSphere(p - vec3(.0,.05,.0), s * .90 * cos(cos(p.y*11.)* p.z * 2.3) ));  
  shape = smax(shape,  -sdSphere (p - vec3(.10, 0.23, 0.00), s * .74),.02);
  shape = smax(shape,  -sdSphere (p - vec3(-.1, 0.24, 0.00), s * .74),.02);
  shape = smax(shape,  -sdSphere (p - vec3(.0, 0.24, 0.00), s * .74),.02);
  
  // eye balls - symmetry
  shape = smax(shape, -sdSphere(sp-vec3(.32,-.04,.140), s  * .28 * cos(p.y*10.)),.03);
  
  // nose
  //-----------------------------------------------------------
    
  // base nose shape
  float temp = sdSphere(p- vec3(cos(.0)*.220,-.05, sin(.0)*.3), s * .35 * cos(sin(p.y*22.)*p.z*24.));
    
  // substract the eyes balls ( symetrix) & skukl globe
  temp = smax(temp, -sdSphere(sp-vec3(.32,-.04,.140), s * .35 * cos(p.y*10.)), .02); 
  temp = smax(temp, -sdSphere(p - vec3(.0,.05,.0), s * .90 * cos(cos(p.y*11.)* p.z * 2.3) ),.02);
  
  // add nose shape to skull 
  shape = smin(shape,temp,.015);  
  
  // empty the nose
  shape = smax(shape, - sdSphere(p- vec3(cos(.0)*.238,-.09, sin(.0)*.3), s * .3 * cos(sin(p.y*18.)*p.z*29.)),.002);
  
  // substract bottom
  shape = smax(shape, -sdSphere(p- vec3(-.15,-0.97, .0), s * 2.5 ),.01);
    
  // I like the noise deformation on this edge with ss for the sphere radius.
  // It give a more natural look to the skull.
  shape = smax(shape, -sdSphere(p- vec3(-.23,-0.57, .0), abs(ss) * 1.6 ),.01);
    
  //--------------------------------------------------------- 
  // skull part2: UP jaws
  // --------------------------------------------------------
    
  temp = smax(sdSphere(p - vec3(.13,-.26,.0), .45 * s), -sdSphere(p - vec3(.125,-.3,.0), .40 * s), .01);
  
  // substract back
  temp = smax(temp,-sdSphere(p - vec3(-.2,-.1,.0), .9 * s), .03);
  
  // substract bottom  
  temp = smax(temp,-sdSphere(p - vec3(.13,-.543,.0), .9 * s), .03);
  
  // substract up  
  temp = max(temp, -sdSphere(p - vec3(.0,.02,.0), s * .90 * cos(cos(p.y*11.)* p.z * 2.3) ));  
  shape = smin(shape, temp, .07);
    
   
  // Teeths - symmetry
  //-----------------------------------------------------------
 
  temp = sdSphere(p - vec3(.26, -.29, .018), .053 * s );
  temp = min(temp, sdSphere(p - vec3(.26, -.29, -.018), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.25, -.29, .05), .05 * s ));
  temp = min(temp, sdSphere(sp - vec3(.235, -.29, .08), .05 * s ));
  temp = min(temp, sdSphere(sp - vec3(.215, -.28, .1), .05 * s ));
  temp = max(temp, -sdSphere(p - vec3(.16, -.35, .0), .33 * s ));   
  temp = min(temp, sdSphere(sp - vec3(.18, -.28, .115), .05 * s ));
  temp = min(temp, sdSphere(sp - vec3(.14, -.28, .115), .06 * s ));
  temp = min(temp, sdSphere(sp - vec3(.11, -.28, .115), .06 * s ));
  temp = min(temp, sdSphere(sp - vec3(.08, -.28, .115), .06 * s ));

   
  shape = smin(shape, temp, .03); 
   
  // DOWN Jaws
  //-----------------------------------------------------------
  
  temp = sdSphere(p - vec3(.1,-.32,.0), .43 * s);  
  temp = smax (temp, - sdSphere(p - vec3(.1,-.32,.0), .37 * s ),.02);  
  temp = smax(temp, - sdSphere(p - vec3(.1,-.034,.0), 1.03 * s),.02) ;  
  temp = smax(temp, - sdSphere(p - vec3(.0,-.4,.0), .35 * s),.02);   
  // symmetry
  temp = smin(temp, sdBox(sp - vec3(.04 -.03 * cos(p.y * 20.2),-.23, .27 + sin(p.y)*.27), vec3(cos(p.y*4.)*.03,.12,.014)), .13);
  temp = max(temp, - sdSphere(sp - vec3(.0,.153,.2), .85 * s)); 
  temp = smin (temp, sdSphere(sp - vec3(.2, -.45, 0.05), .05 * s ),.07);  
 
  shape = smin(shape, temp, .02);  
    
    
  // Teeths -  symmetry
  //--------------------------------------------------------
 
  temp = sdSphere(p - vec3(.23, -.34, .018), .053 * s );
  temp = min(temp, sdSphere(p - vec3(.23, -.34, -.018), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.22, -.34, .048), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.20, -.34, .078), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.17, -.35, .098), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.14, -.35, .11), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.11, -.35, .11), .053 * s));
  temp = min(temp, sdSphere(sp - vec3(.08, -.35, .11), .053 * s));
      
 
  shape = 1.5 * smin(shape, temp, .025);  
    
  return shape ;  
    
}	



//==========================================================
//                     SCENE MANAGER  
//
// here pull in all the objects into the scene no worry the order 
// 
//==========================================================

vec2 map(vec3 pos)
{
 
  vec2 scene = vec2(.5 * sdSkull(pos, .35), 39.);
  
  return scene;     
}

//==========================================================//
//                     RAY CASTER  
//
// note : iteration IT and precision PR are defined on top
// ro and rd are ray origin and direction;
//
//==========================================================//

vec2 castRay( vec3 ro, vec3 rd )    
{
    int   i     = 0;                           // raycaster iteration loop factor
    float close = 1.0;                         // raycaster min distance
    float far   = 3.0;                         // raycaster max distance
   	float p     = PR * close;                  // raycaster precision
    float id    = .0;                          // casted object id
       
    while( i ++< IT)
    {    
	  vec2 res = map(ro + rd * close);         // map() > response vec2(depth, id)
        
      if(abs(res.x) < p || close > far) break; // break when object something is encountred or when outside of bounds
     
      	close += res.x;				           // add depth to caster 
	  	id  = res.y;						   // write object'id
    }

    //if( close > far ) id = .0;				   // when there no response we return the background id
   
    return vec2( close, id );				   // return depth value and id
}


//==========================================================//
//                       NORMALS 
//
//==========================================================//


vec3 calcNormal( vec3 pos )
{
    vec2 e = vec2(1., -1.) * PR;
    return normalize(e.xyy * map(pos + e.xyy).x + 
					 e.yyx * map(pos + e.yyx).x + 
					 e.yxy * map(pos + e.yxy).x + 
					 e.xxx * map(pos + e.xxx).x );
}

//==========================================================//
//                       RENDERER 
//
//==========================================================//


vec3 render (vec2 p, vec3 ro, vec3 rd )
{ 
  
  vec2  res = castRay(ro,rd);        
  float t   = res.x;	   						 
  float m   = res.y;
  vec3  col = vec3(.0,.0,.0);
  vec3 pos = ro + t * rd;
  vec3 nor = calcNormal(pos);
        
  // material color 
      
  col = .45 + .55 * sin(vec3(.05, .08, .1) *  m - 1.);
      
  // depth fog 

  col = mix(col, vec3(.0,.0,.0), 1. - exp(-0.02 * pow(t, 9.5)));

  return vec3( clamp(col,.0,1.0));
}


//==========================================================//
//                       CAMERA 
//
//==========================================================//

mat3 setCamera(vec3 ro)
{
  vec3 cw = normalize(- ro);
  vec3 cp = vec3(sin(.0), cos(.0), .0);
  vec3 cu = normalize(cross(cw,cp));
  vec3 cv = normalize(cross(cu,cw));
  
  return mat3(cu, cv, cw);
}

//==========================================================//
//                       MAIN 
//
//==========================================================//

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    
  vec3 tot = vec3(.0,.0,.0);
  vec2 p = (-R.xy + 2.0 * fragCoord)/R.y;
  vec2 mo = iMouse.xy/iResolution.xy;

  // camera	
  //---------------------------
 
  vec3 ro = vec3(1.6*cos(iTime*.6),.0,1.6*sin(iTime*.6));
  mat3 ca = setCamera(ro);    
    
  // ray direction

  vec3 rd = ca * normalize(vec3(p.xy, 2.));

  // render	

  vec3 col = render(p, ro, rd);

  // gamma

  col = pow( col, vec3(0.25) );

    
  tot += col; 
  fragColor = vec4( tot, 1.0 );

}