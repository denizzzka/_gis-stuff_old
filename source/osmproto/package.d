module osmproto;

import dproto.dproto;

//~ mixin ProtocolBuffer!"fileformat.proto";
//~ mixin ProtocolBuffer!"osmformat.proto";

import dproto.imports;
mixin(ParseProtoSchema("<none>", `option dproto_reserved_fmt = "%s_"; ` ~ import("fileformat.proto")).toD());
mixin(ParseProtoSchema("<none>", `option dproto_reserved_fmt = "%s_"; ` ~ import("osmformat.proto")).toD());
