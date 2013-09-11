module render.sfml;

import render.window;
import dsfml.graphics;
import scene;
import math.geometry;
import map.map: MapLinesDescriptor, MapCoords, MercatorCoords, RoadGraph;
import cat = config.categories;
import render.road;

import std.conv: to;
import std.random;
debug(sfml) import std.stdio;
debug(scene) import std.stdio;
debug(controls) import std.stdio;


struct Vector2f
{
    dsfml.graphics.Vector2f vector;
    
    this( float X, float Y )
    {
	vector = dsfml.graphics.Vector2f( X , Y );
    }
    
    alias vector this;
    
    void opAssign(T)( in T v )
    if( !isScalarType!(T) )
    {
	x = v.x;
	y = v.y;
    }
}

class Window : IWindow
{
    POV scene;
    RenderWindow window;    
    
    private
    {
	VertexArray vertex_array;
    }
    
    this()
    {
	auto vmode = VideoMode( 640, 480 );
	string title = "hello world!";
	
	window = new RenderWindow( vmode, title );
	
	window.setFramerateLimit(24);
	//window.setVerticalSyncEnabled(true);
    }
    
    void mainCycle()
    {
	while(window.isOpen)
	{
	    eventsProcessing();
	    
	    window.clear(Color.Black);
	    
	    if( scene )
	    {
		scene.calcBoundary( this );
		
		vertex_array = new VertexArray( PrimitiveType.Points, 0 );
		auto pois = scene.getPOIs();
		drawPOIs( pois );
		window.draw( vertex_array );
		
		auto any = scene.getLines();
		drawLines( any );
		
		drawPath( scene.found_path );
	    }
	    
	    drawCenter;
	    
	    window.display;
	}
    }
    
    private
    void drawPOIs(T)( in T pois )
    {
        for(auto i = 0; i < pois.length; i++)
        {
            MercatorCoords node = pois[i].coords.getMercatorCoords;
            auto window_coords = scene.metersToScreen( node );
            
            debug(sfml) writeln("draw point i=", i, " encoded coords=", pois[i], " meters=", node, " window_coords=", window_coords);
            
	    Vector2f c; c = cartesianToSFML(window_coords );
	    vertex_array.append( Vertex(c, Color.Cyan) );
        }
    }
    
    private
    WindowCoords[] MapToWindowCoords( MapCoords[] map_points )
    {
	WindowCoords[] res;
	
	foreach( i, point; map_points )
	    res ~= scene.metersToScreen( point );
	    
	return res;
    }
    
    private
    void drawLines( MapLinesDescriptor[] map_lines )
    {	
        foreach( ref reg_lines; map_lines )
	    foreach( ref line; reg_lines.lines )
	    {
		MapCoords[] encoded_points;
		Color color;
		
		with( cat.LineClass ) final switch( line.line_class )
		{
		    case POLYLINE:
			auto graph = reg_lines.region.line_graph;
			encoded_points = graph.getMapCoords( line.line );
			color = graph.getPolyline( line.line ).properties.color;
			break;
			
		    case ROAD:
			auto graph = reg_lines.region.layers[ reg_lines.layer_num ].road_graph;
			encoded_points = graph.getMapCoords( line.road );
			
			auto bend1 = scene.metersToScreen( encoded_points[0] );
			auto bend2 = scene.metersToScreen( encoded_points[$-1] );
			
			auto type = graph.getPolyline( line.road ).type;
			drawRoadBend( bend1, type );
			drawRoadBend( bend2, type );
			
			auto crds = MapToWindowCoords( encoded_points );
			drawRoadSegments( crds, type );
			continue;
			
		    case AREA:
			auto area_points = line.area.perimeter.points;
			encoded_points = area_points ~ area_points[0];
			color = line.area.properties.color;
			break;
		}
		
		auto res_points = MapToWindowCoords( encoded_points );
		drawLine( res_points, color );
	    }
    }
    
    private
    void drawPath( in RoadGraph.Polylines lines )
    {
	alias RoadGraph.Polylines.MapGraphType_copy_because_compiling_bug RG;
	
	void dg( inout RG g, inout RoadGraph.PolylineDescriptor descr )
	{
	    auto encoded_points = g.getMapCoords( descr );
	    
	    auto bend1 = scene.metersToScreen( encoded_points[0] );
	    auto bend2 = scene.metersToScreen( encoded_points[$-1] );
	    
	    auto type = config.categories.Line.PATH;
	    drawRoadBend( bend1, type );
	    drawRoadBend( bend2, type );
	    
	    auto crds = MapToWindowCoords( encoded_points );
	    drawRoadSegments( crds, type );
	}
	
	lines.forAllLines( &dg );
    }
    
    void drawCenter()
    {
	auto c = getCenter();
	
	auto horiz = Vector2f(8, 0);
	auto vert = Vector2f(0, 8);
	
	auto cross = new VertexArray( PrimitiveType.Lines, 4 );
	
	cross.append( Vertex(c-vert) );
	cross.append( Vertex(c+vert) );
	cross.append( Vertex(c-horiz) );
	cross.append( Vertex(c+horiz) );
	
	window.draw( cross );
    }
    
    private
    void drawLine( WindowCoords[] coords, Color color )
    {
	debug(sfml) writeln("draw line, nodes num=", coords.length, " color=", color);
	
	auto line = new VertexArray( PrimitiveType.LinesStrip, coords.length );
	
	foreach( i, point; coords )
	{
	    Vector2f c; c = cartesianToSFML( point );
	    debug(sfml) writeln("draw line node, window coords=", c);
	    
	    line[i] = Vertex(c, color);
	}
	
	window.draw( line );
    }
        
    Vector2uint getSize()
    {
        Vector2uint res = window.size;
	
	return res;
    }
    
    Vector2f getCenter()
    {
	Vector2f c;
	
	c = window.size;
	c /= 2;
	
	return c;
    }
    
    T cartesianToSFML( T )( ref T from )
    {
	from.y = to!real(window.size.y) - from.y;
	
	return from;
    }
    
    mixin Road;
    
    private void eventsProcessing()
    {
	Event event;
	while (window.pollEvent(event))
	{
	    switch( event.type )
	    {
		case Event.Closed:
		    window.close();
		    break;
		    
		case Event.Resized:
		    auto visibleArea = FloatRect(0, 0, event.size.width, event.size.height);
		    auto view = new View( visibleArea );
		    window.view( view );
		    
		    debug(controls)
			writeln("window size=", window.size);
			
		    break;
		
		case Event.KeyPressed:
		    immutable auto zoom_step = 1.05;
		    auto center = scene.getCenter;
		    auto zoom = scene.getZoom;
		    auto dir_step = 10.0 / zoom;
		    
		    switch( event.key.code )
		    {
			case Keyboard.Key.Escape:
			    window.close();
			    break;
			
			case Keyboard.Key.Equal: // zoom in
			    zoom *= zoom_step;
			    debug(controls) writeln(scene);
			    break;
			
			case Keyboard.Key.Dash: // zoom out
			    zoom /= zoom_step;
			    debug(controls) writeln(scene);
			    break;
			    
			case Keyboard.Key.Right:
			    center.x += dir_step;
			    debug(controls) writeln(scene);
			    break;
			    
			case Keyboard.Key.Left:
			    center.x -= dir_step;
			    debug(controls) writeln(scene);
			    break;
			    
			case Keyboard.Key.Up:
			    center.y += dir_step;
			    debug(controls) writeln(scene);
			    break;
			    
			case Keyboard.Key.Down:
			    center.y -= dir_step;
			    debug(controls) writeln(scene);
			    break;
			
			case Keyboard.Key.F:
			    debug(controls) write("Find path..."), stdout.flush();
			    scene.updatePath();
			    debug(controls) writeln("done");
			    break;
			
			default:
			    break;
		    }
		    
		    scene.setZoom( zoom );
		    scene.setCenter( center );
		    break;
		    
		default:
		    break;
	    }
	}
    }
}

Color randomColor()
{
    return Color(
	    to!ubyte( uniform(30, 255) ),
	    to!ubyte( uniform(30, 255) ),
	    to!ubyte( uniform(30, 255) ),
	);
}
