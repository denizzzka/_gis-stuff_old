module math.graph.edge_descr_pbf;

import pbf = pbf.edge_descr;


pbf.EdgeDescr toPbf( Descr )( inout Descr descr )
{
    pbf.EdgeDescr res;
    
    res.node = descr.node.idx;
    res.edge = descr.idx;
    
    return res;
}

Descr fromPbf( Descr )( inout pbf.EdgeDescr pbfDescr )
{
    Descr res;
    
    res.node.idx = pbfDescr.node;
    res.idx = pbfDescr.edge;
    
    return res;
}
