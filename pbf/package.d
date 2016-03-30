module pbf;

import dproto.dproto;

mixin ProtocolBuffer!"compressed_array.proto";
mixin ProtocolBuffer!"digraph_compressed.proto";
mixin ProtocolBuffer!"line_graph.proto";
mixin ProtocolBuffer!"map_objects.proto";
mixin ProtocolBuffer!"region.proto";
mixin ProtocolBuffer!"road_graph.proto";
mixin ProtocolBuffer!"undirected_graph_compressed.proto";
