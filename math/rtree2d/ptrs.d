module math.rtree2d.ptrs;

import math.geometry;

import core.bitop;
import std.typecons: Nullable;
import std.exception: enforce;
debug import std.stdio;
version(unittest) import std.string;


class RTreePtrs( _Box, _Payload )
{
    alias _Box Box;
    alias _Payload Payload;
    
    const size_t maxChildren;
    const size_t maxLeafChildren;
    
    package ubyte depth = 0;
    package Node* root;
    
    private Payload[] payloads;
    
    this( in size_t maxChildren = 4, in size_t maxLeafChildren = 50 )
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
        package
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
    
    Payload*[] search( in Box boundary ) const
    {
        Node* r = cast(Node*) root;
        return search( boundary, r );
    }
    
    Box getBoundary() const
    {
        assert( root.children.length );
        
        return root.boundary;
    }
    
    private
    {
        Payload*[] search( in Box boundary, Node* curr, size_t currDepth = 0 ) const
        {
            Payload*[] res;
            
            if( currDepth > depth )
            {
                debug assert( curr.leafNode );
                
                res ~= curr.payload;
            }
            else
            {
                debug assert( !curr.leafNode );
                
                foreach( i, c; curr.children )
                    if( c.boundary.isOverlappedBy( boundary ) )
                        res ~= search( boundary, c, currDepth+1 );
            }
            
            return res;
        }
        
        Node* selectLeafPlace( in Box newItemBoundary ) const
        {
            Node* curr = cast(Node*) root;
            
            for( auto currDepth = 0; currDepth < depth; currDepth++ )
            {
                debug assert( !curr.leafNode );
                
                // search for min area of child nodes
                float minArea = float.infinity;
                size_t minKey;
                foreach( i, c; curr.children )
                {
                    auto area = c.boundary.getCircumscribed( newItemBoundary ).getArea();
                    
                    if( area < minArea )
                    {
                        minArea = area;
                        minKey = i;
                    }
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
                
                debug assert( node.children[0].leafNode == leafs_level );
                
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
        Node* splitNode( Node* n )
        in
        {
            debug assert( !n.leafNode );
            assert( n.children.length >= 2 );
        }
        body
        {
            debug(rtptrs)
            {
                writeln( "Begin splitting node ", n, " by brute force" );
                stdout.flush();
            }
            
            size_t children_num = n.children.length;
            
            alias uint BinKey;
            
            float minArea = float.max;
            BinKey minAreaKey;
            
            // loop through all combinations of nodes
            auto capacity = numToBits!BinKey( children_num );
            for( BinKey i = 1; i < ( capacity + 1 ) / 2; i++ )
            {
                Nullable!Box b1;
                Nullable!Box b2;
                
                static void circumscribe( ref Nullable!Box box, inout Box add )
                {
                    if( box.isNull )
                        box = add;
                    else
                        box.addCircumscribe( add );
                }
                
                // division into two unique combinations of child nodes
                for( BinKey j = 0; j < children_num; j++ )
                {
                    auto boundary = n.children[j].boundary;
                    
                    if( bt( cast( size_t* ) &i, j ) == 0 )
                        circumscribe( b1, boundary );
                    else
                        circumscribe( b2, boundary );
                }
                
                // search for combination with minimum area
                float area = b1.getArea() + b2.getArea();
                
                if( area < minArea )
                {
                    minArea = area;
                    minAreaKey = i;
                }
            }
            
            // split by places specified by bits of key
            auto oldChildren = n.children.dup;
            n.children.destroy;
            
            auto newNode = new Node;
            
            for( auto i = 0; i < children_num; i++ )
            {
                auto c = oldChildren[i];
                
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
        
        package debug
        void showTree()
        {
            showBranch( root );
        }
        
        debug
        void showBranch( Node* from, uint depth = 0 )
        {
            writeln( "Depth: ", depth );
            
            if( depth > this.depth )
            {
                writeln( "Leaf: ", from, " parent: ", from.parent, " value: ", *from.payload );
            }
            else
            {
                writeln( "Node: ", from, " parent: ", from.parent, " children: ", from.children );
                
                foreach( i, c; from.children )
                {
                    showBranch( c, depth+1 );
                }
            }
        }
        
        package void statistic(
            ref size_t nodesNum,
            ref size_t leafsNum,
            ref size_t leafBlocksNum,
            Node* curr = null,
            size_t currDepth = 0
        ) const
        {
            if( !curr )
            {
                curr = cast(Node*) root;
                nodesNum = 1;
            }
            
            if( currDepth == depth )
            {
                leafBlocksNum++;
                leafsNum += curr.children.length;
            }
            else
            {
                nodesNum += curr.children.length;
                
                foreach( i, c; curr.children )
                    statistic( nodesNum, leafsNum, leafBlocksNum, c, currDepth+1 );
            }
        }
    }
}

private
{
    /// convert number to number of bits
    T numToBits( T, N )( N n ) pure
    {
        {
            auto max_n = n + 1;
            auto bytes_used = max_n / 8;
            
            if( max_n % 8 > 0 )
                bytes_used++;
                
            enforce( bytes_used <= T.sizeof );
        }
        
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
    static struct DumbPayload
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
        
    debug(rtree) rtree.showBranch( rtree.root );
    debug GC.enable();
    
    size_t nodes, leafs, leafBlocksNum;
    rtree.statistic( nodes, leafs, leafBlocksNum );
    
    assert( leafs == 9 );
    //assert( nodes == 13 );
    assert( leafBlocksNum == 6 );
    
    assert( rtree.root.getBoundary == BBox(Vector(1, 1), Vector(3, 3)) );
    
    BBox search1 = BBox( Vector( 2, 2 ), Vector( 1, 1 ) );
    BBox search2 = BBox( Vector( 2.1, 2.1 ), Vector( 0.8, 0.8 ) );
    
    assert( rtree.search( search1 ).length == 9 );
    assert( rtree.search( search2 ).length == 1 );
}
