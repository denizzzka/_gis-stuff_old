module render.road;

import dsfml.graphics;
import cat = config.categories;
import config.map: PolylineProperties, polylines;
import map.map: RoadGraph;


mixin template Road()
{
    void drawRoadJointPoint( Vector2F center, in float diameter, in Color color )
    {
        auto radius = diameter / 2;
        
        auto circle = new CircleShape;
        
        circle.origin = Vector2f( radius, radius );
        circle.position = Vector2f( center );
        circle.radius = radius;
        circle.fillColor = color;
        
        window.draw( circle );
    }
    
    void drawRoadSegmentLine( Vector2F from, Vector2F to, in float width, in Color color )
    {
        auto vector = to - from;
        auto length = vector.length;
        auto angleOX = vector.angleOX;
        
        auto rect = new RectangleShape;
        
        rect.origin = Vector2f( 0, width / 2 );
        rect.position = Vector2f( from );
        rect.rotation = -angleOX.radian2degree + 90;
        rect.size = Vector2f( length, width );
        rect.fillColor = color;
        
        window.draw( rect );
    }
    
    void drawRoadSegments( Vector2F[] coords, in float width, in Color color )
    in
    {
        assert( coords.length >= 2 );
    }
    body
    {
        auto prev = coords[0];
        
        for( auto i = 1; i < coords.length; i++ )
        {
            drawRoadSegmentLine( prev, coords[i], width, color );
            prev = coords[i];
        }
    }
    
    struct RoadDrawProperties
    {
        float thickness;
        float outlineThickness;
        Color color;
        Color outlineColor;
        
        this( T )( T prop )
        {
            thickness = prop.thickness;
            outlineThickness = prop.outlineThickness;
            color = prop.color;
            outlineColor = prop.outlineColor;
        }
    }
    
    void drawRoadEdge( in RoadGraph g, in RoadGraph.EdgeDescr road, in RoadDrawProperties prop )
    {
        auto map_coords = g.getMapCoords( road );
        WindowCoords[] cartesian = MapToWindowCoords( map_coords );
        auto coords = cartesianToSFML( cartesian );
        
        auto fullWidth = prop.thickness + prop.outlineThickness;
        
        foreach( c; coords )
            drawRoadJointPoint( c, fullWidth, prop.color );
        
        drawRoadSegments( coords, fullWidth, prop.outlineColor );
        drawRoadSegments( coords, prop.thickness, prop.color );
        
        foreach( c; coords )
            drawRoadJointPoint( c, prop.thickness, prop.color );
    }
    
    void drawRoadEdge( in RoadGraph g, in RoadGraph.EdgeDescr road )
    {
        const type = g.getEdge( road ).payload.type;
        auto drawProps = RoadDrawProperties( polylines.getProperty( type ) );
        
        drawRoadEdge( g, road, drawProps );
    }
    
    void drawPathEdge( in RoadGraph g, in RoadGraph.EdgeDescr road )
    {
        auto drawProps = RoadDrawProperties( polylines.getProperty( cat.Line.PATH ) );
        
        drawRoadEdge( g, road, drawProps );
    }
    
    void drawMonochromeLayer( SfmlRoad[] roads, in float width, in Color color )
    {
        foreach( r; roads )
            drawRoadSegments( r.coords, width, color );
            
        foreach( r; roads )
            foreach( c; r.coords )
                drawRoadJointPoint( c, width, color );
    }
    /*
    void drawRoadsLayer( RoadToSort[] roads )
    {
        const fullWidth = prop.thickness + prop.outlineThickness;
        
        
        foreach( r; roads )
            if( foreground )
                drawRoadSegments( r.coords, r.properties.thickness, r.properties.color );
            else
                drawRoadSegments( r.coords, fullWidth, r.properties.outlineColor );
        
        foreach( road; roads )
            foreach( c; road.coords )
                if( foreground )
                    drawRoadJointPoint( c, r.properties.thickness, r.properties.outlineColor );
                else
                    drawRoadJointPoint( c, fullWidth, r.properties.outlineColor );
    }
    */
    void drawRoads( RoadsSorted sorted )
    {
        foreach( layer; sorted.roads )
            foreach( road; layer )
            {
                //const type = g.getEdge( road ).payload.type;
                //auto drawProps = RoadDrawProperties( polylines.getProperty( type ) );
                
                //drawRoadEdge( road.graph, road.edge );
            }
    }
}
