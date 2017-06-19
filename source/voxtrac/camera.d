module voxtrac.camera;

import std.stdio;
import voxtrac.math;

struct Camera {
    enum Mode {
        Free,
        LookAt
    }

    Mode mode;
    VectorF3 pos, dir;    
    VectorF3 lookAt;    

    static Camera fromLookAt(VectorF3 pos, VectorF3 lookAt) {
         return Camera(Mode.LookAt, pos, (lookAt - pos).normalized(), lookAt);
    }

    void rotateAroundLookAt(float amount, VectorF3 up = VectorF3(0,0,1)) {
        VectorF3 rotDir = VectorF3.cross(up, dir);
        
        float oldDist = (lookAt - pos).norm();        
        pos += rotDir * amount;
        dir = (lookAt - pos).normalized();
        float newDist = (lookAt - pos).norm();
        pos += dir * (newDist - oldDist);
    }

    Ray getRay() {
        return Ray(pos, dir);
    }
}

unittest {
    // auto cam = Camera.fromLookAt(VectorF3(1,1,1), VectorF3(0.1,0.2,0.3));

    // foreach(i; 0..100) {
    //     cam.rotateAroundLookAt(0.05);
    //     writefln("%s %s %s", cam.pos, cam.dir, (cam.lookAt - cam.pos).norm());
    // }    
}