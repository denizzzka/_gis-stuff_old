module math.geometry;

import std.algorithm;
import std.math;


struct Vector2D( _T )
{
    alias _T T;
    
    T x = 0;
    T y = 0;
    
    alias x lon;
    alias y lat;
    
    Vector2D!T opBinary( string op )( in Vector2D!T v ) const
    {
        static if( op == "+" )
            return Vector2D!float( x + v.x, y + v.y );
        else static if( op == "-" )
            return Vector2D!float( x - v.x, y - v.y );
        else
            static assert( false, "op not found" );
    }
    
    void opOpAssign( string op, R )( in Vector2D!R v )
    {
        static if( op == "+" )
            x += v.x, y += v.y;
        else static if( op == "-" )
            x -= v.x, y -= v.y;
        else
            static assert( false, "op not found" );
    }
    
    auto length()
    {
        return hypot( x, y );
    }
}

unittest
{
    Vector2D!float a = { x: 3, y: 2 };
    Vector2D!float b = { x: -2, y: 2 };
    
    auto c = a - b;
    a -= b;
    
    assert( c == a );
    assert( a.length() == 5 );
}


struct Box( _Vector, string S = "size" )
{
    alias _Vector Vector;
    
    Vector leftDownCorner;
    Vector rightUpCorner;
    
    alias leftDownCorner ld;
    alias rightUpCorner ru;
    
    this( in Vector coords, in Vector size )
    {
        static if( S == "size" )
        {
            leftDownCorner.x = coords.x + ((size.x > 0) ? 0 : size.x);
            leftDownCorner.y = coords.y + ((size.y > 0) ? 0 : size.y);
            rightUpCorner.x = coords.x + ((size.x < 0) ? 0 : size.x);
            rightUpCorner.y = coords.y + ((size.y < 0) ? 0 : size.y);
        }
        else // corners
        {
            leftDownCorner = coords;
            rightUpCorner = size;
        }
    }
    
    bool isOverlappedBy( in Box!Vector b ) const pure
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
        alias Vector2D!float Vector2;
        alias Box!Vector2 BBox;
        
        BBox b1 = BBox( Vector2(2, 2), Vector2(1, 1) );
        BBox b2 = BBox( Vector2(3, 3), Vector2(1, 1) );
        BBox b3 = BBox( Vector2(4, 4), Vector2(1, 1) );
        
        assert( b1.isOverlappedBy( b2 ) );
        assert( !b1.isOverlappedBy( b3 ) );
    }
    
    Vector getSizeVector() const
    {
        return Vector( ru.x - ld.x, ru.y - ld.y );
    }
    
    auto getArea() const
    {
        auto size = getSizeVector();
        return size.x * size.y;
    }
    
    Box!Vector getCircumscribed( in Box!Vector b ) const pure
    {
        Box!Vector res;
        
        res.ld.x = min( ld.x, b.ld.x );
        res.ld.y = min( ld.y, b.ld.y );
        
        res.ru.x = max( ru.x, b.ru.x );
        res.ru.y = max( ru.y, b.ru.y );
        
        return res;
    }
    
    void addCircumscribe( in Box!Vector b ) pure
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
    Vector2D!float coords1 = { 0, 0 };
    Vector2D!float size1 = { 1, 1 };
    
    Vector2D!float coords2 = { 1, 0 };
    Vector2D!float size2 = { 1, 1 };
    
    alias Box!(Vector2D!float) BBox;
    
    BBox box1 = BBox( coords1, size1 );
    BBox box2 = BBox( coords2, size2 );
    
    assert( box1.isOverlappedBy( box2 ) );
    
    assert( box1.getCircumscribed( box2 ) == BBox(Vector2D!float(0, 0), Vector2D!float(2, 1)) );
    
    auto serialized = &(box1.Serialize())[0];
    auto size = box2.Deserialize( serialized );
    
    assert( size == box1.sizeof );
    assert( box2 == box1 );
}
