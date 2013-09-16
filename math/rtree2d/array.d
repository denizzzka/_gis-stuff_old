module math.rtree2d.array;

import math.rtree2d.ptrs;
import math.geometry;
import protobuf.runtime;

debug import std.stdio;


class RTreeArray( RTreePtrs )
{
    alias RTreePtrs.Payload Payload;
    alias RTreePtrs.Box Box;
    
    private ubyte[] storage;
    private ubyte depth = 0;
    
    this( RTreePtrs source )
    in
    {
        size_t nodes, leafs, leafsBlocks;
        source.statistic( nodes, leafs, leafsBlocks );
        
        assert( leafs > 0 );
    }
    body
    {
        depth = source.depth;
        
        storage = fillFrom( source.root );
    }
    
    Payload[] search( in Box boundary, size_t place = 0, in size_t currDepth = 0 )
    {
        Payload[] res;
        
        size_t items_num;
        place += unpackVarint( &storage[place], items_num );
        
        if( currDepth >= depth ) // returning leafs
        {
            for( auto i = 0; i < items_num; i++ )
            {
                Payload o;
                auto offset = o.decompress( &storage[place] );
                
                assert( offset > 0 );
                
                place += offset;
                res ~= o;
            }
        }
        else // searching in nodes
        {
            Box box;
            
            for( auto i = 0; i < items_num; i++ )
            {
                size_t child;
                
                place += box.Deserialize( &storage[place] );
                place += unpackVarint( &storage[place], child );
                
                if( box.isOverlappedBy( boundary ) )
                    res ~= search( boundary, place + child, currDepth+1 );
            }
        }
        
        return res;
    }
        
private:
    
    ubyte[] fillFrom( RTreePtrs!(Box, Payload).Node* curr, size_t currDepth = 0 )
    {
        ubyte[] res = packVarint( curr.children.length ); // number of items
        
        if( currDepth >= depth ) // adding leafs
        {
            foreach( c; curr.children )
                res ~= c.payload.compress;
        }
        else // adding node
        {
            auto offsets = new size_t[ curr.children.length ];
            ubyte[] nodes;
            
            foreach( i, c; curr.children )
            {
                offsets[i] = nodes.length;
                nodes ~= fillFrom( c, currDepth+1 );
            }
            
            ubyte[] boundaries;
            
            foreach_reverse( i, c; curr.children )
            {
                auto s = c.boundary.Serialize();
                s ~= packVarint( offsets[i] + boundaries.length );
                boundaries = s ~ boundaries;
            }
            
            res ~= boundaries ~ nodes;
        }
        
        return res;
    }
}


version(unittest)
{
    struct DumbPayload
    {
        char[32] data;
        
        float* x;
        float* y;
        
        ubyte[] compress() const /// TODO: real serialization
        {
            ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
            return res;
        }
        
        size_t decompress( ubyte* data ) /// TODO: real serialization
        {
            (cast (ubyte*) &this)[ 0 .. this.sizeof] = data[ 0 .. this.sizeof ].dup;
            
            return this.sizeof;
        }
        
        this( float x, float y )
        {
            this.x = cast(float*) &data[0];
            this.y = cast(float*) &data[16];
            
            *this.x = x;
            *this.y = y;
        }
        
        string toString()
        {
            return "x=" ~ to!string( *x ) ~ " y=" ~ to!string( *y );
        }
    }
    unittest
    {
        DumbPayload a;
        DumbPayload b;
        
        auto serialized = &(a.compress())[0];
        auto size = b.decompress( serialized );
        
        assert( size == a.sizeof );
        assert( a == b );
    }
}


unittest
{
    import std.string;
    
    alias Vector2D!float Vector;
    alias Box!Vector BBox;
    
    auto rtree = new RTreePtrs!(BBox, DumbPayload)( 2, 2 );
    
    for( float y = 1; y < 4; y++ )
        for( float x = 1; x < 4; x++ )
        {
            DumbPayload payload = DumbPayload( x, y );
            BBox boundary = BBox( Vector( x, y ), Vector( 1, 1 ) );
            
            rtree.addObject( boundary, payload );
        }
    
    auto rarr = new RTreeArray!(typeof(rtree))( rtree );
    
    // search request and test answers is from ptrs unittest
    BBox search1 = BBox( Vector( 2, 2 ), Vector( 1, 1 ) );
    BBox search2 = BBox( Vector( 2.1, 2.1 ), Vector( 0.8, 0.8 ) );
    
    auto res2 = rarr.search( search2 );
    
    writeln( rarr.search( search2 ) );
    
    assert( rarr.search( search1 ).length == 9 );
    assert( rarr.search( search2 ).length == 1 );
}
