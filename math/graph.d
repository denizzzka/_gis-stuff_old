module math.graph;

import math.geometry;


struct Edge
{
    float weight;
    Node* node;
    
    invariant()
    {
        assert( weight >= 0 );
    }
}


struct Node
{
    Vector2D coords;
    Edge[] edges;
}


class Graph
{
    Node* root;
}

unittest
{
    auto g = new Graph;
    
    for( auto y=0; y<3; y++ )
        for( auto x=0; x<3; x++ )
        {
            Node n = { coords: Vector2D(x, y) };
        }
}
