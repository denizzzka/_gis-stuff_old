module math.rtree2d.array;

import math.rtree2d.ptrs;
import math.geometry;
import protobuf.runtime: packVarint, unpackVarint;
import compression.geometry;

debug import std.stdio;


class RTreeArray( RTreePtrs )
{
    alias RTreePtrs.Payload Payload;
    alias RTreePtrs.Box Box;
    
    private ubyte[] storage;
    private ubyte depth = 0;
    
    this( inout RTreePtrs source )
    {
        if( source.root.children.length )
        {
            depth = source.depth;
            
            storage = source.root.boundary.compress;
            storage ~= fillNode( source.root );
        }
        
        debug(rtreearray) writeln("RTreeArray created, size ", storage.length, " bytes" );
    }
    
    Payload[] search( in Box boundary ) const
    {
        Payload[] res;
        
        if( storage.length )
        {
            Box delta;
            
            size_t place = delta.decompress( &storage[0] );
            res = search( boundary, delta, place, 0 );
        }
        
        debug(rtreearray) writeln("Found ", res.length, " items" );
        
        return res;
    }
    
    private
    Payload[] search( inout Box boundary, inout Box delta2, size_t place, in size_t currDepth ) const
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
                
                place += box.decompress( &storage[place] );
                //box = box.getCornersSum( delta );
                place += unpackVarint( &storage[place], child_offset );
                
                if( box.isOverlappedBy( boundary ) )
                    res ~= search( boundary, box, place + child_offset, currDepth+1 );
            }
        }
        
        return res;
    }
    
    private
    ubyte[] fillNode( inout RTreePtrs!(Box, Payload).Node* curr, size_t currDepth = 0 )
    in
    {
        assert( curr.children.length );
    }
    body
    {
        ubyte[] res = packVarint( curr.children.length ); // number of items
        
        if( currDepth >= depth ) // adding leafs
            foreach( c; curr.children )
                res ~= (*c.payload).compress;
        
        else // adding nodes
        {
            auto offsets = new size_t[ curr.children.length ];
            ubyte[] nodes;
            
            foreach( i, c; curr.children )
            {
                offsets[i] = nodes.length;
                nodes ~= fillNode( c, currDepth+1 );
            }
            
            ubyte[] boundaries;
            
            foreach_reverse( i, c; curr.children )
            {
                auto boundary = c.boundary; //.getCornersDiff( curr.boundary );
                auto s = boundary.compress;
                s ~= packVarint( offsets[i] + boundaries.length );
                boundaries = s ~ boundaries;
            }
            
            res ~= boundaries ~ nodes;
        }
        
        return res;
    }
}

unittest
{
    import std.string;
    
    alias Vector2D!long Vector;
    alias Box!Vector BBox;
    
    auto rtree = new RTreePtrs!(BBox, Vector)( 2, 2 );
    
    for( long y = -10; y < 10; y++ )
        for( long x = -10; x < 10; x++ )
        {
            auto payload = Vector( x, y );
            BBox boundary = BBox( Vector( x, y ), Vector( 1, 1 ) );
            
            rtree.addObject( boundary, payload );
        }
    
    auto rarr = new RTreeArray!(typeof(rtree))( rtree );
    
    // search request and test answers is from ptrs unittest
    BBox search1 = BBox( Vector( 2, 2 ), Vector( 1, 1 ) );
    
    assert( rarr.search( search1 ).length >= 9 );
}
