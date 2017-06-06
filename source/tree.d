module voxtrac.tree;

import std.stdio;
import std.string;
import std.conv;
import std.array;
import std.range;

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

class Tree(T) {
    static class Node {
    public:
        RectI3D volume;
    }

    static class Leaf : Node {
    public:
        T val;

        this(RectI3D vol, T val) {
            this.volume = vol;
            this.val = val;
        }

        override string toString() const {
            return "L" ~ to!string(volume) ~ " " ~ to!string(val);
        }
    }

    static class Branch : Node {
    public:
        int nbranches;
        Node[8] branches;

        override string toString() const {
            return "B" ~ to!string(volume) ~ " N: " ~ to!string(nbranches);
        }

        string toStringRec(int tab = 0) {
            auto s = appender!string();
            s.put('\t'.repeat(tab));
            s.put("B");
            s.put(volume.toString);
            s.put("(\n");
            foreach (i, n; branches) {
                if (n is null)
                    continue;

                Branch bn = cast(Branch) n;
                s.put('\t'.repeat(tab));
                if (bn !is null)
                    s.put(bn.toStringRec(tab + 1));
                else
                    s.put("\t" ~ n.toString);

                s.put("\n");
            }
            s.put('\t'.repeat(tab));
            s.put(")");
            return s.data;
        }
    }

    Branch root;

    public {
        int nodeCount;
        RectI3D volume;
        T defVal;
    }

    static PointI3D split(RectI3D vol) {
        int x0 = vol.x0 + ((vol.x1 - vol.x0) >> 1);
        int y0 = vol.y0 + ((vol.y1 - vol.y0) >> 1);
        int z0 = vol.z0 + ((vol.z1 - vol.z0) >> 1);
        return PointI3D(x0, y0, z0);
    }

    static int getPart(PointI3D p, RectI3D vol) {
        PointI3D s = split(vol);
        int xb = p.x < s.x ? 1 : 0;
        int yb = p.y < s.y ? 1 : 0;
        int zb = p.z < s.z ? 1 : 0;
        return (zb << 2) | (yb << 1) | xb;
    }

    Branch createBranch(RectI3D vol, T val) {
        Branch b = new Branch();
        b.volume = vol;
        PointI3D s = split(vol);

        for (size_t i = 0; i < 8; ++i) {
            int xb = i & 1;
            int yb = (i >> 1) & 1;
            int zb = (i >> 2) & 1;

            RectI3D sv;
            if (xb == 1) {
                sv.x0 = vol.x0;
                sv.x1 = s.x;
            }
            else {
                sv.x0 = s.x;
                sv.x1 = vol.x1;
            }

            if (yb == 1) {
                sv.y0 = vol.y0;
                sv.y1 = s.y;
            }
            else {
                sv.y0 = s.y;
                sv.y1 = vol.y1;
            }

            if (zb == 1) {
                sv.z0 = vol.z0;
                sv.z1 = s.z;
            }
            else {
                sv.z0 = s.z;
                sv.z1 = vol.z1;
            }

            if (sv.volume > 0) {
                b.branches[i] = new Leaf(sv, val);
                ++b.nbranches;
            }
        }

        nodeCount += b.nbranches;
        return b;
    }

    public this(RectI3D vol, T val) {
        this.volume = vol;
        this.defVal = val;
        this.nodeCount = 1;
        this.root = createBranch(vol, defVal);
    }

    T recGet(PointI3D p, const Node n) const {
        Branch bn = cast(Branch) n;

        if (bn is null) {
            return (cast(Leaf) n).val;
        }
        else {
            int i = getPart(p, bn.volume);
            return recGet(p, bn.branches[i]);
        }
    }

    public T get(PointI3D p) const {
        return recGet(p, root);
    }

    bool recSet(PointI3D p, T x, Branch n, Branch prev, int prevIdx) {
        int i = getPart(p, n.volume);

        Node next = n.branches[i];
        Branch bnext = cast(Branch) next;
        bool changed;

        if (bnext is null) { //We're on leaf node
            Leaf lnext = cast(Leaf) next;

            if (lnext.val == x)
                return false; //Leaf value is the same as x, nothing to do here

            if (lnext.volume.volume == 1) { //Smallest possible leaf, just set value to x
                lnext.val = x;
                changed = true;
            }
            else { //Otherwise, convert leaf to branch and repeat
                n.branches[i] = bnext = createBranch(next.volume, lnext.val);
                changed = recSet(p, x, bnext, n, i);
            }
        }
        else { //We're on branch node, just repeat
            changed = recSet(p, x, bnext, n, i);
        }

        if (changed) {
            //Check if all children are now leafs with same value        
            bool same = true;
            foreach (k; 0 .. 8) {
                if (n.branches[k] is null)
                    continue;

                Leaf ln = cast(Leaf) n.branches[k];
                if (ln is null || ln.val != x) {
                    same = false;
                    break;
                }
            }

            //And merge them into one big leaf (if it's not root)
            if (same && (prev !is null)) {
                nodeCount -= n.nbranches;
                prev.branches[prevIdx] = new Leaf(prev.branches[prevIdx].volume, x);
                return true;
            }
        }

        return false;
    }

    public bool set(PointI3D p, T x) {
        return recSet(p, x, root, null, -1);
    }
}

unittest {
    import std.random;

    int maxX = 7;
    int maxY = 9;
    int maxZ = 11;

    //Check read/write correctness using dictionary as ground truth
    auto tree = new Tree!int(RectI3D(0, 0, 0, maxX, maxY, maxZ), 0);
    int[PointI3D] dict;

    auto rng = Random(1);

    auto getRandomP() {
        return PointI3D(uniform(0, maxX, rng), uniform(0, maxY, rng), uniform(0, maxZ, rng));
    }

    for (size_t i = 0; i < 10_000; ++i) {
        //Set random voxel to random value
        auto p = getRandomP();
        int val = uniform(0, 10, rng);

        tree.set(p, val);
        dict[p] = val;

        //Check another random point validity
        auto cp = getRandomP();
        int v = tree.get(cp);
        int ev = cp !in dict ? 0 : dict[cp];
        assert(v == ev);
    }

    //Check node merges
    tree = new Tree!int(RectI3D(0, 0, 0, maxX, maxY, maxZ), 0);

    for (int x = 0; x < maxX; x++) {
        for (int y = 0; y < maxY; y++) {
            for (int z = 0; z < maxZ; z++) {
                tree.set(PointI3D(x, y, z), 1);
            }
        }
    }
    assert(tree.nodeCount == 9);
}
