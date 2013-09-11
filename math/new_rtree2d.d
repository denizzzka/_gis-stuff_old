module math.new_rtree2d;

import math.geometry;
import protobuf.runtime;

debug import std.stdio;
version(unittest) import std.string;
import core.bitop;


class RTreePtrs( _Box, _Payload )
{
    alias _Box Box;
    alias _Payload Payload;
    
    const size_t maxChildren;
    const size_t maxLeafChildren;
    
    ubyte depth = 0;
    Node* root;
    
    Payload[] payloads;
    
    this( in size_t maxChildren = 5, in size_t maxLeafChildren = 250 )
    in
    {
        assert( maxChildren >= 2 );
        assert( maxLeafChildren >= 1 );
    }
    body
    {
        this.maxChildren = maxChildren;
        this.maxLeafChildren = maxLeafChildren;
    }
    
    struct Node
    {
        private
        {
            Node* parent;
            Box boundary;
            
            union
            {
                Node*[] children;
                Payload* payload;
            }
            
            debug const bool leafNode;
        }
        
        this( in Box boundary, Payload* payload )
        {
            debug leafNode = true;
            
            this.boundary = boundary;
            this.payload = payload;
        }
        
        Box getBoundary() const
        {
            return boundary;
        }
    }
    
    void addObject( in Box boundary, Payload payload )
    {
        payloads ~= payload;
        Payload* payload_ptr = &payloads[$-1];
        
        if( !root )
        {
            assert( !depth );
            
            root = new Node( boundary, payload_ptr );
            
            return;
        }
        
        auto place = selectLeafPlace( boundary );
    }
    
    private
    {
        Node* selectLeafPlace( in Box newItemBoundary ) const
        {
            assert( root );
            Node* curr = cast(Node*) root;
            
            for( auto currDepth = 0; currDepth < depth; currDepth++ )
            {
                debug assert( !curr.leafNode );
                
                auto area = new float[ curr.children.length ];
                
                // search for min area of child nodes
                size_t minKey;
                foreach( i, c; curr.children )
                {
                    area[i] = c.boundary.getCircumscribed( newItemBoundary ).getArea();
                    
                    if( area[i] < area[minKey] )
                        minKey = i;
                }
                
                curr = curr.children[minKey];
            }
            
            return curr;
        }
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
    import core.memory;
    debug GC.disable();    
    
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
}