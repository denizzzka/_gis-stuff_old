module pbf.undirected_graph_compressed;
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
	Nullable!(uint) from_node_idx;
	///
	Nullable!(uint) to_node_idx;
	///
	Nullable!(ubyte[]) payload;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name from_node_idx
		ret ~= toVarint(from_node_idx.get(),1);
		// Serialize member 2 Field Name to_node_idx
		ret ~= toVarint(to_node_idx.get(),2);
		// Serialize member 3 Field Name payload
		ret ~= toByteString(payload.get(),3);
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
			case 1:// Deserialize member 1 Field Name from_node_idx
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				from_node_idx = fromVarint!(uint)(input);
			break;
			case 2:// Deserialize member 2 Field Name to_node_idx
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				to_node_idx = fromVarint!(uint)(input);
			break;
			case 3:// Deserialize member 3 Field Name payload
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
		if (from_node_idx.isNull) throw new Exception("Did not find a from_node_idx in the message parse.");
		if (to_node_idx.isNull) throw new Exception("Did not find a to_node_idx in the message parse.");
		if (payload.isNull) throw new Exception("Did not find a payload in the message parse.");
	}

	void MergeFrom(Edge merger) {
		if (!merger.from_node_idx.isNull) from_node_idx = merger.from_node_idx;
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
	Nullable!(uint[]) global_edge_idx;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name payload
		ret ~= toByteString(payload.get(),1);
		// Serialize member 2 Field Name global_edge_idx
		if(!global_edge_idx.isNull)
		foreach(iter;global_edge_idx.get()) {
			ret ~= toVarint(iter,2);
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
			case 2:// Deserialize member 2 Field Name global_edge_idx
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				if(global_edge_idx.isNull) global_edge_idx = new uint[](0);
				global_edge_idx ~= fromVarint!(uint)(input);
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
		if (!merger.global_edge_idx.isNull) global_edge_idx ~= merger.global_edge_idx;
	}

	static Node opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct UndirectedGraph {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(ubyte[]) nodes;
	///
	Nullable!(ubyte[]) global_edges;

	ubyte[] Serialize(int field = -1) const {
		ubyte[] ret;
		// Serialize member 1 Field Name nodes
		ret ~= toByteString(nodes.get(),1);
		// Serialize member 2 Field Name global_edges
		ret ~= toByteString(global_edges.get(),2);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static UndirectedGraph Deserialize(ref ubyte[] manip, bool isroot=true) {return UndirectedGraph(manip,isroot);}
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
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				nodes =
				   fromByteString!(ubyte[])(input);
			break;
			case 2:// Deserialize member 2 Field Name global_edges
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				global_edges =
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
		if (nodes.isNull) throw new Exception("Did not find a nodes in the message parse.");
		if (global_edges.isNull) throw new Exception("Did not find a global_edges in the message parse.");
	}

	void MergeFrom(UndirectedGraph merger) {
		if (!merger.nodes.isNull) nodes = merger.nodes;
		if (!merger.global_edges.isNull) global_edges = merger.global_edges;
	}

	static UndirectedGraph opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
