module map_objects;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct MapCoords {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(long) lon;
	///
	Nullable!(long) lat;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name lon
		ret ~= toVarint(lon.get(),1);
		// Serialize member 2 Field Name lat
		ret ~= toVarint(lat.get(),2);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static MapCoords Deserialize(ref ubyte[] manip, bool isroot=true) {return MapCoords(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name lon
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				lon = fromVarint!(long)(input);
			break;
			case 2:// Deserialize member 2 Field Name lat
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				lat = fromVarint!(long)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (lon.isNull) throw new Exception("Did not find a lon in the message parse.");
		if (lat.isNull) throw new Exception("Did not find a lat in the message parse.");
	}

	void MergeFrom(MapCoords merger) {
		if (!merger.lon.isNull) lon = merger.lon;
		if (!merger.lat.isNull) lat = merger.lat;
	}

	static MapCoords opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct MapPolyline {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(MapCoords[]) coords_delta;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name coords_delta
		if(!coords_delta.isNull)
		foreach(iter;coords_delta.get()) {
			static if (is(MapCoords == struct)) {
				ret ~= iter.Serialize(1);
			} else static if (is(MapCoords == enum)) {
				ret ~= toVarint(cast(int)iter,1);
			} else
				static assert(0,"Can't identify type `MapCoords`");
		}
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static MapPolyline Deserialize(ref ubyte[] manip, bool isroot=true) {return MapPolyline(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name coords_delta
				static if (is(MapCoords == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type MapCoords");

					if(coords_delta.isNull) coords_delta = new MapCoords[](0);
					coords_delta ~= MapCoords.Deserialize(input,false);
				} else static if (is(MapCoords == enum)) {
					if (wireType == WireType.varint) {
						if(coords_delta.isNull) coords_delta = new MapCoords[](0);
						coords_delta ~= cast(MapCoords)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(coords_delta.isNull) coords_delta = new MapCoords[](0);
						coords_delta ~=
						   fromPacked!(MapCoords,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type MapCoords");

				} else
					static assert(0,
					  "Can't identify type `MapCoords`");
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(MapPolyline merger) {
		if (!merger.coords_delta.isNull) coords_delta ~= merger.coords_delta;
	}

	static MapPolyline opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
