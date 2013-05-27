module rtree2d;

import protobuf;

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
        
        auto ld2 = b.leftDownCorner;
        auto ru2 = b.rightUpCorner;
        
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
    
    Vector2D coords2 = { 1, 0 };
    Vector2D size2 = { 1, 1 };
    
    Box box1 = Box( coords1, size1 );
    Box box2 = Box( coords2, size2 );
    
    assert( box1.isOverlappedBy( box2 ) );
}

struct RTreePayload
{
    Vector2D coords;
    Vector2D value;
    
    Box getBound()
    {
        return Box( coords, value );
    }
}

struct RTree
{
    ubyte depth = 0;
    ubyte[] data;
    
    static struct Node
    {
        Box bound;
        ubyte childOffset;
    }
    
    static struct Leaf
    {
        RTreePayload payload;
    }
    
    void addObject( RTreePayload o )
    {
    }
}

unittest
{
    RTree rtree;
    
    for( float y = 0; y < 10; y++ )
        for( float x = 0; x < 10; x++ )
        {
            RTreePayload p;
            p.coords = Vector2D( x, y );
            p.value = Vector2D( 1, 1 );
            
            //rtree.addObject( 
        }
}
