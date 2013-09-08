module math.reduce_points;

import math.geometry: Vector2D;
import map.map: getMercatorCoords, map_coords;

import std.math;


private
real parallelSqr( V )( in V v1, in V v2 )
{
    auto angle = v1.angleBetweenVector( v2 );
    
    return v1.length * v2.length * sin( angle );
}

private
real normalLength( V )( in V vector, in V point_coords )
{
    auto vector_length = vector.length;
    
    if( vector_length )
    {
        auto square = abs( parallelSqr( vector, point_coords ) );
        
        return square / vector.length;
    }
    else
        return point_coords.length;
}
unittest
{
    auto vector = Vector2D!long( 4, 0 );
    auto point = Vector2D!long( 6, -6 );
    
    auto normal_length = normalLength( vector, point );
    
    assert( normal_length == 6 );
}

T[] reduce( T, Scalar )( T[] points, Scalar epsilon )
in
{
    assert( points.length >= 2 );
    assert( epsilon > 0 );
}
body
{
    size_t key;
    real biggest_length = 0;
    size_t crop_idx;
    
    for( size_t i = 1; i < points.length - 1; i++ )
    {
        // TODO: remove this
        static if( __traits( compiles, points[0].getCoords ) )
        {
            auto vector = points[$-1].getCoords.map_coords.getMercatorCoords - points[0].getCoords.map_coords.getMercatorCoords;
            auto point = points[i].getCoords.map_coords.getMercatorCoords - points[0].getCoords.map_coords.getMercatorCoords;
        }
        else
        {
            auto vector = points[$-1] - points[0];
            auto point = points[i] - points[0];
        }
        
        auto length = normalLength( vector, point );
        
        if( length > biggest_length )
        {
            key = i;
            biggest_length = length;
        }
    }
    
    T[] res;
    
    if( biggest_length > epsilon )
    {
        auto r1 = reduce( points[ 0..key+1 ], epsilon );
        auto r2 = reduce( points[ key..$ ], epsilon );
        
        res ~= r1[ 0..$-1 ] ~ r2;
    }
    else
    {
        res ~= points[0];
        res ~= points[$-1];
    }
    
    return res;
}
unittest
{
    alias Vector2D!long Coords;
    
    Coords[] points = [
            Coords(4, 1),
            Coords(3, 1),
            Coords(2, 3),
            Coords(1, 2),
            Coords(0, 1),
            Coords(-1, 1)
        ];
    
    Coords[] result = reduce( points, 1.5 );
    
    assert( result == [ Coords(4, 1), Coords(2, 3), Coords(-1, 1) ] );
}
