module rtree2d;

import std.stdio;

struct Vector2D
{
    float[2] axis;
    
    @property
    ref float x(){ return axis[0]; }

    @property 
    ref float y(){ return axis[1]; }
    
    alias x lon;
    alias y lat;
}

struct Box
{
    Vector2D coords;
    Vector2D size;
    
    private float boundary( size_t coordNum, bool itIsLeftDown )
    {
        return ( size.axis[coordNum] > 0 ) == itIsLeftDown ?
        
            coords.axis[coordNum] :
            coords.axis[coordNum] + size.axis[coordNum];
    }
    
    @property
    Vector2D leftDownCorner()
    {
        Vector2D res = { axis: [ boundary(0, true), boundary(1, true) ] };            
        return res;
    }
    
    @property
    Vector2D rightUpCorner()
    {
        Vector2D res = { axis: [ boundary(0, false), boundary(1, false) ] };            
        return res;
    }
    
    
    bool isOverlapped( Box b )
    {
        auto ld1 = leftDownCorner();
        auto ru2 = b.rightUpCorner();
        
        if( ld1.x > ru2.x || ld1.y > ru2.y ) return false;
        
        auto ru1 = rightUpCorner();
        auto ld2 = b.leftDownCorner();
        
        if( ld2.x > ru1.x || ld2.y > ru1.y ) return false;
        
        return true;
    }
}
unittest
{
    Vector2D coords1 = { axis: [ 0, 0 ] };
    Vector2D size1 = { axis: [ 1, 1 ] };
    
    Vector2D coords2 = { axis: [ 2, 1 ] };
    Vector2D size2 = { axis: [ -1, 1 ] };
    
    Box box1 = { coords: coords1, size: size1 };
    
    Box box2 = { coords: coords2, size: size2 };
    
    assert( box1.isOverlapped( box2 ) );
    
    writeln( box1, box2, box1.isOverlapped( box2 ) );
}
