// The MIT License
// Copyright © 2018 Inigo Quilez
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// Smooth vs sharp boolean operations for combining shapes

// Related techniques:
//
// Elongation  : https://www.shadertoy.com/view/Ml3fWj
// Rounding    : https://www.shadertoy.com/view/Mt3BDj
// Onion       : https://www.shadertoy.com/view/MlcBDj
// Metric      : https://www.shadertoy.com/view/ltcfDj
// Combination : https://www.shadertoy.com/view/lt3BW2
// Repetition  : https://www.shadertoy.com/view/3syGzz
// Extrusion2D : https://www.shadertoy.com/view/4lyfzw
// Revolution2D: https://www.shadertoy.com/view/4lyfzw
//
// More information here: http://iquilezles.org/www/articles/distfunctions/distfunctions.htm


float opUnion( float d1, float d2 )
{
    return min(d1,d2);
}

float opSubtraction( float d1, float d2 )
{
    return max(-d1,d2);
}

float opIntersection( float d1, float d2 )
{
    return max(d1,d2);
}

float opSmoothUnion( float d1, float d2, float k )
{
    float h = max(k-abs(d1-d2),0.0);
    return min(d1, d2) - h*h*0.25/k;
    //float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    //return mix( d2, d1, h ) - k*h*(1.0-h);
}

float opSmoothSubtraction( float d1, float d2, float k )
{
    float h = max(k-abs(-d1-d2),0.0);
    return max(-d1, d2) + h*h*0.25/k;
    //float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    //return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float opSmoothIntersection( float d1, float d2, float k )
{
    float h = max(k-abs(d1-d2),0.0);
    return max(d1, d2) + h*h*0.25/k;
    //float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    //return mix( d2, d1, h ) + k*h*(1.0-h);
}

//-------------------------------------------------

float sdSphere( in vec3 p, in float r )
{
    return length(p)-r;
}


float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0)) - r;
}

// an infinite slab along the XZ plane with radius r, overall height 2r.
float sdSlabXZ( in vec3 p, float r )
{
    return abs(p.y) - r;
}

float sdParabola( in vec2 pos, in float k )
{
    pos.x = abs(pos.x);
    
    float ik = 1.0/k;
    float p = ik*(pos.y - 0.5*ik)/3.0;
    float q = 0.25*ik*ik*pos.x;
    
    float h = q*q - p*p*p;
    float r = sqrt(abs(h));

    float x = (h>0.0) ? 
        // 1 root
        pow(q+r,1.0/3.0) - pow(abs(q-r),1.0/3.0)*sign(r-q) :
        // 3 roots
        2.0*cos(atan(r,q)/3.0)*sqrt(p);
    
    return length(pos-vec2(x,k*x*x)) * sign(pos.x-x);
}

//---------------------------------

mat2 rot2(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c);
}

float opOnion( in float sdf, in float thickness )
{
    return abs(sdf)-thickness;
}

float map(in vec3 pos)
{
    float d = 1e10;
        
    vec3 p = pos - vec3(0.0, 0.5 ,0.0);

    p.xy *= rot2(iTime * 0.77);
    p.zy *= rot2(iTime * 0.97);

    float o = 0.0;
    vec2 q = vec2(length(p.xz) - o, p.y);
    float sep = 0.5;
    vec2 up = vec2(0.0, 1.0);
    float d1 = sdParabola(q + up * sep,  0.5);
    float d2 = sdParabola(q - up * sep, -0.5);
    float pd = max(d1, d2);
    pd = opOnion(pd, 0.01);
    pd = max(pd, p.y - sep * 0.9);

    d = min( d, pd );
    d = min( d, pos.y + 0.75);

    return d;
}

// http://iquilezles.org/www/articles/normalsSDF/normalsSDF.htm
vec3 calcNormal( in vec3 pos )
{
    const float ep = 0.0001;
    vec2 e = vec2(1.0,-1.0)*0.5773;
    return normalize( e.xyy*map( pos + e.xyy*ep ) + 
                      e.yyx*map( pos + e.yyx*ep ) + 
                      e.yxy*map( pos + e.yxy*ep ) + 
                      e.xxx*map( pos + e.xxx*ep ) );
}

// http://iquilezles.org/www/articles/rmshadows/rmshadows.htm
float calcSoftshadow( in vec3 ro, in vec3 rd, float tmin, float tmax, const float k )
{
    float res = 1.0;
    float t = tmin;
    for( int i=0; i<50; i++ )
    {
        float h = map( ro + rd*t );
        res = min( res, k*h/t );
        t += clamp( h, 0.02, 0.20 );
        if( res<0.0005 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );
}


#define AA 1

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
   vec3 tot = vec3(0.0);
    
    #if AA>1
    for( int m=0; m<AA; m++ )
    for( int n=0; n<AA; n++ )
    {
        // pixel coordinates
        vec2 o = vec2(float(m),float(n)) / float(AA) - 0.5;
        vec2 p = (-iResolution.xy + 2.0*(fragCoord+o))/iResolution.y;
        #else    
        vec2 p = (-iResolution.xy + 2.0*fragCoord)/iResolution.y;
        #endif
 
        vec3 ro = vec3(0.0,2.0,7.0);
        vec3 rd = normalize(vec3(p-vec2(0.0,0.8),-3.5));

        float t = 3.0;
        for( int i=0; i<100; i++ )
        {
            vec3 p = ro + t*rd;
            float h = map(p);
            if( abs(h)<0.00001 * t || t>51.0 ) break;
            t += h;
        }

        vec3 col = vec3(0.0);

        if( t<50.0 )
        {
            vec3 pos = ro + t*rd;
            vec3 nor = calcNormal(pos);
            vec3  lig = normalize(vec3(0.0,1.0,0.0));
            float dif = clamp(dot(nor,lig),0.0,1.0);
            float sha = calcSoftshadow( pos, lig, 0.001, 1.0, 16.0 );
            float amb = 0.5 + 0.5*nor.y;
            col = vec3(0.05,0.1,0.15)*amb + 
                  vec3(1.00,0.9,0.80)*dif*sha;
        }

        col = sqrt( col );
        tot += col;
    #if AA>1
    }
    tot /= float(AA*AA);
    #endif

    fragColor = vec4( tot, 1.0 );
}

#ifdef GRIMOIRE
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
#endif
