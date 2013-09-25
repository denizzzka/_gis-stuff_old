module pbf.compressed_array;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct Compressed_Array {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(uint) items_num;
	///
	Nullable!(uint[]) keys_indexes;
	///
	Nullable!(ubyte[]) storage;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name items_num
		ret ~= toVarint(items_num.get(),1);
		// Serialize member 2 Field Name keys_indexes
		if(!keys_indexes.isNull)
		foreach(iter;keys_indexes.get()) {
			ret ~= toVarint(iter,2);
		}
		// Serialize member 3 Field Name storage
		ret ~= toByteString(storage.get(),3);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,WireType.lenDelimited)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Compressed_Array Deserialize(ref ubyte[] manip, bool isroot=true) {return Compressed_Array(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name items_num
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				items_num = fromVarint!(uint)(input);
			break;
			case 2:// Deserialize member 2 Field Name keys_indexes
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				if(keys_indexes.isNull) keys_indexes = new uint[](0);
				keys_indexes ~= fromVarint!(uint)(input);
			break;
			case 3:// Deserialize member 3 Field Name storage
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
		if (items_num.isNull) throw new Exception("Did not find a items_num in the message parse.");
		if (storage.isNull) throw new Exception("Did not find a storage in the message parse.");
	}

	void MergeFrom(Compressed_Array merger) {
		if (!merger.items_num.isNull) items_num = merger.items_num;
		if (!merger.keys_indexes.isNull) keys_indexes ~= merger.keys_indexes;
		if (!merger.storage.isNull) storage = merger.storage;
	}

	static Compressed_Array opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
