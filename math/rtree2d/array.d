module math.rtree2d.array;

import math.rtree2d.ptrs;
import math.geometry;
import compression.pb_encoding: packVarint, unpackVarint;
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
            
            storage = fillNode( source.root );
        }
        
        debug(rtreearray) writeln("RTreeArray created, size ", storage.length, " bytes" );
    }
    
    Payload[] search( inout Box boundary ) const
    {
        Payload[] res;
        
        if( storage.length )
            res = search( boundary, boundary, 0, 0 );
        
        debug(rtreearray) writeln("Found ", res.length, " items" );
        
        return res;
    }
    
    private
    Payload[] search( inout Box boundary, inout Box delta2, size_t place, in size_t currDepth ) const
    {
        Payload[] res;
        
        Box curr_boundary;
        place += curr_boundary.decompress( &storage[place] );
        
        if( curr_boundary.isOverlappedBy( boundary ) )
        {
            size_t children_num;
            place += children_num.unpackVarint( &storage[place] );
            
            if( currDepth >= depth ) // returning leafs
                res ~= getPayloads( children_num, &storage[place] );
            
            else // searching in nodes
            {
                auto offsets = new size_t[ children_num ];
                
                for( size_t i = 1; i < offsets.length; i++ ) // skips first zero offset
                    place += offsets[i].unpackVarint( &storage[place] );
                
                for( auto i = 0; i < children_num; i++ )
                    res ~= search( boundary, boundary, place + offsets[i], currDepth+1 );
            }
        }
        
        return res;
    }
    
    private static
    Payload[] getPayloads( inout size_t items_num, inout ubyte* src )
    {
        Payload[] res = new Payload[ items_num ];
        size_t offset;
        
        for( auto i = 0; i < items_num; i++ )
        {
            auto last_offset = res[i].decompress( src + offset );
            assert( last_offset > 0 );
            offset += last_offset;
        }
        
        return res;
    }
    
    private
    ubyte[] fillNode( inout RTreePtrs!(Box, Payload).Node* curr, size_t currDepth = 0 )
    {
        ubyte[] res = curr.boundary.compress; // boundary
        res ~= packVarint( curr.children.length ); // number of children
        
        if( currDepth >= depth ) // adding leafs
            foreach( c; curr.children )
                res ~= (*c.payload).compress;
                
        else // adding nodes
        {
            auto offsets = new size_t[ curr.children.length ];
            ubyte[] children_encoded;
            
            foreach( i, c; curr.children )
            {
                offsets[i] = children_encoded.length;
                children_encoded ~= fillNode( c, currDepth+1 );
            }
            
            assert( offsets[0] == 0 ); // first offset
            
            ubyte[] offsets_encoded;
            
            for( size_t i = 1; i < curr.children.length; i++ ) // excludes first offset
                offsets_encoded ~= packVarint( offsets[i] );
                
            res ~= offsets_encoded ~ children_encoded;
        }
        
        return res;
    }
}

unittest
{
    import std.string;
    
    alias Vector2D!long V;
    alias Box!V BBox;
    
    auto rtree = new RTreePtrs!(BBox, V)( 2, 2 );
    
    for( auto y = -16; y < 16; y++ )
        for( auto x = -16; x < 16; x++ )
        {
            auto payload = V( x, y );
            BBox boundary = BBox( V( x, y ), V( 1, 1 ) );
            
            rtree.addObject( boundary, payload );
        }
    
    auto rarr = new RTreeArray!(typeof(rtree))( rtree );
    
    BBox search1 = BBox( V( 2, 2 ), V( 1, 1 ) );
    
    assert( rarr.search( search1 ).length >= 9 );
}
