import std.stdio;
import core.memory;

mixin template Freelist() {
private:
    alias T = typeof(this);    

    static T freelistRoot;
    T freelistNext;

public:
    static T create() {
        if(freelistRoot is null) {           
            T x = new T();           
            x.init();
            return x;
        } 
        else {
            T x = freelistRoot;
            x.init();
            freelistRoot = freelistRoot.freelistNext;
            return x;
        }
    }

    void destr() {
        freelistNext = freelistRoot;
        freelistRoot = this;
    }
}

class A {
    mixin Freelist;

    int[10000] payload = void;

    void init() {
        payload = 0;
    }
}

// unittest {
//     GC.collect();
//     GC.disable();

//     size_t usedLast = GC.stats().usedSize;
//     foreach(i; 0..10) {
//         A a = A.create();
//         a.destr();
//         writeln(GC.stats().usedSize - usedLast);
//     }      
    

//     GC.enable();
//     GC.collect();

//     writeln(GC.stats());
// }