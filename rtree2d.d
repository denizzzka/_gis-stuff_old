module rtree2d;

import std.stdio;

struct Vector2D
{
    float x;
    float y;
    
    alias x lon;
    alias y lat;
}

struct Box
{
    Vector2D leftDownCorner;
    Vector2D rightUpCorner;
    
    this( ref Vector2D coords, ref Vector2D size )
    {
        leftDownCorner.x = coords.x + ((size.x > 0) ? 0 : size.x);
        leftDownCorner.y = coords.y + ((size.y > 0) ? 0 : size.y);
        rightUpCorner.x = coords.x + ((size.x < 0) ? 0 : size.x);
        rightUpCorner.y = coords.y + ((size.y < 0) ? 0 : size.y);
    }
    
    bool isOverlappedBy( Box b )
    {
        alias leftDownCorner ld1;
        alias rightUpCorner ru1;
        
        alias b.leftDownCorner ld2;
        alias b.rightUpCorner ru2;
        
        auto r1 = ld1.x <= ru2.x;
        auto r2 = ru1.x >= ld2.x;
        auto r3 = ld1.y <= ru2.y;
        auto r4 = ru1.y >= ld2.y;
        
        writeln( ld1.x, " <= ", ru2.x, " = ", r1 );
        writeln( ru1.x, " >= ", ld2.x, " = ", r2 );
        writeln( r1, r2 ,r3, r4 );
        
        return
            ld1.x <= ru2.x &&
            ru1.x >= ld2.x &&
            ld1.y <= ru2.y &&
            ru1.y >= ld2.y;
    }
}

unittest
{
    Vector2D coords1 = { 0, 0 };
    Vector2D size1 = { 1, 1 };
    
    Vector2D coords2 = { 2, 0 };
    Vector2D size2 = { 1, 2 };
    
    Box box1 = Box( coords1, size1 );
    Box box2 = Box( coords2, size2 );
    
    //assert( box1.isOverlappedBy( box2 ) );
    
    writeln( box1 );
    writeln( box2 );
    writeln( box1.isOverlappedBy( box2 ) );
}
