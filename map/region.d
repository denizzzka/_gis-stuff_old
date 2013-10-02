module map.region.region;

import map.map: MapCoords, BBox, MBBox, toMBBox;
import math.rtree2d.ptrs;
import math.rtree2d.array;
import map.objects_properties: LineClass;
static import cat = config.categories;
import map.line_graph;
import map.road_graph;
import map.map_graph: cutOnCrossings;
import map.area: Area;
static import config.map;
static import pbf = pbf.region;


struct Point
{
    private
    {
        MapCoords _coords;
        cat.Point _type;
        string _tags;
    }
    
    this( in MapCoords coords, in cat.Point type, in string tags )
    {
        _coords = coords;
        _type = type;
        _tags = tags;
    }
    
    @disable this();
    
    MapCoords coords() const
    {
        return _coords;
    }
    
    string tags() const
    {
        return _tags;
    }
    
    cat.Point type() const
    {
        return _type;
    }
}

alias RTreePtrs!(BBox, Point) PointsStorage; // TODO: 2D-Tree points storage

void addPoint( PointsStorage storage, Point point )
{
    storage.addObject( point.coords.getBBox, point );
}

struct AnyLineDescriptor
{
    LineClass line_class;
    
    union
    {
        LineGraph.EdgeDescr line;
        RoadGraph.EdgeDescr road;
        Area area;
    }
    
    // TODO: need to implement real compression
    ubyte[] compress() const
    {
        ubyte res[] = (cast (ubyte*) &this) [ 0 .. this.sizeof ];
        return res;
    }
    
    // TODO: need to implement real compression
    size_t decompress( inout ubyte* storage )
    {
        ubyte* this_ptr = cast (ubyte*) &this;
        this_ptr[ 0 .. this.sizeof] = storage[ 0 .. this.sizeof ].dup[0 .. this.sizeof];
        
        return this.sizeof;
    }
}

private alias RTreePtrs!(BBox, AnyLineDescriptor) LinesRTree;
alias RTreeArray!( LinesRTree ) LinesRTree_array;

class Region
{
    Layer[5] layers;
    LineGraphCompressed _line_graph;
    Area[] areas;
    
    this()
    {
        foreach( ref c; layers )
            c.init;
    }
    
    void moveInfoIntoRTreeArray()
    {
        foreach( ref l; layers )
        {
            l._lines = new LinesRTree_array( l.lines );
            delete l.lines;
        }
    }
    
    MBBox boundary() const
    {
        return layers[0].boundary; // FIXME
    }
    
    void addPoint( Point point )
    {
        size_t layer_num;
        
        with( cat.Point )
        switch( point.type )
        {
            case POLICE:
            case SHOP:
            case LEISURE:
                layer_num = 0;
                break;
                
            default:
                layer_num = layers.length - 1;
                break;
        }
        
        layers[layer_num].POI.addPoint( point );
    }
    
    void fillLines( Prepare )( Prepare prepared )
    {
        auto line_graph = new LineGraph;
        
        LineGraph.NodeDescr[ulong] already_stored;
        
        foreach( i, ref unused; layers )
        {
            auto epsilon = config.converter.layersGeneralization[i];
            auto cutted = cutOnCrossings( prepared.lines_to_store[i] );
            
            foreach( descr; cutted )
            {
                if( epsilon )
                    descr.generalize( epsilon );
                
                auto descriptor = line_graph.addPolyline( descr, already_stored );
                
                auto bbox = line_graph.getBoundary( descriptor );
                
                AnyLineDescriptor any = {
                    line_class: LineClass.POLYLINE,
                    line: descriptor
                };
                
                // be careful: this line uses uncompressed graph class
                layers[i].lines.addObject( bbox, any );
            }
        }
        
        this._line_graph = new LineGraphCompressed( line_graph );
    }
    
    void fillRoads( Prepare )( Prepare prepared )
    {
        foreach( i, ref layer; layers )
        {
            RoadGraph g = new RoadGraph;
            
            RoadGraph.NodeDescr[ulong] already_stored;
            
            auto epsilon = config.converter.layersGeneralization[i];
            auto cutted = cutOnCrossings( prepared.lines_to_store[i] );
            
            foreach( descr; cutted )
            {
                if( epsilon )
                    descr.generalize( epsilon );
                
                g.addPolyline( descr, already_stored );
            }
            
            g.sortEdgesByReducingRank;
            
            layer.road_graph = new RoadGraphCompressed(g);
            
            void addEdgeToRtree( RoadGraphCompressed.EdgeDescr descr )
            {
                auto bbox = g.getBoundary( descr );
                
                AnyLineDescriptor any = {
                    line_class: LineClass.ROAD,
                };
                any.road = descr;
                
                layer.lines.addObject( bbox, any );
            }
            
            // be careful: this line uses uncompressed graph class
            g.forAllEdges( &addEdgeToRtree );
            
        }
    }
    
    void fillAreas( Area[] areas )
    {
        this.areas = areas;
        
        foreach( area; areas )
        {
            auto to_layers = config.map.polylines.getProperty( area._properties.type ).layers;
            
            foreach( n; to_layers )
            {
                auto epsilon = config.converter.layersGeneralization[n];
                
                if( epsilon )
                    area.generalize( epsilon );
                
                AnyLineDescriptor any = {
                    line_class: LineClass.AREA
                };
                any.area = area;
                
                layers[n].lines.addObject( area.getBoundary, any );
            }
        }
    }
    
    void dumpToFile(inout string filename)
    {
        pbf.MapRegion res;
        
        res.file_id = cast(ubyte[]) "6dFile!Map";
    }
}

struct Layer
{
    PointsStorage POI;
    LinesRTree lines;
    LinesRTree_array _lines;
    
    RoadGraphCompressed road_graph;
    
    void init()
    {
        POI = new PointsStorage( 4, 1 );
        lines = new LinesRTree( 4, 1 );
    }
    
    MBBox boundary() const
    {
        return POI.getBoundary.getCircumscribed( POI.getBoundary ).toMBBox; // FIXME
    }
}

class TPrepareLines( Descr )
{
    private Descr[][ Region.layers.length ] lines_to_store;
    
    void addLine( Descr line_descr )
    {
        auto to_layers = config.map.polylines.getProperty( line_descr.properties.type ).layers;
        
        foreach( n; to_layers )
            lines_to_store[n] ~= line_descr;
    }
}
