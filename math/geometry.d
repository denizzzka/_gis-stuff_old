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
    
    this( T x, T y )
    {
        this.x = x;
        this.y = y;
    }
    
    auto length()
    {
        return hypot( x, y );
    }
    
    Vector2D opUnary( string op )() const
    {
        static if( op == "-" )
            return Vector2D( -x, -y );
        else
            static assert( false, "op \""~op~"\" is not found" );
    }
    
    Vector2D opBinary( string op, T )( in T v ) const
    {
        static if( op == "+" )
            return Vector2D( x + v.x, y + v.y );
        else static if( op == "-" )
            return Vector2D( x - v.x, y - v.y );
        else static if( op == "/" )
            return Vector2D( x/v, y/v );
        else
            static assert( false, "op \""~op~"\" is not found" );
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
    
    void opAssign(T)( T v )
    {
        x = v.x;
        y = v.y;
    }
}

unittest
{
    auto a = Vector2D!float( 3, 2 );
    auto b = Vector2D!float( -2, 2 );
    
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
    alias Vector2D!float Vector;
    
    auto coords1 = Vector( 0, 0 );
    auto size1 = Vector( 1, 1 );
    
    auto coords2 = Vector( 1, 0 );
    auto size2 = Vector( 1, 1 );
    
    alias Box!(Vector) BBox;
    
    BBox box1 = BBox( coords1, size1 );
    BBox box2 = BBox( coords2, size2 );
    
    assert( box1.isOverlappedBy( box2 ) );
    
    assert( box1.getCircumscribed( box2 ) == BBox(Vector(0, 0), Vector(2, 1)) );
    
    auto serialized = &(box1.Serialize())[0];
    auto size = box2.Deserialize( serialized );
    
    assert( size == box1.sizeof );
    assert( box2 == box1 );
}

auto degree2radian( T )( in T val ) pure
{
    return val * (PI / 180);
}

unittest
{
    assert( degree2radian(0) == 0 );
    assert( degree2radian(45) == PI_4 );
    assert( degree2radian(360) == PI * 2 );
}

auto radian2degree( T )( in T val ) pure
{
    return val * (180 / PI);
}

unittest
{
    assert( degree2radian(500).radian2degree == 500 );
}

auto degrees2radians(T)( in T from ) pure
{
    Vector2D!real res;
    
    res.lon = degree2radian( from.lon );
    res.lat = degree2radian( from.lat );
    
    return res;
}
