module math.geometry;

import std.algorithm;


struct Vector2D
{
    float x = 0;
    float y = 0;
    
    alias x lon;
    alias y lat;
}

struct Box
{
    Vector2D leftDownCorner;
    Vector2D rightUpCorner;
    
    alias leftDownCorner ld;
    alias rightUpCorner ru;
    
    this( in Vector2D coords, in Vector2D size )
    {
        leftDownCorner.x = coords.x + ((size.x > 0) ? 0 : size.x);
        leftDownCorner.y = coords.y + ((size.y > 0) ? 0 : size.y);
        rightUpCorner.x = coords.x + ((size.x < 0) ? 0 : size.x);
        rightUpCorner.y = coords.y + ((size.y < 0) ? 0 : size.y);
    }
    
    bool isOverlappedBy( in Box b ) const pure
    {
        auto ld2 = b.leftDownCorner;
        auto ru2 = b.rightUpCorner;
        
        return
            ld.x <= ru2.x &&
            ru.x >= ld2.x &&
            ld.y <= ru2.y &&
            ru.y >= ld2.y;
    }
    unittest
    {
        Box b1 = Box( Vector2D(2, 2), Vector2D(1, 1) );
        Box b2 = Box( Vector2D(3, 3), Vector2D(1, 1) );
        Box b3 = Box( Vector2D(4, 4), Vector2D(1, 1) );
        
        assert( b1.isOverlappedBy( b2 ) );
        assert( !b1.isOverlappedBy( b3 ) );
    }
    
    Vector2D getSizeVector() const
    {
        return Vector2D( ru.x - ld.x, ru.y - ld.y );
    }
    
    auto getArea() const
    {
        auto size = getSizeVector();
        return size.x * size.y;
    }
    
    Box getCircumscribed( in Box b ) const pure
    {
        Box res;
        
        res.ld.x = min( ld.x, b.ld.x );
        res.ld.y = min( ld.y, b.ld.y );
        
        res.ru.x = max( ru.x, b.ru.x );
        res.ru.y = max( ru.y, b.ru.y );
        
        return res;
    }
    
    void addCircumscribe( in Box b ) pure
    {
        this = this.getCircumscribed( b );
    }
    
    ubyte[] Serialize() /// TODO: real serialization
    {
        ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
        return res;
    }
    
    size_t Deserialize( ubyte* data ) /// TODO: real serialization
    {
        (cast (ubyte*) &this)[ 0 .. this.sizeof] = data[ 0 .. this.sizeof ].dup;
        
        return this.sizeof;
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
    
    assert( box1.getCircumscribed( box2 ) == Box(Vector2D(0, 0), Vector2D(2, 1)) );
    
    auto serialized = &(box1.Serialize())[0];
    auto size = box2.Deserialize( serialized );
    
    assert( size == box1.sizeof );
    assert( box2 == box1 );
}
