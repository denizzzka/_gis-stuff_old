module rtree2d;

import protobuf;

import std.algorithm;
import std.stdio;

struct Vector2D
{
    float x;
    float y;
    
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
    
    Vector2D getSizeVector()
    {
        return Vector2D( ru.x - ld.x, ru.y - ld.y );
    }
    
    auto getArea()
    {
        auto size = getSizeVector();
        return size.x * size.y;
    }
    
    Box getCircumscribed( Box b )
    {
        Box res;
        
        res.ld.x = min( ld.x, b.ld.x );
        res.ld.y = min( ld.y, b.ld.y );
        
        res.ru.x = max( ru.x, b.ru.x );
        res.ru.y = max( ru.y, b.ru.y );
        
        return res;
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
    Vector2D coords;
    Vector2D value;
    
    Box getBound()
    {
        return Box( coords, value );
    }
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
    ubyte depth = 0;
    Knot* root;
    
    this()
    {
        root = new Knot;
    }
    
    static union Knot
    {
        Node node;
        Leaf leaf;
    }
    
    static struct Node
    {
        Node* parent;
        Knot* children[];
        Box bound;
    }
    
    static struct Leaf
    {
        Node* parent;
        RTreePayload payload;
    }
    
    void addObject( RTreePayload o )
    {
        auto leaf = selectLeaf( o.getBound(), root );
        
        //if( leaf.
    }
    
    private:
    Leaf* selectLeaf( Box newItemBound, Knot* curr, ubyte currDepth = 0 )
    {
        if( currDepth == depth )
            return &curr.leaf;
        
        auto areas = new float[ curr.node.children.length ];
        
        // get areas for all child nodes
        foreach( size_t i, child; curr.node.children )
            areas[i] = child.node.bound.getCircumscribed( newItemBound ).getArea();
        
        // search for min area
        size_t minKey;
        foreach( i, f; areas )
            if( areas[minKey] > areas[i] )
                minKey = i;
        
        return selectLeaf( newItemBound, curr.node.children[minKey], ++currDepth );
    }
    
    void correctNode( Knot* needsCorrection, ubyte currDepth = 0, Knot* newNode = null )
    {
        if( currDepth == 0 )
        {
            if( newNode != null )
            {
                // creating new root from two remaining nodes
                auto r = new Knot;
                r.node.children = [ needsCorrection, newNode ];
                root = r;
                depth++;
            }
            
            return;
        }
    }
}
    

unittest
{
    auto rtree = new RTreePtrs;
    
    for( float y = 0; y < 10; y++ )
        for( float x = 0; x < 10; x++ )
        {
            RTreePayload p;
            p.coords = Vector2D( x, y );
            p.value = Vector2D( 1, 1 );
            
            rtree.addObject( p );
            rtree.addObject( p );
        }
}
