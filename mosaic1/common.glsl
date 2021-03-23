
const float PI        = 3.14159265259;
const float PI2       = (PI * 2.0);

mat2 rot2(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat2(c, s, -s, c);
}




