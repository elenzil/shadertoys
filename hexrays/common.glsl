
const float PI        = 3.14159265259;
const float PI2       = (PI * 2.0);

struct lineSeg_t {
    vec2  ptA;
    vec2  ptB;
};

struct lineSegEx_t {
    lineSeg_t pts;
    float     len;  // |a->b|
    vec2      dir;  // a->b, normalized
    vec2      nrm;  // dir rotated 90 deg ccw
                    // todo precalc this stuff in bufferA
};
