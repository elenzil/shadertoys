
const float PI        = 3.14159265259;
const float PI2       = (PI * 2.0);

struct raySeg_t {
    vec2  pnt;
    vec2  dir;  // length = 1
    float len;
    vec2  nrm;  // dir rotated 90 deg ccw
};

// return a first of two vec4's encoding the data
vec4 packRaySeg1of2(in raySeg_t rs) {
    return vec4(rs.pnt, rs.dir);
}
// return a second of two vec4's encoding the data
vec4 packRaySeg2of2(in raySeg_t rs) {
    return vec4(rs.len, 0.0, rs.nrm);
}

raySeg_t unpackRaySeg(in vec4 v1, in vec4 v2) {
    raySeg_t rs;
    rs.pnt = v1.xy;
    rs.dir = v1.zw;
    rs.len = v2.x;
    rs.nrm = v2.zw;
    return rs;
}

raySeg_t calcRaySeg(in vec2 ptA, in vec2 ptB) {
    raySeg_t ret;
    ret.pnt  = ptA;
    ret.dir  = ptB - ptA;
    ret.len  = length(ret.dir);
    ret.dir /= ret.len;
    ret.nrm  = vec2(-ret.dir.y, ret.dir.x); // should this just be runtime ?
    return ret;
}

