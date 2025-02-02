#define PI 3.1415926535897932384626433832795
#define PI2 6.283185307179586
#define AUDIO_DATA_LENGTH 128.0

// simulation
varying vec2 vUv;


uniform sampler2D tPositions;
uniform sampler2D origin;
uniform int audioData[int(AUDIO_DATA_LENGTH)];




uniform float timer;
uniform float amplitude;
uniform float maxHeight;
uniform float noiseConstant;
uniform float lifetime;

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float atan2(in float y, in float x)
{
    return x == 0.0 ? sign(y)*PI/2.0 : sign(y)*atan(y, x);
}

float calculateY(vec3 pos){
    float angle = atan2(pos.z, pos.x);
    angle = (angle < 0.0) ? (angle + PI) : angle;
    int index = int( angle / PI2 * AUDIO_DATA_LENGTH);
    for (int x = 0; x < int(AUDIO_DATA_LENGTH); x++) { 
        if (x == index) {
             return float(audioData[x]) / AUDIO_DATA_LENGTH - 1.0;
        }
    }
    return 0.0;
}

float calculateVel(vec3 pos){
    float angle = atan2(pos.z, pos.x);
    angle = (angle < 0.0) ? (angle + PI) : angle;
    int index = int( angle / PI2 * AUDIO_DATA_LENGTH);
    for (int x = 0; x < int(AUDIO_DATA_LENGTH); x++) { 
        if (x == index) {
             return float(audioData[x]) / AUDIO_DATA_LENGTH - 1.0;
        }
    }
    return 0.0;
}

vec3 mod289_3_0(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289_3_0(vec4 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute_3_1(vec4 x) {
     return mod289_3_0(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt_3_2(vec4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise_3_3(vec3 v)
  {
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D_3_4 = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g_3_5 = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g_3_5;
  vec3 i1 = min( g_3_5.xyz, l.zxy );
  vec3 i2 = max( g_3_5.xyz, l.zxy );

  //   x0 = x0 - 0.0 + 0.0 * C.xxx;
  //   x1 = x0 - i1  + 1.0 * C.xxx;
  //   x2 = x0 - i2  + 2.0 * C.xxx;
  //   x3 = x0 - 1.0 + 3.0 * C.xxx;
  vec3 x1 = x0 - i1 + C.xxx;
  vec3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
  vec3 x3 = x0 - D_3_4.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

// Permutations
  i = mod289_3_0(i);
  vec4 p = permute_3_1( permute_3_1( permute_3_1(
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 ))
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients: 7x7 points over a square, mapped onto an octahedron.
// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
  float n_ = 0.142857142857; // 1.0/7.0
  vec3  ns = n_ * D_3_4.wyz - D_3_4.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  //vec4 s0 = vec4(lessThan(b0,0.0))*2.0 - 1.0;
  //vec4 s1 = vec4(lessThan(b1,0.0))*2.0 - 1.0;
  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1_3_6 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0_3_7 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1_3_6.xy,h.z);
  vec3 p3 = vec3(a1_3_6.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt_3_2(vec4(dot(p0_3_7,p0_3_7), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0_3_7 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0_3_7,x0), dot(p1,x1),
                                dot(p2,x2), dot(p3,x3) ) );
  }


vec3 snoiseVec3_2_8( vec3 x ){

  float s  = snoise_3_3(vec3( x ));
  float s1 = snoise_3_3(vec3( x.y - 19.1 , x.z + 33.4 , x.x + 47.2 ));
  float s2 = snoise_3_3(vec3( x.z + 74.2 , x.x - 124.5 , x.y + 99.4 ));
  vec3 c = vec3( s , s1 , s2 );
  return c;

}


vec3 curlNoise_2_9( vec3 p ){
  
  const float e = .1;
  vec3 dx = vec3( e   , 0.0 , 0.0 );
  vec3 dy = vec3( 0.0 , e   , 0.0 );
  vec3 dz = vec3( 0.0 , 0.0 , e   );

  vec3 p_x0 = snoiseVec3_2_8( p - dx );
  vec3 p_x1 = snoiseVec3_2_8( p + dx );
  vec3 p_y0 = snoiseVec3_2_8( p - dy );
  vec3 p_y1 = snoiseVec3_2_8( p + dy );
  vec3 p_z0 = snoiseVec3_2_8( p - dz );
  vec3 p_z1 = snoiseVec3_2_8( p + dz );

  float x = p_y1.z - p_y0.z - p_z1.y + p_z0.y;
  float y = p_z1.x - p_z0.x - p_x1.z + p_x0.z;
  float z = p_x1.y - p_x0.y - p_y1.x + p_y0.x;

  const float divisor = 1.0 / ( 2.0 * e );
  return normalize( vec3( x , y , z ) * divisor );

}


void main() {


    vec3 pos = texture2D( tPositions, vUv ).xyz;

    if ( rand(vUv + timer ) > (0.9 + lifetime) ) {

        pos = texture2D( origin, vUv ).xyz;
        pos.x += (rand(vUv + timer + pos.x )-0.5)*0.4;
        pos.z += (rand(vUv + timer + pos.z )-0.5)*0.4;
        pos.y = (4.0*amplitude + 0.5*calculateY(pos)  + 0.5*(rand(vUv + timer + pos.y )-0.5) - 2.0)*maxHeight;

    } else{
    	pos.x += pos.x*exp(-abs(pos.z*pos.z + pos.x*pos.x - 1.0)/25.0)/20.0;
      pos.z += pos.z*exp(-abs(pos.z*pos.z + pos.x*pos.x - 1.0)/25.0)/20.0;
    	pos += curlNoise_2_9(pos)*noiseConstant;
        
    }

    // Write new position out
    gl_FragColor = vec4(pos, 1.0);


}