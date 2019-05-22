/*
    orion elenzil 2019

*/

const float PI           =   3.14159265359;
const float TAU          =   PI * 2.0;
const float gutterWidth  =  50.0;


void mainImage(out vec4 RGBA, in vec2 XY) {
    RGBA.a   = 1.0;
    float smallWay = min(iResolution.x, iResolution.y);
    vec2  uv = (XY * 2.0 - iResolution.xy)/smallWay;
    float t  = iTime * TAU / 100.0;

    float fullRad = 1.0 - gutterWidth / smallWay;
    float rad     = clamp(length(uv) / fullRad, 0.0, 1.0);

    float b  = 0.5;

    b = rad;
    b = sqrt(rad);
//  b = sqrt(1.0 - rad * rad) / (PI); 

    b = mix(b, 0.5, smoothstep(4.0, 0.0, (1.0 - rad) * smallWay));

//  b = pow(b, 0.4545);

    vec3 rgb = vec3(b);

    RGBA.rgb = rgb;
}

// grimoire bindings
out vec4 fragColor; void main() { mainImage(fragColor, gl_FragCoord.xy); }
