module math.geometry;

import std.algorithm;
import std.math;
import std.conv: to;
import std.traits: isScalarType;


struct Vector2D( _T, string name = "noname" )
{
    alias _T T;
    
    T x = 0;
    T y = 0;
    
    alias x lon;
    alias y lat;
    
    this( T1, T2 )( inout T1 x, inout T2 y )
    //if( isScalarType!(T1) && isScalarType!(T2) ) // FIXME
    {
        this.x = x;
        this.y = y;
    }
    
    this( V )( in V v )
    if( !isScalarType!(V) )
    {
        this.x = v.x;
        this.y = v.y;
    }
    
    auto length() const
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
    if( isScalarType!(T) )
    {
        Vector2D res = this;
        
        static if( op == "*" )
            res *= v;
        else static if( op == "/" )
            res /= v;
        else
            static assert( false, "op \""~op~"\" is not found" );
            
        return res;
    }
    
    Vector2D opBinary( string op, T )( in T v ) const
    if( !isScalarType!(T) )
    {
        Vector2D res = this;
        
        static if( op == "+" )
            res += v;
        else static if( op == "-" )
            res -= v;
        else
            static assert( false, "op \""~op~"\" is not found" );
            
        return res;
    }
    
    void opOpAssign( string op, T )( in T v )
    if( isScalarType!(T) )
    {
        static if( op == "*" )
            x *= v, y *= v;
        else static if( op == "/" )
            x /= v, y /= v;
        else
            static assert( false, "op \""~op~"\" is not found" );
    }
    
    void opOpAssign( string op, T )( in T v )
    if( !isScalarType!(T) )
    {
        static if( op == "+" )
            x += v.x, y += v.y;
        else static if( op == "-" )
            x -= v.x, y -= v.y;
        else
            static assert( false, "op \""~op~"\" is not found" );
    }
    
    void opAssign(T)( in T v )
    if( !isScalarType!(T) )
    {
        x = v.x;
        y = v.y;
    }
    
    Vector2D!long lround() const
    {
        Vector2D!long r;
        
        r.x = std.math.lround(x);
        r.y = std.math.lround(y);
        
        return r;
    }
    
    Vector2D!T roundToLeftDown( T )() const
    {
        Vector2D!T r;
        
        r.x = cast(T) floor(x);
        r.y = cast(T) floor(y);
        
        return r;
    }
    
    Vector2D!T roundToRightUpper( T )() const
    {
        Vector2D!T r;
        
        r.x = cast(T) ceil(x);
        r.y = cast(T) ceil(y);
        
        return r;
    }
        
    string toString() const
    {
        return "("~to!string(x)~";"~to!string(y)~")";
    }
    
    Vector2D!real toReal() const
    {
        return Vector2D!real( x, y );
    }
    
    Vector2D!double roundToDouble() const
    {
        return Vector2D!double( to!double( x ), to!double( y ) );
    }
    
    /// Angle between OX and vector
    real angleOX() const
    {
        return atan2( to!real( x ), to!real( y ) );
    }
    
    real angleBetweenVector( V )( in V v ) const
    {
        return angleOX() - v.angleOX();
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
    Vector rightUpperCorner;
    
    alias leftDownCorner ld;
    alias rightUpperCorner ru;
    alias getLeftUpperCorner lu;
    alias getRightDownCorner rd;
    
    this( inout Vector coords, inout Vector size )
    {
        static if( S == "size" )
        {
            leftDownCorner.x = coords.x + ((size.x > 0) ? 0 : size.x);
            leftDownCorner.y = coords.y + ((size.y > 0) ? 0 : size.y);
            rightUpperCorner.x = coords.x + ((size.x < 0) ? 0 : size.x);
            rightUpperCorner.y = coords.y + ((size.y < 0) ? 0 : size.y);
        }
        else // corners
        {
            leftDownCorner = coords;
            rightUpCorner = size;
        }
    }
    
    Vector getLeftUpperCorner() const
    {
        return Vector( ld.x, ru.y );
    }
    
    Vector getRightDownCorner() const
    {
        return Vector( ru.x, ld.y );
    }
    
    bool isOverlappedBy( in Box!Vector b ) const pure
    {
        auto ld2 = b.leftDownCorner;
        auto ru2 = b.rightUpperCorner;
        
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
        return ru - ld;
    }
    
    Vector getCenter() const
    {
        return ld + getSizeVector() / 2;
    }
    
    auto getArea() const
    {
        auto size = getSizeVector();
        return size.x * size.y;
    }
    
    Box getCircumscribed( in Vector v ) const pure
    {
        Box res;
        
        res.ld.x = min( ld.x, v.x );
        res.ld.y = min( ld.y, v.y );
        
        res.ru.x = max( ru.x, v.x );
        res.ru.y = max( ru.y, v.y );
        
        return res;
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
    
    void addCircumscribe(T)( in T v )
    {
        this = this.getCircumscribed( v );
    }
    
    Box getCornersSum( inout Box v ) const
    {
        Box res;
        
        res.leftDownCorner = leftDownCorner + v.leftDownCorner;
        res.rightUpperCorner = rightUpperCorner + v.rightUpperCorner;
        
        return res;
    }
    
    Box getCornersDiff( inout Box v ) const
    {
        Box res;
        
        res.leftDownCorner = leftDownCorner - v.leftDownCorner;
        res.rightUpperCorner = rightUpperCorner - v.rightUpperCorner;
        
        return res;
    }
}

unittest
{
    //Box!(Vector2D!(short)) SBox; // FIXME: causes bug in opBinary("-");
    alias Vector2D!float Vector;
    
    auto coords1 = Vector( 0, 0 );
    auto size1 = Vector( 1, 1 );
    
    auto coords2 = Vector( 1, 0 );
    auto size2 = Vector( 1, 1 );
    
    alias Box!(Vector) BBox;
    
    BBox box1 = BBox( coords1, size1 );
    BBox box2 = BBox( coords2, size2 );
    
    assert( box1.isOverlappedBy( box2 ) );
    
    assert( box2.getCircumscribed( Vector(3,3) ) == BBox(Vector(1, 0), Vector(2, 3)) );
    assert( box1.getCircumscribed( box2 ) == BBox(Vector(0, 0), Vector(2, 1)) );
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

auto radians2degrees(T)( in T from ) pure
{
    Vector2D!real res;
    
    res.lon = radian2degree( from.lon );
    res.lat = radian2degree( from.lat );
    
    return res;
}
