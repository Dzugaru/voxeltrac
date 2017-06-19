module voxtrac.app;

import std.datetime;
import std.random;

import voxtrac.math;
import voxtrac.tracer;
import voxtrac.camera;

struct Color {
    ubyte b,g,r,a;

    this(ubyte r, ubyte g, ubyte b) {
        this.r = r;
        this.g = g;
        this.b = b;
    }
}

struct Canvas {
    Color* pixs;
    immutable int stride;
    immutable int w, h;

    this(Color* pixs, int stride, int w, int h) {
        this.pixs = pixs;
        this.stride = stride;
        this.w = w;
        this.h = h;
    }

    void fillColor(const Color c) {
        foreach(y; 0..h) 
            foreach(x; 0..w) 
                pixs[y*stride + x] = c;
    }

    void fillRandom() {
        foreach(y; 0..h) 
            foreach(x; 0..w) {
                Color* c = &pixs[y*stride + x];
                c.r = cast(ubyte)uniform(0, 256);
                c.g = cast(ubyte)uniform(0, 256);
                c.b = cast(ubyte)uniform(0, 256);
            }                
    }
}

Camera camera = Camera.fromLookAt(VectorF3(5,0,5), VectorF3(0.5,0.5,0.5));

void appStart() {

}

void appLoop(Duration dt) {

}

void appDraw(ref Canvas canv) {
    //Color c = Color(255,255,0);
    //canv.fillRandom();

    auto t = traceOutside(camera.getRay(), RectI3D(0,0,0,1,1,1));
}

