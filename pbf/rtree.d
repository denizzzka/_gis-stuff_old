module pbf.rtree;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct RTree {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(uint) depth;
	///
	Nullable!(ubyte[]) storage;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name depth
		ret ~= toVarint(depth.get(),1);
		// Serialize member 2 Field Name storage
		ret ~= toByteString(storage.get(),2);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static RTree Deserialize(ref ubyte[] manip, bool isroot=true) {return RTree(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name depth
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				depth = fromVarint!(uint)(input);
			break;
			case 2:// Deserialize member 2 Field Name storage
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				storage =
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
		if (depth.isNull) throw new Exception("Did not find a depth in the message parse.");
		if (storage.isNull) throw new Exception("Did not find a storage in the message parse.");
	}

	void MergeFrom(RTree merger) {
		if (!merger.depth.isNull) depth = merger.depth;
		if (!merger.storage.isNull) storage = merger.storage;
	}

	static RTree opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
