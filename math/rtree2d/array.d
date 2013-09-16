module math.rtree2d.array;

import math.rtree2d.ptrs;
import math.geometry: Box;
import protobuf.runtime;

debug import std.stdio;


class RTreeArray( RTreePtrs )
{
    alias RTreePtrs.Payload Payload;
    alias RTreePtrs.Box Box;
    
    private ubyte[] storage;
    private ubyte depth = 0;
    
    this( inout RTreePtrs source )
    in
    {
        size_t nodes, leafs, leafsBlocks;
        source.statistic( nodes, leafs, leafsBlocks );
        
        assert( leafs > 0 );
    }
    body
    {
        depth = source.depth;
        
        storage = fillFrom( source.root, source.root.boundary );
    }
    
    Payload[] search( in Box boundary, size_t place = 0, in size_t currDepth = 0 ) const
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
            for( auto i = 0; i < items_num; i++ )
            {
                Box box;
                size_t child_offset;
                
                place += box.Deserialize( &storage[place] );
                place += unpackVarint( &storage[place], child_offset );
                
                if( box.isOverlappedBy( boundary ) )
                    res ~= search( boundary, place + child_offset, currDepth+1 );
            }
        }
        
        return res;
    }
    
    private
    ubyte[] fillFrom(
            inout RTreePtrs!(Box, Payload).Node* curr,
            inout Box delta,
            size_t currDepth = 0 )
    {
        ubyte[] res = packVarint( curr.children.length ); // number of items
        
        if( currDepth >= depth ) // adding leafs
            foreach( c; curr.children )
                res ~= c.payload.compress;
        
        else // adding nodes
        {
            auto offsets = new size_t[ curr.children.length ];
            ubyte[] nodes;
            
            foreach( i, c; curr.children )
            {
                offsets[i] = nodes.length;
                nodes ~= fillFrom( c, delta, currDepth+1 );
            }
            
            ubyte[] boundaries;
            
            foreach_reverse( i, c; curr.children )
            {
                auto boundary = c.boundary.getCornersDifference( delta );
                auto s = boundary.Serialize();
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
    import math.geometry;
    
    alias Vector2D!float Vector2f;
    
    struct DumbPayload
    {
        Vector2f data;
        alias data this;
        
        ubyte[] compress() const
        {
            ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
            return res;
        }
        
        size_t decompress( inout ubyte* storage )
        {
            (cast (ubyte*) &this)[ 0 .. this.sizeof] = storage[ 0 .. this.sizeof ].dup;
            
            return this.sizeof;
        }
        
        this( float x, float y )
        {
            data.x = x;
            data.y = y;
        }
        
        string toString()
        {
            return data.toString;
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
            auto payload = DumbPayload( x, y );
            BBox boundary = BBox( Vector( x, y ), Vector( 1, 1 ) );
            
            rtree.addObject( boundary, payload );
        }
    
    auto rarr = new RTreeArray!(typeof(rtree))( rtree );
    
    // search request and test answers is from ptrs unittest
    BBox search1 = BBox( Vector( 2, 2 ), Vector( 1, 1 ) );
    BBox search2 = BBox( Vector( 2.1, 2.1 ), Vector( 0.8, 0.8 ) );
    
    assert( rarr.search( search1 ).length == 9 );
    assert( rarr.search( search2 ).length == 2 );
}
