module compression.compressed;

class Compressed( T, size_t keyInterval )
{
}

unittest
{
    alias Compressed!( float, 3 ) C;
}
