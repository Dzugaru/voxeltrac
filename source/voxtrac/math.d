module voxtrac.math;

import std.string;

struct Vector3(T) {
    T x, y, z;

    string toString() const {
        return format("(%s,%s,%s)", x, y, z);
    }

    typeof(this) opBinary(string op)(typeof(this) rhs) if (op == "+" || op == "-") {
        return Vector3!T(mixin("this.x " ~ op ~ " rhs.x"),
                mixin("this.y " ~ op ~ " rhs.y"), mixin("this.z " ~ op ~ " rhs.z"));
    }
}

alias VectorF3 = Vector3!float;

@nogc testNoGC() {
    
}

unittest {
    VectorF3 v = VectorF3(1, 2, 3);

    testNoGC();
}
