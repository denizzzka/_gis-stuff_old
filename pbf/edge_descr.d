module pbf.edge_descr;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct EdgeDescr {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(uint) node;
	///
	Nullable!(uint) edge;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name node
		ret ~= toVarint(node.get(),1);
		// Serialize member 2 Field Name edge
		ret ~= toVarint(edge.get(),2);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static EdgeDescr Deserialize(ref ubyte[] manip, bool isroot=true) {return EdgeDescr(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name node
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				node = fromVarint!(uint)(input);
			break;
			case 2:// Deserialize member 2 Field Name edge
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				edge = fromVarint!(uint)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (node.isNull) throw new Exception("Did not find a node in the message parse.");
		if (edge.isNull) throw new Exception("Did not find a edge in the message parse.");
	}

	void MergeFrom(EdgeDescr merger) {
		if (!merger.node.isNull) node = merger.node;
		if (!merger.edge.isNull) edge = merger.edge;
	}

	static EdgeDescr opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
