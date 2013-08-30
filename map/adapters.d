module map.adapters;

import map.map: Coords;
import math.geometry: Box, to;
import cat = categories: Line;
import osm: encodedToMapCoords;

static import math.reduce_points;


struct TPolylineDescription( _ForeignCoords, alias MAP_COORDS_BY_ID )
{
    alias _ForeignCoords ForeignCoords;
    alias Box!Coords BBox;
    
    ulong nodes_ids[];
    cat.Line type;
    ulong way_id;
    
    this( ulong[] nodes_ids, cat.Line type, in ForeignCoords[ulong] nodes = null )
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        this.nodes_ids = nodes_ids;
        this.type = type;
        
        // checking
        if( nodes )
            for( size_t i = 0; i < nodes_ids.length; i++ )
                getNode( i );
    }
    
    @disable this();
    
    this(this)
    {
        nodes_ids = nodes_ids.dup;
    }
    
    private
    Coords getNode( in size_t node_idx ) const
    in
    {
        assert( node_idx < nodes_ids.length );
    }
    body
    {
        auto foreign_id = nodes_ids[ node_idx ];
        
        return MAP_COORDS_BY_ID( foreign_id );
    }
    
    BBox getBoundary() const
    in
    {
        assert( nodes_ids.length >= 2 );
    }
    body
    {
        auto start_node = getNode( 0 );
        auto res = BBox( start_node, Coords(0,0) );
        
        for( auto i = 1; i < nodes_ids.length; i++ )
        {
            auto curr_node = getNode( i );
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
    
    void generalize( IDstruct )( in ForeignCoords[ulong] nodes_coords, in real epsilon )
    {
        IDstruct[] points;
        
        foreach( c; nodes_ids )
            points ~= IDstruct( nodes_coords, c );
            
        nodes_ids.destroy;
        
        auto reduced = math.reduce_points.reduce( points, epsilon );
        
        foreach( c; reduced )
            nodes_ids ~= c.id;
    }
}
