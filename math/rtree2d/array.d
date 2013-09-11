module math.rtree2d.array;

import math.rtree2d.ptrs;
import math.geometry;
import protobuf.runtime;


debug import std.stdio;
version(unittest) import std.string;


class RTreeArray( RTreePtrs )
{
    alias RTreePtrs.Payload Payload;
    alias RTreePtrs.Box Box;
    
    ubyte depth = 0;
    ubyte[] data;
    
    this( RTreePtrs source )
    in
    {
        size_t nodes, leafs, leafsBlocks;
        source.statistic( nodes, leafs, leafsBlocks );
        
        assert( leafs > 0 );
    }
    body
    {
        alias source s;
        
        depth = s.depth;
        
        size_t offset;
        data = fillFrom( s.root, offset );
    }
    
    Payload[] search( in Box boundary, size_t place = 0, in size_t currDepth = 0 )
    {
        Payload[] res;
        size_t num;
        
        place += unpackVarint( &data[place], num );
        
        if( currDepth > depth ) // returning leaf
        {
            Payload o;
            o.Deserialize( &data[place] );
            res ~= o;
        }
        else // searching in nodes
        {
            Box box;
            
            for( auto i = 0; i < num; i++ )
            {
                size_t child;
                
                place += box.Deserialize( &data[place] );
                place += unpackVarint( &data[place], child );
                
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
        
        if( currDepth > depth ) // adding leaf?
        {
            res ~= curr.payload.Serialize();
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
        char[6] data = [ 0x58, 0x58, 0x58, 0x58, 0x58, 0x58 ];
        
        ubyte[] Serialize() const /// TODO: real serialization
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
        DumbPayload a;
        DumbPayload b;
        
        auto serialized = &(a.Serialize())[0];
        auto size = b.Deserialize( serialized );
        
        assert( size == a.sizeof );
        assert( a == b );
    }
}


unittest
{
    alias Vector2D!float Vector;
    alias Box!Vector BBox;
    
    auto rtree = new RTreePtrs!(BBox, DumbPayload)( 2, 2 );
    
    for( float y = 1; y < 4; y++ )
        for( float x = 1; x < 4; x++ )
        {
            DumbPayload payload;
            BBox boundary = BBox( Vector( x, y ), Vector( 1, 1 ) );
            
            rtree.addObject( boundary, payload );
        }
    
    auto rarr = new RTreeArray!(typeof(rtree))( rtree );
    
    // search request and test answers is from ptrs unittest
    BBox search1 = BBox( Vector( 2, 2 ), Vector( 1, 1 ) );
    BBox search2 = BBox( Vector( 2.1, 2.1 ), Vector( 0.8, 0.8 ) );
    
    assert( rarr.search( search1 ).length == 9 );
    assert( rarr.search( search2 ).length == 1 );
}
