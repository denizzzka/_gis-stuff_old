module pbf;

import dproto.dproto;

mixin ProtocolBuffer!"map_objects.proto";
mixin ProtocolBuffer!"compressed_array.proto";
mixin ProtocolBuffer!"digraph_compressed.proto";
mixin ProtocolBuffer!"undirected_graph_compressed.proto";
