module render.sfml;

import render.window;
import dsfml.graphics;
import scene;
import math.geometry;
import map.map: MapLinesDescriptor, MapCoords, MercatorCoords, RoadGraph;
import cat = config.categories;
import map.objects_properties: LineClass; // TODO: remove it?
import render.road;
import map.road_graph: RoadProperties;

import std.conv: to;
import std.random;
import std.exception: enforce;
debug(sfml) import std.stdio;
debug(scene) import std.stdio;
debug(controls) import std.stdio;


struct Vector2f /// extending sfml vector type
{
    dsfml.graphics.Vector2f vector;
    alias vector this;
    
    this()( float X, float Y )
    {
	vector = dsfml.graphics.Vector2f( X , Y );
    }
    
    this(T)( T vec )
    {
	x = vec.x;
	y = vec.y;
    }
    
    void opAssign(T)( in T v )
    if( !isScalarType!(T) )
    {
	x = v.x;
	y = v.y;
    }
}

alias Vector2D!float Vector2F; /// our more powerful vector

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
    WindowCoords[] MapToWindowCoords( MapCoords[] map_points ) const
    {
	auto res = new WindowCoords[ map_points.length ];
	
	foreach( i, point; map_points )
	    res[i] = scene.metersToScreen( point );
	    
	return res;
    }
    
    private
    void drawLines( MapLinesDescriptor[] map_lines )
    {
	RoadsSorted roads;
	
        foreach( ref reg_lines; map_lines )
	    foreach( ref line; reg_lines.lines )
	    {
		MapCoords[] encoded_points;
		Color color;
		
		with( LineClass ) final switch( line.line_class )
		{
		    case POLYLINE:
			auto graph = reg_lines.region.line_graph;
			encoded_points = graph.getMapCoords( line.line );
			auto type = graph.getEdge( line.line ).payload.properties.type;
			auto prop = &polylines.getProperty( type );
			color = prop.color;
			break;
			
		    case ROAD:
			auto graph = reg_lines.region.layers[ reg_lines.layer_num ].road_graph;
			auto road = SfmlRoad( this, graph, line.road );
			
			roads.addRoad( road );
			
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
	
	auto path = sfmlPath( scene.found_path );
	roads.addRoads( path );
	drawRoads( roads );
    }
    
    struct SfmlRoad
    {
	alias RoadGraph.EdgeDescr EdgeDescr;
	
        Vector2F[] coords;
        const RoadProperties* props;
	bool draw_start_point;
	bool draw_end_point;
	
	this( Window window, in RoadGraph g, in EdgeDescr edge, RoadProperties* ps = null )
	{
            auto map_coords = g.getMapCoords( edge );
            WindowCoords[] cartesian = window.MapToWindowCoords( map_coords );
            coords = window.cartesianToSFML( cartesian );
	    
	    if( ps )
		props = ps;
	    else
		props = &g.getEdge( edge ).payload.properties;
	}
    }
    
    struct RoadsSorted
    {
	immutable direction_layers_num = 5;
	immutable array_length = direction_layers_num * 2 + 1;
	
	SfmlRoad[][ array_length ] roads;
	
	void addRoad( SfmlRoad road )
	{
	    auto layer = road.props.layer;
	    
	    enforce( layer >= -direction_layers_num );
	    enforce( layer <= direction_layers_num );
	    
	    roads[ layer + direction_layers_num ] ~= road;
	}
	
	void addRoads( SfmlRoad[] roads )
	{
	    foreach( r; roads )
		addRoad( r );
	}
    }
        
    private
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
    
    SfmlRoad[] sfmlPath( in RoadGraph.Polylines r_path )
    {
	SfmlRoad[] res;
	
	foreach( gline; r_path.lines )
	    foreach( edge; gline.descriptors )
	    {
		auto ps = new RoadProperties;
		ps.type = cat.Line.PATH;
		ps.weight = 1;
		
		res ~= SfmlRoad( this, cast(RoadGraph) gline.map_graph, edge, ps ); // FIXME: cast?!
	    }
	    
	return res;
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
    
    Vector2F cartesianToSFML( in WindowCoords from ) const
    {
	Vector2F res;
	
	res.x = from.x;
	res.y = to!real(window.size.y) - from.y;
	
	return res;
    }
    
    Vector2F[] cartesianToSFML( in WindowCoords[] from ) const
    {
	auto res = new Vector2F[ from.length ];
	
	foreach( i, c; from )
	    res[i] = cartesianToSFML( c );
	    
	return res;
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
