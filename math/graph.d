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
    Knot[] knots;
}
