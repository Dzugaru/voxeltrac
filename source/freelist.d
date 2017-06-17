import std.stdio;

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

    void init() {

    }
}