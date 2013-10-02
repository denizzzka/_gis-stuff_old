module pbf.region;
import pbf.map_objects;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct Layer {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(Box) boundary;
	///
	Nullable!(ubyte[]) points_storage;
	///
	Nullable!(ubyte[]) lines_rtree;
	///
	Nullable!(ubyte[]) road_graph;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name boundary
		static if (is(Box == struct)) {
			ret ~= boundary.Serialize(1);
		} else static if (is(Box == enum)) {
			ret ~= toVarint(cast(int)boundary.get(),1);
		} else
			static assert(0,"Can't identify type `Box`");
		// Serialize member 2 Field Name points_storage
		if (!points_storage.isNull) ret ~= toByteString(points_storage.get(),2);
		// Serialize member 3 Field Name lines_rtree
		if (!lines_rtree.isNull) ret ~= toByteString(lines_rtree.get(),3);
		// Serialize member 4 Field Name road_graph
		if (!road_graph.isNull) ret ~= toByteString(road_graph.get(),4);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Layer Deserialize(ref ubyte[] manip, bool isroot=true) {return Layer(manip,isroot);}
	this(ref ubyte[] manip,bool isroot=true) {
		ubyte[] input = manip;
		// cut apart the input string
		if (!isroot) {
			uint len = fromVarint!(uint)(manip);
			input = manip[0..len];
			manip = manip[len..$];
		}
		while(input.length) {
			int header = fromVarint!(int)(input);
			auto wireType = getWireType(header);
			switch(getFieldNumber(header)) {
			case 1:// Deserialize member 1 Field Name boundary
				static if (is(Box == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Box");

					boundary = Box.Deserialize(input,false);
				} else static if (is(Box == enum)) {
					if (wireType == WireType.varint) {
						boundary = cast(Box)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Box");

				} else
					static assert(0,
					  "Can't identify type `Box`");
			break;
			case 2:// Deserialize member 2 Field Name points_storage
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				points_storage =
				   fromByteString!(ubyte[])(input);
			break;
			case 3:// Deserialize member 3 Field Name lines_rtree
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				lines_rtree =
				   fromByteString!(ubyte[])(input);
			break;
			case 4:// Deserialize member 4 Field Name road_graph
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				road_graph =
				   fromByteString!(ubyte[])(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (boundary.isNull) throw new Exception("Did not find a boundary in the message parse.");
	}

	void MergeFrom(Layer merger) {
		if (!merger.boundary.isNull) boundary = merger.boundary;
		if (!merger.points_storage.isNull) points_storage = merger.points_storage;
		if (!merger.lines_rtree.isNull) lines_rtree = merger.lines_rtree;
		if (!merger.road_graph.isNull) road_graph = merger.road_graph;
	}

	static Layer opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct MapRegion {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(ubyte[]) file_id;
	///
	Nullable!(Box) boundary;
	///
	Nullable!(ubyte[]) line_graph;
	///
	Nullable!(Layer[]) layers;
	///
	Nullable!(ubyte[]) areas;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name file_id
		ret ~= toByteString(file_id.get(),1);
		// Serialize member 2 Field Name boundary
		static if (is(Box == struct)) {
			ret ~= boundary.Serialize(2);
		} else static if (is(Box == enum)) {
			ret ~= toVarint(cast(int)boundary.get(),2);
		} else
			static assert(0,"Can't identify type `Box`");
		// Serialize member 3 Field Name line_graph
		if (!line_graph.isNull) ret ~= toByteString(line_graph.get(),3);
		// Serialize member 4 Field Name layers
		if(!layers.isNull)
		foreach(iter;layers.get()) {
			static if (is(Layer == struct)) {
				ret ~= iter.Serialize(4);
			} else static if (is(Layer == enum)) {
				ret ~= toVarint(cast(int)iter,4);
			} else
				static assert(0,"Can't identify type `Layer`");
		}
		// Serialize member 5 Field Name areas
		if (!areas.isNull) ret ~= toByteString(areas.get(),5);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static MapRegion Deserialize(ref ubyte[] manip, bool isroot=true) {return MapRegion(manip,isroot);}
	this(ref ubyte[] manip,bool isroot=true) {
		ubyte[] input = manip;
		// cut apart the input string
		if (!isroot) {
			uint len = fromVarint!(uint)(manip);
			input = manip[0..len];
			manip = manip[len..$];
		}
		while(input.length) {
			int header = fromVarint!(int)(input);
			auto wireType = getWireType(header);
			switch(getFieldNumber(header)) {
			case 1:// Deserialize member 1 Field Name file_id
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				file_id =
				   fromByteString!(ubyte[])(input);
			break;
			case 2:// Deserialize member 2 Field Name boundary
				static if (is(Box == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Box");

					boundary = Box.Deserialize(input,false);
				} else static if (is(Box == enum)) {
					if (wireType == WireType.varint) {
						boundary = cast(Box)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Box");

				} else
					static assert(0,
					  "Can't identify type `Box`");
			break;
			case 3:// Deserialize member 3 Field Name line_graph
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				line_graph =
				   fromByteString!(ubyte[])(input);
			break;
			case 4:// Deserialize member 4 Field Name layers
				static if (is(Layer == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Layer");

					if(layers.isNull) layers = new Layer[](0);
					layers ~= Layer.Deserialize(input,false);
				} else static if (is(Layer == enum)) {
					if (wireType == WireType.varint) {
						if(layers.isNull) layers = new Layer[](0);
						layers ~= cast(Layer)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(layers.isNull) layers = new Layer[](0);
						layers ~=
						   fromPacked!(Layer,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Layer");

				} else
					static assert(0,
					  "Can't identify type `Layer`");
			break;
			case 5:// Deserialize member 5 Field Name areas
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				areas =
				   fromByteString!(ubyte[])(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (file_id.isNull) throw new Exception("Did not find a file_id in the message parse.");
		if (boundary.isNull) throw new Exception("Did not find a boundary in the message parse.");
	}

	void MergeFrom(MapRegion merger) {
		if (!merger.file_id.isNull) file_id = merger.file_id;
		if (!merger.boundary.isNull) boundary = merger.boundary;
		if (!merger.line_graph.isNull) line_graph = merger.line_graph;
		if (!merger.layers.isNull) layers ~= merger.layers;
		if (!merger.areas.isNull) areas = merger.areas;
	}

	static MapRegion opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
