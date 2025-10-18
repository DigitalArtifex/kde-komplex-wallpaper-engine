//based on the barrel deformation shader taken from:
//http://www.geeks3d.com/20140213/glsl-shader-library-fish-eye-and-dome-and-barrel-distortion-post-processing-filters/2/

//CONTROL VARIABLES
float uPower = 0.2; // barrel power - (values between 0-1 work well)
float uSpeed = 5.0;
float uFrequency = 5.0;

vec2 Distort(vec2 p, float power, float speed, float freq)
{
    float theta  = atan(p.y, p.x);
    float radius = length(p);
    radius = pow(radius, power*sin(radius*freq-iTime*speed)+1.0);
    p.x = radius * cos(theta);
    p.y = radius * sin(theta);
    return 0.5 * (p + 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord )
{
  vec2 xy = 2.0 * fragCoord.xy/iResolution.xy - 1.0;
  vec2 uvt;
  float d = length(xy);

  //distance of distortion
  if (d < 1.0 && uPower != 0.0)
  {
    //if power is 0, then don't call the distortion function since there's no reason to do it :)
    uvt = Distort(xy, uPower, uSpeed, uFrequency);
  }
  else
  {
    uvt = fragCoord.xy / iResolution.xy;
  }
  vec4 c = texture(iChannel0, uvt);
  fragColor = c;
}
