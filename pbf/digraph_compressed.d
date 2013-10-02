module pbf.digraph_compressed;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct Edge {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(uint) to_node_idx;
	///
	Nullable!(ubyte[]) payload;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name to_node_idx
		ret ~= toVarint(to_node_idx.get(),1);
		// Serialize member 2 Field Name payload
		ret ~= toByteString(payload.get(),2);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Edge Deserialize(ref ubyte[] manip, bool isroot=true) {return Edge(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name to_node_idx
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				to_node_idx = fromVarint!(uint)(input);
			break;
			case 2:// Deserialize member 2 Field Name payload
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				payload =
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
		if (to_node_idx.isNull) throw new Exception("Did not find a to_node_idx in the message parse.");
		if (payload.isNull) throw new Exception("Did not find a payload in the message parse.");
	}

	void MergeFrom(Edge merger) {
		if (!merger.to_node_idx.isNull) to_node_idx = merger.to_node_idx;
		if (!merger.payload.isNull) payload = merger.payload;
	}

	static Edge opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct Node {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(ubyte[]) payload;
	///
	Nullable!(Edge[]) edges;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name payload
		ret ~= toByteString(payload.get(),1);
		// Serialize member 2 Field Name edges
		if(!edges.isNull)
		foreach(iter;edges.get()) {
			static if (is(Edge == struct)) {
				ret ~= iter.Serialize(2);
			} else static if (is(Edge == enum)) {
				ret ~= toVarint(cast(int)iter,2);
			} else
				static assert(0,"Can't identify type `Edge`");
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
	static Node Deserialize(ref ubyte[] manip, bool isroot=true) {return Node(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name payload
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				payload =
				   fromByteString!(ubyte[])(input);
			break;
			case 2:// Deserialize member 2 Field Name edges
				static if (is(Edge == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Edge");

					if(edges.isNull) edges = new Edge[](0);
					edges ~= Edge.Deserialize(input,false);
				} else static if (is(Edge == enum)) {
					if (wireType == WireType.varint) {
						if(edges.isNull) edges = new Edge[](0);
						edges ~= cast(Edge)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(edges.isNull) edges = new Edge[](0);
						edges ~=
						   fromPacked!(Edge,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Edge");

				} else
					static assert(0,
					  "Can't identify type `Edge`");
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (payload.isNull) throw new Exception("Did not find a payload in the message parse.");
	}

	void MergeFrom(Node merger) {
		if (!merger.payload.isNull) payload = merger.payload;
		if (!merger.edges.isNull) edges ~= merger.edges;
	}

	static Node opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct DirectedGraph {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(Node[]) nodes;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name nodes
		if(!nodes.isNull)
		foreach(iter;nodes.get()) {
			static if (is(Node == struct)) {
				ret ~= iter.Serialize(1);
			} else static if (is(Node == enum)) {
				ret ~= toVarint(cast(int)iter,1);
			} else
				static assert(0,"Can't identify type `Node`");
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
	static DirectedGraph Deserialize(ref ubyte[] manip, bool isroot=true) {return DirectedGraph(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name nodes
				static if (is(Node == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Node");

					if(nodes.isNull) nodes = new Node[](0);
					nodes ~= Node.Deserialize(input,false);
				} else static if (is(Node == enum)) {
					if (wireType == WireType.varint) {
						if(nodes.isNull) nodes = new Node[](0);
						nodes ~= cast(Node)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(nodes.isNull) nodes = new Node[](0);
						nodes ~=
						   fromPacked!(Node,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Node");

				} else
					static assert(0,
					  "Can't identify type `Node`");
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

	void MergeFrom(DirectedGraph merger) {
		if (!merger.nodes.isNull) nodes ~= merger.nodes;
	}

	static DirectedGraph opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
