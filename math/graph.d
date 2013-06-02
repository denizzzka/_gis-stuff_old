module math.graph;

import math.geometry;


struct Edge
{
    const float weight;
    const Node* node;
    
    invariant()
    {
        assert( weight >= 0 );
    }
}


struct Node
{
    Vector2D coords;
    Edge[] edges;
    string payload;
    
    void addPathToEdge( in Node* n, in float weight )
    {
        Edge e = { node: n, weight: weight };
    }
}


class Graph
{
    Node* root;
}

unittest
{
    auto g = new Graph;
    Node* prev;
    
    for( auto y=0; y<3; y++ )
        for( auto x=0; x<3; x++ )
        {
            Node n = { coords: Vector2D(x, y) };
            
            //if( prev )
                
        }
}
