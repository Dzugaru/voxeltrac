module voxtrac.math;

import std.string;
import std.stdio;
import std.math;

struct Point3D(T) {
    T x, y, z;

    string toString() const {
        return format("(%s,%s,%s)", x, y, z);
    }

    typeof(this) opBinary(string op)(typeof(this) rhs) if (op == "+" || op == "-") {
        return Point3D(mixin("this.x " ~ op ~ " rhs.x"),
                mixin("this.y " ~ op ~ " rhs.y"), mixin("this.z " ~ op ~ " rhs.z"));
    }

}

struct Rect3D(T) {
    T x0, y0, z0;
    T x1, y1, z1;

    bool isIn(Point3D!T p) const {
        return p.x >= x0 && p.x < x1 && p.y >= y0 && p.y < y1 && p.z >= z0 && p.z < z1;
    }

    T volume() const {
        return (x1 - x0) * (y1 - y0) * (z1 - z0);
    }

    string toString() const {
        return format("(%s,%s,%s,%s,%s,%s)", x0, y0, z0, x1, y1, z1);
    }
}

alias RectI3D = Rect3D!int;
alias PointI3D = Point3D!int;

struct Vector3(T) {
    private alias VT = typeof(this);

    T x, y, z;

    string toString() const {
        return format("(%s,%s,%s)", x, y, z);
    }

    VT opBinary(string op)(VT rhs) if (op == "+" || op == "-") {
        return VT(mixin("x " ~ op ~ " rhs.x"), mixin("y " ~ op ~ " rhs.y"),
                mixin("z " ~ op ~ " rhs.z"));
    }

    ref VT opOpAssign(string op)(VT rhs) if (op == "+" || op == "-") {            
        mixin("x " ~ op ~ "= rhs.x;");
        mixin("y " ~ op ~ "= rhs.y;");
        mixin("z " ~ op ~ "= rhs.z;");

        return this;
    }

    VT opBinary(string op, R)(R rhs) if (op == "*" || op == "/") {
        return VT(mixin("x " ~ op ~ " rhs"), mixin("y " ~ op ~ " rhs"),
                mixin("z " ~ op ~ " rhs"));
    }

    VT opBinaryRight(string op, R)(R lhs) if (op == "*") {
        return VT(x * lhs, y * lhs, z * lhs);
    }

    static VT cross(VT a, VT b) {
        return VT(a.y * b.z - a.z * b.y, 
                  a.z * b.x - a.x * b.z,
                  a.x * b.y - a.y * b.x);
    }

    T norm() {
        return sqrt(x ^^ 2 + y ^^ 2 + z ^^ 2);
    }

    VT normalized() {
        return this / norm();
    }
}

alias VectorF3 = Vector3!float;

struct Ray {
public:
    VectorF3 orig, dir;

    this(float x0, float y0, float z0, float dx, float dy, float dz) {
        orig = VectorF3(x0, y0, z0);
        dir = VectorF3(dx, dy, dz);
    }

    this(VectorF3 orig, VectorF3 dir) {
        this.orig = orig;
        this.dir = dir;
    }
}

unittest {
    VectorF3 v = VectorF3(1, 2, 3);

    //writeln(v * 3.0);
    // writeln(v / 2.0);
    // writeln(3.0 * v);
}
