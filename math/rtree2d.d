module math.rtree2d;

import math.geometry;
import protobuf.runtime;

debug import std.stdio;
version(unittest) import std.string;
import core.bitop;
import std.typecons;


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
            res ~= (cast (RTreePtrs.Leaf*) curr).payload.Serialize();
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


class RTreePtrs( _Box, _Payload )
{
    alias _Box Box;
    alias _Payload Payload;
    
    const ubyte maxChildren;
    ubyte depth = 0;
    Node* root;
    
    this( in ubyte maxChildren = 50 )
    in
    {
        assert( maxChildren >= 2 );
    }
    body
    {
        this.maxChildren = maxChildren;
        
        root = new Node;
    }
    
    static struct Node
    {
        private:
        
            Node* parent;
            Nullable!Box boundary;
            Node*[] children;
    
        public:
        
            void assignChild( Node* child )
            {
                children ~= child;
                
                boundary = boundary.isNull ?
                    child.boundary :
                    boundary.getCircumscribed( child.boundary );
                    
                child.parent = &this;
            }
            
            Box getBoundary() const
            {
                return boundary;
            }
    }
    
    static struct Leaf
    {
    private:
        Node* parent;
        
    public:
        Nullable!Box boundary;
        Payload payload;
        
        this( in Box boundary, Payload payload )
        {
            this.boundary = boundary;
            this.payload = payload;
        }
    }
    
    Payload* addObject( Box boundary, Payload o )
    {
        // unconditional add a leaf
        auto place = selectLeafPlace( boundary );
        auto l = new Leaf( boundary, o );
        place.assignChild( cast( Node* ) l );
        
        debug(rtptrs) writeln( "Add leaf ", l, " to node ", place );
        
        // correction of the tree
        correct( place );
        
        return &l.payload;
    }
    
    Box getBoundary() const
    {
        return root.getBoundary();
    }

    Payload*[] search( in Box boundary ) const
    {
        return search( boundary, root );
    }
    
    void statistic(
        out size_t nodesNum,
        out size_t leafsNum,
        out size_t leafBlocksNum
    )
    {
        nodesNum = 1;
        leafsNum = 0;
        leafBlocksNum = 0;
        
        statistic( root, nodesNum, leafsNum, leafBlocksNum );
    }
    
    debug
    void showBranch( Node* from, uint depth = 0 )
    {
        writeln( "Depth: ", depth );
        
        if( depth > this.depth )
        {
            writeln( "Leaf: ", from, " parent: ", from.parent );
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
    
private:
    
    Payload*[] search( in Box boundary, const (Node)* curr, size_t currDepth = 0 ) const
    {
        Payload*[] res;
        
        if( currDepth > depth )
            res ~= &(cast( Leaf* ) curr).payload;
        else
            foreach( i, c; curr.children )
                if( c.boundary.isOverlappedBy( boundary ) )
                    res ~= search( boundary, c, currDepth+1 );
        
        return res;
    }
    
    void statistic(
        in Node* curr,
        ref size_t nodesNum,
        ref size_t leafsNum,
        ref size_t leafBlocksNum,
        size_t currDepth = 0
    )
    {
        if( currDepth == depth )
        {
            leafBlocksNum++;
            leafsNum += curr.children.length;
        }
        else
        {
            nodesNum += curr.children.length;
            
            foreach( i, c; curr.children )
                statistic( c, nodesNum, leafsNum, leafBlocksNum, currDepth+1 );
        }
    }
    
    Node* selectLeafPlace( in Box newItemBoundary )
    {
        Node* curr = root;
        
        for( auto currDepth = 0; currDepth < depth; currDepth++ )
        {
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
    
    Node* createParentNode( Node* child )
    {
        auto r = new Node;
        r.assignChild( child );
        return r;
    }
    
    void correct( Node* fromNode )
    {
        auto node = fromNode;
        
        while( node )
        {
            if( node.children.length > maxChildren ) // need split?
            {
                if( node.parent is null ) // for root split need a new root node
                {
                    root = createParentNode( node );
                    depth++;
                    
                    debug(rtptrs) writeln( "Added new root, depth (without leafs) now is: ", depth );
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
        }
    }
    
    /// convert number to number of bits
    static pure auto numToBits( T, N )( N n )
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
    
    /// Brute force method
    Node* splitNode( Node* n )
    in
    {
        assert( n.children.length > 1 );
    }
    body
    {
        size_t len = n.children.length;
        
        float minArea = float.max;
        uint minAreaKey;
        
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
        n.boundary.nullify;
        
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
    
    auto rtree = new RTreePtrs!(BBox, DumbPayload)( 2 );
    
    for( float y = 1; y < 4; y++ )
        for( float x = 1; x < 4; x++ )
        {
            DumbPayload payload;
            BBox boundary = BBox( Vector( x, y ), Vector( 1, 1 ) );
            
            rtree.addObject( boundary, payload );
    
            debug(rtptrs)
            {
                writeln("\nShow tree:");
                rtree.showBranch( rtree.root );
                
                writeln( "Boundary: ", rtree.root.getBoundary );
            }
        }
    
    debug(rtree) rtree.showBranch( rtree.root );
    
    size_t leafs, nodes, leafBlocksNum;
    rtree.statistic( nodes, leafs, leafBlocksNum );
    assert( leafs == 9 );
    assert( nodes == 13 );
    assert( leafBlocksNum == 6 );
    
    debug GC.enable();
    
    assert( rtree.root.getBoundary == BBox(Vector(1, 1), Vector(3, 3)) );
    
    BBox search1 = BBox( Vector( 2, 2 ), Vector( 1, 1 ) );
    BBox search2 = BBox( Vector( 2.1, 2.1 ), Vector( 0.8, 0.8 ) );
    
    assert( rtree.search( search1 ).length == 9 );
    assert( rtree.search( search2 ).length == 1 );
    
    auto rarr = new RTreeArray!(typeof(rtree))( rtree );
    
    assert( rarr.search( search1 ).length == 9 );
    assert( rarr.search( search2 ).length == 1 );
}
