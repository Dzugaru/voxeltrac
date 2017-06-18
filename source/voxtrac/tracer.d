module voxtrac.tracer;

import std.math;
import std.algorithm;
import std.conv;
import std.typecons;
import std.stdio;
import voxtrac.math;
import voxtrac.tree;

struct Ray {
public:
    VectorF3 orig, dir;

    this(float x0, float y0, float z0, float dx, float dy, float dz) {
        orig = VectorF3(x0, y0, z0);
        dir = VectorF3(dx, dy, dz);
    }
}

VectorF3 traceInside(Ray ray, RectI3D vol) {
    float x = ray.dir.x < 0 ? vol.x0 : vol.x1;
    float y = ray.dir.y < 0 ? vol.y0 : vol.y1;
    float z = ray.dir.z < 0 ? vol.z0 : vol.z1;

    float tx = abs((x - ray.orig.x) / ray.dir.x);
    float ty = abs((y - ray.orig.y) / ray.dir.y);
    float tz = abs((z - ray.orig.z) / ray.dir.z);

    float t = min(tx, ty, tz);

    VectorF3 p = ray.orig + ray.dir * t;

    if (t == tx)
        p.x = roundTo!int(p.x);
    else if (t == ty)
        p.y = roundTo!int(p.y);
    else if (t == tz)
        p.z = roundTo!int(p.z);

    return p;
}

Nullable!VectorF3 traceOutside(Ray ray, RectI3D vol) {
    float x = ray.dir.x < 0 ? vol.x1 : vol.x0;
    float y = ray.dir.y < 0 ? vol.y1 : vol.y0;
    float z = ray.dir.z < 0 ? vol.z1 : vol.z0;

    float tx = (x - ray.orig.x) / ray.dir.x;
    float ty = (y - ray.orig.y) / ray.dir.y;
    float tz = (z - ray.orig.z) / ray.dir.z;

    if (tx >= 0) {
        VectorF3 ix = ray.orig + ray.dir * tx;
        if (ix.y >= vol.y0 && ix.y <= vol.y0 && ix.z >= vol.z0 && ix.z <= vol.z1) {
            ix.x = roundTo!int(ix.x);
            return nullable(ix);
        }
    }

    if (ty >= 0) {
        VectorF3 iy = ray.orig + ray.dir * ty;
        if (iy.x >= vol.x0 && iy.x <= vol.x1 && iy.z >= vol.z0 && iy.z <= vol.z1) {
            iy.y = roundTo!int(iy.y);
            return nullable(iy);
        }
    }

    if (tz >= 0) {
        VectorF3 iz = ray.orig + ray.dir * tz;
        if (iz.x >= vol.x0 && iz.x <= vol.x1 && iz.y >= vol.y0 && iz.y <= vol.y1) {
            iz.z = roundTo!int(iz.z);
            return nullable(iz);
        }
    }

    return Nullable!VectorF3();
}

// PointI3D RayStepIntoVoxel(VectorF3 orig, VectorF3 dir)
//     {
//         Point3D p = new Point3D((int)orig.x, (int)orig.y, (int)orig.z);

//         if (orig.x == p.X && dir.x < 0) p.X--;
//         if (orig.y == p.Y && dir.y < 0) p.Y--;
//         if (orig.z == p.Z && dir.z < 0) p.Z--;
//         return p;
//     }

unittest {
    writeln(traceOutside(Ray(0,0,2,0.9,0.1,-1), RectI3D(0,0,0,1,1,1)));
}