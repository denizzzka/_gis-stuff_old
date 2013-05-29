module rtree2d;

import protobuf;

import std.algorithm;
import std.stdio;
import core.bitop: bt;

struct Vector2D
{
    float x = 0;
    float y = 0;
    
    alias x lon;
    alias y lat;
}

struct Box
{
    Vector2D leftDownCorner;
    Vector2D rightUpCorner;
    
    alias leftDownCorner ld;
    alias rightUpCorner ru;
    
    this( in Vector2D coords, in Vector2D size )
    {
        leftDownCorner.x = coords.x + ((size.x > 0) ? 0 : size.x);
        leftDownCorner.y = coords.y + ((size.y > 0) ? 0 : size.y);
        rightUpCorner.x = coords.x + ((size.x < 0) ? 0 : size.x);
        rightUpCorner.y = coords.y + ((size.y < 0) ? 0 : size.y);
    }
    
    bool isOverlappedBy( Box b )
    {
        auto ld2 = b.leftDownCorner;
        auto ru2 = b.rightUpCorner;
        
        return
            ld.x <= ru2.x &&
            ru.x >= ld2.x &&
            ld.y <= ru2.y &&
            ru.y >= ld2.y;
    }
    
    Vector2D getSizeVector() const
    {
        return Vector2D( ru.x - ld.x, ru.y - ld.y );
    }
    
    auto getArea() const
    {
        auto size = getSizeVector();
        return size.x * size.y;
    }
    
    Box getCircumscribed( in Box b ) const pure
    {
        Box res;
        
        res.ld.x = min( ld.x, b.ld.x );
        res.ld.y = min( ld.y, b.ld.y );
        
        res.ru.x = max( ru.x, b.ru.x );
        res.ru.y = max( ru.y, b.ru.y );
        
        return res;
    }
    
    void addCircumscribe( in Box b ) pure
    {
        this = this.getCircumscribed( b );
    }
}

unittest
{
    Vector2D coords1 = { 0, 0 };
    Vector2D size1 = { 1, 1 };
    
    Vector2D coords2 = { 1, 0 };
    Vector2D size2 = { 1, 1 };
    
    Box box1 = Box( coords1, size1 );
    Box box2 = Box( coords2, size2 );
    
    assert( box1.isOverlappedBy( box2 ) );
    
    assert( box1.getCircumscribed( box2 ) == Box(Vector2D(0, 0), Vector2D(2, 1)) );
}

struct RTreePayload
{
    string data = "123"; 
}

struct RTreeArray
{
    ubyte depth = 0;
    ubyte[] data;
    
    static struct Node
    {
        Box bound;
        ubyte childOffset;
    }
    
    static struct Leaf
    {
        RTreePayload payload;
    }
    
    void addObject( RTreePayload o )
    {
    }
}


class RTreePtrs
{
    immutable ubyte maxChildren = 2;
    ubyte depth = 0;
    Node* root;
    
    this()
    {
        root = new Node;
    }
    
    static struct Node
    {
        Node* parent;
        Box boundary;
        Node*[] children;
    
        void assignChild( Node* child )
        {
            children ~= child;
            boundary = boundary.getCircumscribed( child.boundary );
            child.parent = &this;
        }
    }
    
    static struct Leaf
    {
        Node* parent;
        Box boundary;
        RTreePayload payload;
        
        this( in Box boundary, in RTreePayload payload )
        {
            this.boundary = boundary;
            this.payload = payload;
        }
    }
    
    void addObject( Box boundary, in RTreePayload o )
    {
        // unconditional add a leaf
        auto place = selectLeafPlace( root, boundary );
        auto l = new Leaf( boundary, o );
        place.assignChild( cast( Node* ) l );
        
        writeln( "Add leaf ", l, " to node ", place );
        
        // correction of the tree
        correct( place );
    }
    
    private:
    
    Node* selectLeafPlace( Node* curr, in Box newItemBoundary )
    {
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
                    
                    writeln( "Added new root, depth (without leafs) now is: ", depth );
                }
                
                Node* n = splitNode( node );
                node.parent.assignChild( n );
            }
            else // just recalculate boundary
            {
                Box boundary;
                foreach( c; node.children )
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
                
                if( bt( cast( ulong* ) &i, j ) == 0 )
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
        auto newNode = new Node;
        auto tmpNode = new Node;
        
        for( auto i = 0; i < len; i++ )
        {
            auto c = n.children[i];
            
            if( bt( cast( ulong* ) &minAreaKey, i ) == 0 )
                tmpNode.assignChild( c );
            else
                newNode.assignChild( c );
        }
        
        n.children = tmpNode.children;
        n.boundary = tmpNode.boundary;
        
        writeln( "Split node ", n, " ", n.children, ", new ", newNode, " ", newNode.children );
        stdout.flush();
        
        return newNode;
    }
}


unittest
{
    import core.memory;
    GC.disable();    
    
    auto rtree = new RTreePtrs;
    
    void showTree( RTreePtrs.Node* from, uint depth = 0 )
    {
        writeln( "Depth: ", depth );
        
        if( depth > rtree.depth )
        {
            writeln( "Leaf: ", from, " parent: ", from.parent );
        }
        else
        {
            writeln( "Node: ", from, " parent: ", from.parent, " children: ", from.children );
            
            foreach( i, c; from.children )
            {
                showTree( c, depth+1 );
            }
        }
    }
    
    for( float y = 0; y < 2; y++ )
        for( float x = 0; x < 8; x++ )
        {
            RTreePayload p;
            Box b = Box( Vector2D( x, y ), Vector2D( 1, 1 ) );
            
            rtree.addObject( b, p );
    
            writeln("\nShow tree:");
            showTree( rtree.root );
        }
}
