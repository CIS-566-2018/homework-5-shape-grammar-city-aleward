#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}
vec4 taylorInvSqrt(vec4 r){return 1.79284291400159 - 0.85373472095314 * r;}

float snoise(vec3 v){ 
  const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
  const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

// First corner
  vec3 i  = floor(v + dot(v, C.yyy) );
  vec3 x0 =   v - i + dot(i, C.xxx) ;

// Other corners
  vec3 g = step(x0.yzx, x0.xyz);
  vec3 l = 1.0 - g;
  vec3 i1 = min( g.xyz, l.zxy );
  vec3 i2 = max( g.xyz, l.zxy );

  //  x0 = x0 - 0. + 0.0 * C 
  vec3 x1 = x0 - i1 + 1.0 * C.xxx;
  vec3 x2 = x0 - i2 + 2.0 * C.xxx;
  vec3 x3 = x0 - 1. + 3.0 * C.xxx;

// Permutations
  i = mod(i, 289.0 ); 
  vec4 p = permute( permute( permute( 
             i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
           + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
           + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

// Gradients
// ( N*N points uniformly over a square, mapped onto an octahedron.)
  float n_ = 1.0/7.0; // N=7
  vec3  ns = n_ * D.wyz - D.xzx;

  vec4 j = p - 49.0 * floor(p * ns.z *ns.z);  //  mod(p,N*N)

  vec4 x_ = floor(j * ns.z);
  vec4 y_ = floor(j - 7.0 * x_ );    // mod(j,N)

  vec4 x = x_ *ns.x + ns.yyyy;
  vec4 y = y_ *ns.x + ns.yyyy;
  vec4 h = 1.0 - abs(x) - abs(y);

  vec4 b0 = vec4( x.xy, y.xy );
  vec4 b1 = vec4( x.zw, y.zw );

  vec4 s0 = floor(b0)*2.0 + 1.0;
  vec4 s1 = floor(b1)*2.0 + 1.0;
  vec4 sh = -step(h, vec4(0.0));

  vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
  vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

  vec3 p0 = vec3(a0.xy,h.x);
  vec3 p1 = vec3(a0.zw,h.y);
  vec3 p2 = vec3(a1.xy,h.z);
  vec3 p3 = vec3(a1.zw,h.w);

//Normalise gradients
  vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
  p0 *= norm.x;
  p1 *= norm.y;
  p2 *= norm.z;
  p3 *= norm.w;

// Mix final noise value
  vec4 m = max(0.6 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
  m = m * m;
  return 42.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
}

vec3 mix3(vec3 v1, vec3 v2, vec3 v3, float f) {
  if (f < 0.6) {
    return mix(v1, v2, f * 1.666666666f);
  } else {
    return mix(v2, v3, (f - 0.6) * 2.5f);
  }
}

void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = fs_Col;

        // Calculate the diffuse term for Lambert shading

        float noise = //(snoise(fs_Pos.xyz) + 1.f) * 0.3 - (snoise(fs_Pos.xyz * 6.f) + 1.f) * 0.2;
        (snoise(fs_Pos.xyz) + 1.0) / 2.0;

        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        diffuseTerm = min(diffuseTerm, 1.0);
        diffuseTerm = max(diffuseTerm, 0.0);

        if (diffuseColor.r <= diffuseColor.g && diffuseColor.g > diffuseColor.b) {
          diffuseColor.g *= noise;
          diffuseColor.b = (1.f - noise);
        } else if (diffuseColor.b > diffuseColor.r + diffuseColor.g) {
          float waterMove  = sin(u_Time * 0.01) * 0.5 + sin(u_Time * 0.02) * 0.3 + sin(u_Time * 0.05) * 0.2 + cos((u_Time + 27.f) * 0.01) * 0.3;
          // previously 10 + waterMove and 5 + waterMove
          float watText = sqrt(sqrt(abs(snoise(fs_Pos.xyz * (5.f + waterMove) )))) * 0.6 + sqrt(sqrt(abs(snoise(fs_Pos.xyz * (2.f + waterMove))))) * 0.4;
          diffuseColor.rgb = mix3(vec3(1.f, 1.f, 1.f), vec3(199.f / 255.f, 0.f / 255.f, 255.f / 255.f), vec3(0.f, 0.15f, 0.75f), watText);
          //diffuseTerm = mix(sqrt(diffuseTerm), diffuseTerm, watText);
        }

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.

        // Compute final shaded color
        
        out_Col = vec4(diffuseColor.rgb * lightIntensity, diffuseColor.a);
        
        //Noise test
        //out_Col = vec4(noise, noise, noise, diffuseColor.a);
}
