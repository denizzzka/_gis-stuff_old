module map.adapters;

import map.map: MapCoords, MercatorCoords;
import math.geometry: Box, to;

static import math.reduce_points;


struct TPolylineDescription( Properties, alias MAP_COORDS_BY_ID )
{
    alias Box!(MapCoords.Coords) BBox;
    alias TNodeDescription!( ulong, MAP_COORDS_BY_ID ) NodeDescription;
    
    ulong nodes_ids[];
    Properties properties;
    
    this( ulong[] nodes_ids, Properties properties )
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        this.nodes_ids = nodes_ids;
        this.properties = properties;
        
        // coords reading checking
        for( size_t i = 0; i < nodes_ids.length; i++ )
            auto unused = getNode( i ).getCoords;
    }
    
    @disable this();
    
    this(this)
    {
        nodes_ids = nodes_ids.dup;
    }
    
    NodeDescription getNode( in size_t node_idx ) const
    in
    {
        assert( node_idx < nodes_ids.length );
    }
    body
    {
        NodeDescription node = { foreign_id: nodes_ids[ node_idx ] };
        
        return node;
    }
    
    BBox getBoundary() const
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        auto start_node = getNode( 0 ).getCoords;
        auto res = BBox( start_node, MapCoords.Coords(0,0) );
        
        for( auto i = 1; i < nodes_ids.length; i++ )
        {
            auto curr_node = getNode( i ).getCoords;
            res.addCircumscribe( curr_node );
        }
        
        return res;
    }
    
    TPolylineDescription opSlice( size_t from, size_t to )
    {
        auto res = this;
        
        res.nodes_ids = nodes_ids[ from..to ];
        
        return res;
    }
    
    void generalize( in real epsilon )
    {
        NodeDescription[] points;
        
        foreach( i, ref c; nodes_ids )
            points ~= getNode( i );
            
        nodes_ids.destroy;
        
        auto reduced = math.reduce_points.reduce( points, epsilon );
        
        foreach( c; reduced )
            nodes_ids ~= c.foreign_id;
    }
}

struct TNodeDescription( _ForeignID, alias MAP_COORDS_BY_ID )
{
    alias _ForeignID ForeignID;
    
    const ForeignID foreign_id;
    
    MapCoords getCoords() const
    {
        return MAP_COORDS_BY_ID( foreign_id );
    }
    
    MercatorCoords mercator() const
    {
        return getCoords.mercator;
    }
    
    alias mercator this;
}
