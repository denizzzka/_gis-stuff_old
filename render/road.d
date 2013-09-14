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
    
    void drawPointsBetween( Vector2F[] coords, in float width, in Color color )
    {
        for( auto i = 1; i < coords.length; i++ )
            drawRoadJointPoint( coords[i], width, color );
    }
    
    void drawRoadSegmentLine( Vector2F from, Vector2F to, in float width, in Color color )
    {
        auto vector = to - from;
        auto length = vector.length;
        auto angleOX = vector.angleOX;
        
        auto degrees = -angleOX.radian2degree + 90;
        degrees = degrees % 360;
        
        auto rect = new RectangleShape;
        
        rect.origin = Vector2f( 0, width / 2 );
        rect.position = Vector2f( from );
        rect.rotation = degrees;
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
    
    void forAllRoads( SfmlRoad[] roads, bool foreground,
            void delegate( Vector2F[] coords, in float width, in Color color ) dg
        )
    {
        foreach( ref r; roads )
        {
            const props = &polylines.getProperty( r.props.type );
            
            float width;
            Color color;
            
            if( foreground )
            {
                width = props.thickness;
                color = props.color;
            }
            else
            {
                width = props.thickness + props.outlineThickness;
                color = props.outlineColor;
            }
            
            dg( r.coords, width, color );
        }
    }
    
    void drawLayer( SfmlRoad[] roads, bool foreground )
    {
        forAllRoads( roads, foreground, &drawRoadSegments );
        forAllRoads( roads, foreground, &drawPointsBetween );
    }
    
    void drawPointType( Vector2F coords, cat.Line type, bool foreground )
    {
        auto props = &polylines.getProperty( type );
        
        float width;
        Color color;
        
        if( foreground )
        {
            width = props.thickness;
            color = props.color;
        }
        else
        {
            width = props.outlineThickness;
            color = props.outlineColor;
        }
        
        drawRoadJointPoint( coords, width, color );
    }
    
    void drawRoads( RoadsSorted roads )
    {
        foreach( i, layer; roads.sorted )
        {
            if( i == 0 ) // first layer
                foreach( by_type; layer )
                    drawLayer( by_type, false ); // background
            
            if( i < roads.sorted.length-1 ) // not last layer
                foreach( by_type; roads.sorted[i+1] )
                    drawLayer( by_type, false ); // background
            
            // background dominating points
            foreach( by_type; layer )
                foreach( road; by_type )
                {
                    drawPointType( road.coords[0], road.startDominatingType, false );
                    drawPointType( road.coords[$-1], road.endDominatingType, false );
                }
                
            foreach_reverse( by_type; layer )
            //auto by_type2 = layer[ cat.Line.UNSUPPORTED ];
                drawLayer( by_type, true ); // foreground
            
            // foreground dominating points
            foreach( by_type; layer )
                foreach( road; by_type )
                {
                    drawPointType( road.coords[0], road.startDominatingType, true );
                    drawPointType( road.coords[$-1], road.endDominatingType, true );
                }
        }
    }
}
