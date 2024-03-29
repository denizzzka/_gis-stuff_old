module pbf.road_graph;
import pbf.map_objects;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct Road {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(MapPolyline) polyline;
	///
	Nullable!(uint) type;
	///
	Nullable!(float) weight;
	///
	Nullable!(int) layer;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name polyline
		static if (is(MapPolyline == struct)) {
			ret ~= polyline.Serialize(1);
		} else static if (is(MapPolyline == enum)) {
			ret ~= toVarint(cast(int)polyline.get(),1);
		} else
			static assert(0,"Can't identify type `MapPolyline`");
		// Serialize member 2 Field Name type
		ret ~= toVarint(type.get(),2);
		// Serialize member 3 Field Name weight
		ret ~= toByteBlob(weight.get(),3);
		// Serialize member 4 Field Name layer
		ret ~= toVarint(layer.get(),4);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Road Deserialize(ref ubyte[] manip, bool isroot=true) {return Road(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name polyline
				static if (is(MapPolyline == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type MapPolyline");

					polyline = MapPolyline.Deserialize(input,false);
				} else static if (is(MapPolyline == enum)) {
					if (wireType == WireType.varint) {
						polyline = cast(MapPolyline)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type MapPolyline");

				} else
					static assert(0,
					  "Can't identify type `MapPolyline`");
			break;
			case 2:// Deserialize member 2 Field Name type
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				type = fromVarint!(uint)(input);
			break;
			case 3:// Deserialize member 3 Field Name weight
				if (wireType != WireType.fixed32)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type float");

				weight = fromByteBlob!(float)(input);
			break;
			case 4:// Deserialize member 4 Field Name layer
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int32");

				layer = fromVarint!(int)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (polyline.isNull) throw new Exception("Did not find a polyline in the message parse.");
		if (type.isNull) throw new Exception("Did not find a type in the message parse.");
		if (weight.isNull) throw new Exception("Did not find a weight in the message parse.");
		if (layer.isNull) throw new Exception("Did not find a layer in the message parse.");
	}

	void MergeFrom(Road merger) {
		if (!merger.polyline.isNull) polyline = merger.polyline;
		if (!merger.type.isNull) type = merger.type;
		if (!merger.weight.isNull) weight = merger.weight;
		if (!merger.layer.isNull) layer = merger.layer;
	}

	static Road opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
