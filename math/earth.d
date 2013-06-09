import std.math;

auto radian2degree( T )( T r )
{
    return r % 360.0 / 180 * PI;
}
unittest
{
    assert( radian2degree(0) == 0 );
    assert( radian2degree(45) == PI_4 );
    assert( radian2degree(360) == 0 );
}

/*
static struct WGS84
{
    
    
    static
*/
