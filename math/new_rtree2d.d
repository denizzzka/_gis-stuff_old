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
        
        root = new Node;
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
        
        void assignChild( Node* child )
        {
            debug assert( !leafNode );
            
            if( children.length )
                boundary.addCircumscribe( child.boundary );
            else
                boundary = child.boundary;
            
            children ~= child;
            child.parent = &this;
        }
    }
    
    Payload* addObject( in Box boundary, Payload payload )
    {
        payloads ~= payload;
        Payload* payload_ptr = &payloads[$-1];
        
        Node* leaf = new Node( boundary, payload_ptr );
        auto place = selectLeafPlace( boundary );
        
        debug(rtptrs) writeln( "Add leaf ", leaf, " to node ", place );     
        
        place.assignChild( leaf ); // unconditional add a leaf
        correct( place ); // correction of the tree
        
        return payload_ptr;        
    }
    
    private
    {
        Node* selectLeafPlace( in Box newItemBoundary ) const
        {
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
        
        void correct( in Node* fromDeepestNode )
        {
            auto node = cast(Node*) fromDeepestNode;
            bool leafs_level = true;
            
            debug(rtptrs) writeln( "Correcting from node ", fromDeepestNode );
            
            while( node )
            {
                debug(rtptrs) writeln( "Correcting node ", node );
                
                if( (leafs_level && node.children.length > maxLeafChildren) // need split on leafs level?
                    || (!leafs_level && node.children.length > maxChildren) ) // need split of node?
                {
                    if( node.parent is null ) // for root split need a new root node
                    {
                        auto old_root = root;
                        root = new Node;
                        root.assignChild( old_root );
                        depth++;
                        
                        debug(rtptrs) writeln( "Added new root ", root, ", depth (without leafs) now is: ", depth );
                    }
                    
                    Node* n = splitNode( node );
                    node.parent.assignChild( n );
                }
                else // just recalculate boundary
                {
                    Box boundary = node.children[0].boundary;
                    
                    foreach( c; node.children[1..$] )
                        boundary.addCircumscribe( c.boundary );
                        
                    node.boundary = boundary;
                }
                
                node = node.parent;
                leafs_level = false;
            }
            
            debug(rtptrs) writeln( "End of correction" );
        }
        
        /// Brute force method
        RTreePtrs.Node* splitNode( RTreePtrs.Node* n )
        in
        {
            assert( !n.leafNode );
            assert( n.children.length >= 2 );
        }
        body
        {
            alias RTreePtrs.Node Node;
            
            size_t len = n.children.length;
            
            float minArea = float.max;
            uint minAreaKey;
            
            debug(rtptrs)
            {
                writeln( "Begin splitting node ", n, " by brute force" );
                stdout.flush();
            }
            
            // loop through all combinations of nodes
            auto capacity = numToBits!uint( len );
            for( uint i = 1; i < ( capacity + 1 ) / 2; i++ )
            {
                Box b1;
                Box b2;
                
                // division into two unique combinations of child nodes
                uint j;
                for( j = 0; j < len; j++ )
                {
                    auto boundary = n.children[j].boundary;
                    
                    if( bt( cast( size_t* ) &i, j ) == 0 )
                        b1 = b1.getCircumscribed( boundary );
                    else
                        b2 = b2.getCircumscribed( boundary );
                }
                
                // search for combination with minimum area
                float area = b1.getArea() + b2.getArea();
                
                if( area < minArea )
                {
                    minArea = area;
                    minAreaKey = j;
                }
            }
            
            // split by places specified by bits of key
            auto nChildren = n.children.dup;
            n.children.destroy;
            
            auto newNode = new Node;
            
            for( auto i = 0; i < len; i++ )
            {
                auto c = nChildren[i];
                
                if( bt( cast( size_t* ) &minAreaKey, i ) == 0 )
                    n.assignChild( c );
                else
                    newNode.assignChild( c );
            }
            
            debug(rtptrs)
            {
                writeln( "Split node ", n, " ", n.children, ", new ", newNode, " ", newNode.children );
                stdout.flush();
            }
            
            return newNode;
        }
    }
}

private
{
    /// convert number to number of bits
    auto numToBits( T, N )( N n ) pure
    {
        T res;
        for( N i = 0; i < n; i++ )
            res = cast(T) ( res << 1 | 1 );
            
        return res;
    }
    unittest
    {
        assert( numToBits!ubyte( 3 ) == 0b_0000_0111 );
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
