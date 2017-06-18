module voxtrac.tracer;

import std.math;
import std.algorithm;
import std.conv;
import std.typecons;
import std.stdio;
import voxtrac.math;
import voxtrac.tree;

VectorF3 traceInside(VectorF3 orig, VectorF3 dir, RectI3D vol) {
    float x = dir.x < 0 ? vol.x0 : vol.x1;
    float y = dir.y < 0 ? vol.y0 : vol.y1;
    float z = dir.z < 0 ? vol.z0 : vol.z1;

    float tx = abs((x - orig.x) / dir.x);
    float ty = abs((y - orig.y) / dir.y);
    float tz = abs((z - orig.z) / dir.z);

    float t = min(tx, ty, tz);

    VectorF3 p = orig + dir * t;

    if (t == tx)
        p.x = roundTo!int(p.x);
    else if (t == ty)
        p.y = roundTo!int(p.y);
    else if (t == tz)
        p.z = roundTo!int(p.z);

    return p;
}

Nullable!VectorF3 traceOutside(VectorF3 orig, VectorF3 dir, RectI3D vol) {
    float x = dir.x < 0 ? vol.x1 : vol.x0;
    float y = dir.y < 0 ? vol.y1 : vol.y0;
    float z = dir.z < 0 ? vol.z1 : vol.z0;

    float tx = (x - orig.x) / dir.x;
    float ty = (y - orig.y) / dir.y;
    float tz = (z - orig.z) / dir.z;

    if (tx >= 0) {
        VectorF3 ix = orig + dir * tx;
        if (ix.y >= vol.y0 && ix.y <= vol.y0 && ix.z >= vol.z0 && ix.z <= vol.z1) {
            ix.x = roundTo!int(ix.x);
            return nullable(ix);
        }
    }

    if (ty >= 0) {
        VectorF3 iy = orig + dir * ty;
        if (iy.x >= vol.x0 && iy.x <= vol.x1 && iy.z >= vol.z0 && iy.z <= vol.z1) {
            iy.y = roundTo!int(iy.y);
            return nullable(iy);
        }
    }

    if (tz >= 0) {
        VectorF3 iz = orig + dir * tz;
        if (iz.x >= vol.x0 && iz.x <= vol.x1 && iz.y >= vol.y0 && iz.y <= vol.y1) {
            iz.z = roundTo!int(iz.z);
            return nullable(iz);
        }
    }

    return Nullable!VectorF3();
}

unittest {
    version(D_SIMD) {
        writeln("SIMD works!");
    }
}