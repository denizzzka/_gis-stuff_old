module osmproto.osmformat;
import ProtocolBuffer.conversion.pbbinary;
import std.conv;
import std.typecons;

string makeString(T)(T v) {
	return to!string(v);
}
struct HeaderBlock {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(HeaderBBox) bbox;
	///
	Nullable!(string[]) required_features;
	///
	Nullable!(string[]) optional_features;
	///
	Nullable!(string) writingprogram;
	///
	Nullable!(string) source;
	/// From the bbox field.

	/// replication timestamp, expressed in seconds since the epoch, 
	/// otherwise the same value as in the "timestamp=..." field
	/// in the state.txt file used by Osmosis
	Nullable!(long) osmosis_replication_timestamp;
	/// replication sequence number (sequenceNumber in state.txt)
	Nullable!(long) osmosis_replication_sequence_number;
	/// replication base URL (from Osmosis' configuration.txt file)
	Nullable!(string) osmosis_replication_base_url;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name bbox
		static if (is(HeaderBBox == struct)) {
			ret ~= bbox.Serialize(1);
		} else static if (is(HeaderBBox == enum)) {
			if (!bbox.isNull) ret ~= toVarint(cast(int)bbox.get(),1);
		} else
			static assert(0,"Can't identify type `HeaderBBox`");
		// Serialize member 4 Field Name required_features
		if(!required_features.isNull)
		foreach(iter;required_features.get()) {
			ret ~= toByteString(iter,4);
		}
		// Serialize member 5 Field Name optional_features
		if(!optional_features.isNull)
		foreach(iter;optional_features.get()) {
			ret ~= toByteString(iter,5);
		}
		// Serialize member 16 Field Name writingprogram
		if (!writingprogram.isNull) ret ~= toByteString(writingprogram.get(),16);
		// Serialize member 17 Field Name source
		if (!source.isNull) ret ~= toByteString(source.get(),17);
		// Serialize member 32 Field Name osmosis_replication_timestamp
		if (!osmosis_replication_timestamp.isNull) ret ~= toVarint(osmosis_replication_timestamp.get(),32);
		// Serialize member 33 Field Name osmosis_replication_sequence_number
		if (!osmosis_replication_sequence_number.isNull) ret ~= toVarint(osmosis_replication_sequence_number.get(),33);
		// Serialize member 34 Field Name osmosis_replication_base_url
		if (!osmosis_replication_base_url.isNull) ret ~= toByteString(osmosis_replication_base_url.get(),34);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static HeaderBlock Deserialize(ref ubyte[] manip, bool isroot=true) {return HeaderBlock(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name bbox
				static if (is(HeaderBBox == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type HeaderBBox");

					bbox = HeaderBBox.Deserialize(input,false);
				} else static if (is(HeaderBBox == enum)) {
					if (wireType == WireType.varint) {
						bbox = cast(HeaderBBox)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type HeaderBBox");

				} else
					static assert(0,
					  "Can't identify type `HeaderBBox`");
			break;
			case 4:// Deserialize member 4 Field Name required_features
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type string");

				if(required_features.isNull) required_features = new string[](0);
				required_features ~=
				   fromByteString!(string)(input);
			break;
			case 5:// Deserialize member 5 Field Name optional_features
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type string");

				if(optional_features.isNull) optional_features = new string[](0);
				optional_features ~=
				   fromByteString!(string)(input);
			break;
			case 16:// Deserialize member 16 Field Name writingprogram
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type string");

				writingprogram =
				   fromByteString!(string)(input);
			break;
			case 17:// Deserialize member 17 Field Name source
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type string");

				source =
				   fromByteString!(string)(input);
			break;
			case 32:// Deserialize member 32 Field Name osmosis_replication_timestamp
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				osmosis_replication_timestamp = fromVarint!(long)(input);
			break;
			case 33:// Deserialize member 33 Field Name osmosis_replication_sequence_number
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				osmosis_replication_sequence_number = fromVarint!(long)(input);
			break;
			case 34:// Deserialize member 34 Field Name osmosis_replication_base_url
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type string");

				osmosis_replication_base_url =
				   fromByteString!(string)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(HeaderBlock merger) {
		if (!merger.bbox.isNull) bbox = merger.bbox;
		if (!merger.required_features.isNull) required_features ~= merger.required_features;
		if (!merger.optional_features.isNull) optional_features ~= merger.optional_features;
		if (!merger.writingprogram.isNull) writingprogram = merger.writingprogram;
		if (!merger.source.isNull) source = merger.source;
		if (!merger.osmosis_replication_timestamp.isNull) osmosis_replication_timestamp = merger.osmosis_replication_timestamp;
		if (!merger.osmosis_replication_sequence_number.isNull) osmosis_replication_sequence_number = merger.osmosis_replication_sequence_number;
		if (!merger.osmosis_replication_base_url.isNull) osmosis_replication_base_url = merger.osmosis_replication_base_url;
	}

	static HeaderBlock opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct HeaderBBox {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(long) left;
	///
	Nullable!(long) right;
	///
	Nullable!(long) top;
	///
	Nullable!(long) bottom;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name left
		ret ~= toSInt(left.get(),1);
		// Serialize member 2 Field Name right
		ret ~= toSInt(right.get(),2);
		// Serialize member 3 Field Name top
		ret ~= toSInt(top.get(),3);
		// Serialize member 4 Field Name bottom
		ret ~= toSInt(bottom.get(),4);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static HeaderBBox Deserialize(ref ubyte[] manip, bool isroot=true) {return HeaderBBox(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name left
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				left = fromSInt!(long)(input);
			break;
			case 2:// Deserialize member 2 Field Name right
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				right = fromSInt!(long)(input);
			break;
			case 3:// Deserialize member 3 Field Name top
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				top = fromSInt!(long)(input);
			break;
			case 4:// Deserialize member 4 Field Name bottom
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				bottom = fromSInt!(long)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (left.isNull) throw new Exception("Did not find a left in the message parse.");
		if (right.isNull) throw new Exception("Did not find a right in the message parse.");
		if (top.isNull) throw new Exception("Did not find a top in the message parse.");
		if (bottom.isNull) throw new Exception("Did not find a bottom in the message parse.");
	}

	void MergeFrom(HeaderBBox merger) {
		if (!merger.left.isNull) left = merger.left;
		if (!merger.right.isNull) right = merger.right;
		if (!merger.top.isNull) top = merger.top;
		if (!merger.bottom.isNull) bottom = merger.bottom;
	}

	static HeaderBBox opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct PrimitiveBlock {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(StringTable) stringtable;
	///
	Nullable!(PrimitiveGroup[]) primitivegroup;
	/// Granularity, units of nanodegrees, used to store coordinates in this block
	Nullable!(int) granularity = 100;
	/// Offset value between the output coordinates coordinates and the granularity grid in unites of nanodegrees.
	Nullable!(long) lat_offset = 0;
	///
	Nullable!(long) lon_offset = 0;
	/// Granularity of dates, normally represented in units of milliseconds since the 1970 epoch.
	Nullable!(int) date_granularity = 1000;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name stringtable
		static if (is(StringTable == struct)) {
			ret ~= stringtable.Serialize(1);
		} else static if (is(StringTable == enum)) {
			ret ~= toVarint(cast(int)stringtable.get(),1);
		} else
			static assert(0,"Can't identify type `StringTable`");
		// Serialize member 2 Field Name primitivegroup
		if(!primitivegroup.isNull)
		foreach(iter;primitivegroup.get()) {
			static if (is(PrimitiveGroup == struct)) {
				ret ~= iter.Serialize(2);
			} else static if (is(PrimitiveGroup == enum)) {
				ret ~= toVarint(cast(int)iter,2);
			} else
				static assert(0,"Can't identify type `PrimitiveGroup`");
		}
		// Serialize member 17 Field Name granularity
		if (!granularity.isNull) ret ~= toVarint(granularity.get(),17);
		// Serialize member 19 Field Name lat_offset
		if (!lat_offset.isNull) ret ~= toVarint(lat_offset.get(),19);
		// Serialize member 20 Field Name lon_offset
		if (!lon_offset.isNull) ret ~= toVarint(lon_offset.get(),20);
		// Serialize member 18 Field Name date_granularity
		if (!date_granularity.isNull) ret ~= toVarint(date_granularity.get(),18);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static PrimitiveBlock Deserialize(ref ubyte[] manip, bool isroot=true) {return PrimitiveBlock(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name stringtable
				static if (is(StringTable == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type StringTable");

					stringtable = StringTable.Deserialize(input,false);
				} else static if (is(StringTable == enum)) {
					if (wireType == WireType.varint) {
						stringtable = cast(StringTable)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type StringTable");

				} else
					static assert(0,
					  "Can't identify type `StringTable`");
			break;
			case 2:// Deserialize member 2 Field Name primitivegroup
				static if (is(PrimitiveGroup == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type PrimitiveGroup");

					if(primitivegroup.isNull) primitivegroup = new PrimitiveGroup[](0);
					primitivegroup ~= PrimitiveGroup.Deserialize(input,false);
				} else static if (is(PrimitiveGroup == enum)) {
					if (wireType == WireType.varint) {
						if(primitivegroup.isNull) primitivegroup = new PrimitiveGroup[](0);
						primitivegroup ~= cast(PrimitiveGroup)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(primitivegroup.isNull) primitivegroup = new PrimitiveGroup[](0);
						primitivegroup ~=
						   fromPacked!(PrimitiveGroup,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type PrimitiveGroup");

				} else
					static assert(0,
					  "Can't identify type `PrimitiveGroup`");
			break;
			case 17:// Deserialize member 17 Field Name granularity
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int32");

				granularity = fromVarint!(int)(input);
			break;
			case 19:// Deserialize member 19 Field Name lat_offset
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				lat_offset = fromVarint!(long)(input);
			break;
			case 20:// Deserialize member 20 Field Name lon_offset
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				lon_offset = fromVarint!(long)(input);
			break;
			case 18:// Deserialize member 18 Field Name date_granularity
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int32");

				date_granularity = fromVarint!(int)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (stringtable.isNull) throw new Exception("Did not find a stringtable in the message parse.");
	}

	void MergeFrom(PrimitiveBlock merger) {
		if (!merger.stringtable.isNull) stringtable = merger.stringtable;
		if (!merger.primitivegroup.isNull) primitivegroup ~= merger.primitivegroup;
		if (!merger.granularity.isNull) granularity = merger.granularity;
		if (!merger.lat_offset.isNull) lat_offset = merger.lat_offset;
		if (!merger.lon_offset.isNull) lon_offset = merger.lon_offset;
		if (!merger.date_granularity.isNull) date_granularity = merger.date_granularity;
	}

	static PrimitiveBlock opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
///////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

/// Group of OSMPrimitives. All primitives in a group must be the same type.
struct PrimitiveGroup {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(Node[]) nodes;
	///
	Nullable!(DenseNodes) dense;
	///
	Nullable!(Way[]) ways;
	///
	Nullable!(Relation[]) relations;
	///
	Nullable!(ChangeSet[]) changesets;

	ubyte[] Serialize(int field = -1) {
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
		// Serialize member 2 Field Name dense
		static if (is(DenseNodes == struct)) {
			ret ~= dense.Serialize(2);
		} else static if (is(DenseNodes == enum)) {
			if (!dense.isNull) ret ~= toVarint(cast(int)dense.get(),2);
		} else
			static assert(0,"Can't identify type `DenseNodes`");
		// Serialize member 3 Field Name ways
		if(!ways.isNull)
		foreach(iter;ways.get()) {
			static if (is(Way == struct)) {
				ret ~= iter.Serialize(3);
			} else static if (is(Way == enum)) {
				ret ~= toVarint(cast(int)iter,3);
			} else
				static assert(0,"Can't identify type `Way`");
		}
		// Serialize member 4 Field Name relations
		if(!relations.isNull)
		foreach(iter;relations.get()) {
			static if (is(Relation == struct)) {
				ret ~= iter.Serialize(4);
			} else static if (is(Relation == enum)) {
				ret ~= toVarint(cast(int)iter,4);
			} else
				static assert(0,"Can't identify type `Relation`");
		}
		// Serialize member 5 Field Name changesets
		if(!changesets.isNull)
		foreach(iter;changesets.get()) {
			static if (is(ChangeSet == struct)) {
				ret ~= iter.Serialize(5);
			} else static if (is(ChangeSet == enum)) {
				ret ~= toVarint(cast(int)iter,5);
			} else
				static assert(0,"Can't identify type `ChangeSet`");
		}
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static PrimitiveGroup Deserialize(ref ubyte[] manip, bool isroot=true) {return PrimitiveGroup(manip,isroot);}
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
			case 2:// Deserialize member 2 Field Name dense
				static if (is(DenseNodes == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type DenseNodes");

					dense = DenseNodes.Deserialize(input,false);
				} else static if (is(DenseNodes == enum)) {
					if (wireType == WireType.varint) {
						dense = cast(DenseNodes)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type DenseNodes");

				} else
					static assert(0,
					  "Can't identify type `DenseNodes`");
			break;
			case 3:// Deserialize member 3 Field Name ways
				static if (is(Way == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Way");

					if(ways.isNull) ways = new Way[](0);
					ways ~= Way.Deserialize(input,false);
				} else static if (is(Way == enum)) {
					if (wireType == WireType.varint) {
						if(ways.isNull) ways = new Way[](0);
						ways ~= cast(Way)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(ways.isNull) ways = new Way[](0);
						ways ~=
						   fromPacked!(Way,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Way");

				} else
					static assert(0,
					  "Can't identify type `Way`");
			break;
			case 4:// Deserialize member 4 Field Name relations
				static if (is(Relation == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Relation");

					if(relations.isNull) relations = new Relation[](0);
					relations ~= Relation.Deserialize(input,false);
				} else static if (is(Relation == enum)) {
					if (wireType == WireType.varint) {
						if(relations.isNull) relations = new Relation[](0);
						relations ~= cast(Relation)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(relations.isNull) relations = new Relation[](0);
						relations ~=
						   fromPacked!(Relation,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Relation");

				} else
					static assert(0,
					  "Can't identify type `Relation`");
			break;
			case 5:// Deserialize member 5 Field Name changesets
				static if (is(ChangeSet == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type ChangeSet");

					if(changesets.isNull) changesets = new ChangeSet[](0);
					changesets ~= ChangeSet.Deserialize(input,false);
				} else static if (is(ChangeSet == enum)) {
					if (wireType == WireType.varint) {
						if(changesets.isNull) changesets = new ChangeSet[](0);
						changesets ~= cast(ChangeSet)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(changesets.isNull) changesets = new ChangeSet[](0);
						changesets ~=
						   fromPacked!(ChangeSet,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type ChangeSet");

				} else
					static assert(0,
					  "Can't identify type `ChangeSet`");
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(PrimitiveGroup merger) {
		if (!merger.nodes.isNull) nodes ~= merger.nodes;
		if (!merger.dense.isNull) dense = merger.dense;
		if (!merger.ways.isNull) ways ~= merger.ways;
		if (!merger.relations.isNull) relations ~= merger.relations;
		if (!merger.changesets.isNull) changesets ~= merger.changesets;
	}

	static PrimitiveGroup opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct StringTable {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(ubyte[][]) s;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name s
		if(!s.isNull)
		foreach(iter;s.get()) {
			ret ~= toByteString(iter,1);
		}
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static StringTable Deserialize(ref ubyte[] manip, bool isroot=true) {return StringTable(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name s
				if (wireType != WireType.lenDelimited)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bytes");

				if(s.isNull) s = new ubyte[][](0);
				s ~=
				   fromByteString!(ubyte[])(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(StringTable merger) {
		if (!merger.s.isNull) s ~= merger.s;
	}

	static StringTable opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct Info {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(int) version_ = -1;
	///
	Nullable!(long) timestamp;
	///
	Nullable!(long) changeset;
	///
	Nullable!(int) uid;
	///
	Nullable!(uint) user_sid;
	/// String IDs

	/// The visible flag is used to store history information. It indicates that
	/// the current object version has been created by a delete operation on the
	/// OSM API.
	/// When a writer sets this flag, it MUST add a required_features tag with
	/// value "HistoricalInformation" to the HeaderBlock.
	/// If this flag is not available for some object it MUST be assumed to be
	/// true if the file has the required_features tag "HistoricalInformation"
	/// set.
	Nullable!(bool) visible;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name version
		if (!version_.isNull) ret ~= toVarint(version_.get(),1);
		// Serialize member 2 Field Name timestamp
		if (!timestamp.isNull) ret ~= toVarint(timestamp.get(),2);
		// Serialize member 3 Field Name changeset
		if (!changeset.isNull) ret ~= toVarint(changeset.get(),3);
		// Serialize member 4 Field Name uid
		if (!uid.isNull) ret ~= toVarint(uid.get(),4);
		// Serialize member 5 Field Name user_sid
		if (!user_sid.isNull) ret ~= toVarint(user_sid.get(),5);
		// Serialize member 6 Field Name visible
		if (!visible.isNull) ret ~= toVarint(visible.get(),6);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Info Deserialize(ref ubyte[] manip, bool isroot=true) {return Info(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name version
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int32");

				version_ = fromVarint!(int)(input);
			break;
			case 2:// Deserialize member 2 Field Name timestamp
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				timestamp = fromVarint!(long)(input);
			break;
			case 3:// Deserialize member 3 Field Name changeset
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				changeset = fromVarint!(long)(input);
			break;
			case 4:// Deserialize member 4 Field Name uid
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int32");

				uid = fromVarint!(int)(input);
			break;
			case 5:// Deserialize member 5 Field Name user_sid
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type uint32");

				user_sid = fromVarint!(uint)(input);
			break;
			case 6:// Deserialize member 6 Field Name visible
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type bool");

				visible = fromVarint!(bool)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(Info merger) {
		if (!merger.version_.isNull) version_ = merger.version_;
		if (!merger.timestamp.isNull) timestamp = merger.timestamp;
		if (!merger.changeset.isNull) changeset = merger.changeset;
		if (!merger.uid.isNull) uid = merger.uid;
		if (!merger.user_sid.isNull) user_sid = merger.user_sid;
		if (!merger.visible.isNull) visible = merger.visible;
	}

	static Info opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct DenseInfo {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(int[]) version_;
	///
	Nullable!(long[]) timestamp;
	/// DELTA coded
	Nullable!(long[]) changeset;
	/// DELTA coded
	Nullable!(int[]) uid;
	/// DELTA coded
	Nullable!(int[]) user_sid;
	/// String IDs for usernames. DELTA coded

	/// The visible flag is used to store history information. It indicates that
	/// the current object version has been created by a delete operation on the
	/// OSM API.
	/// When a writer sets this flag, it MUST add a required_features tag with
	/// value "HistoricalInformation" to the HeaderBlock.
	/// If this flag is not available for some object it MUST be assumed to be
	/// true if the file has the required_features tag "HistoricalInformation"
	/// set.
	Nullable!(bool[]) visible;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name version
		if(!version_.isNull)
			ret ~= toPacked!(int[],toVarint)(version_,1);
		// Serialize member 2 Field Name timestamp
		if(!timestamp.isNull)
			ret ~= toPacked!(long[],toSInt)(timestamp,2);
		// Serialize member 3 Field Name changeset
		if(!changeset.isNull)
			ret ~= toPacked!(long[],toSInt)(changeset,3);
		// Serialize member 4 Field Name uid
		if(!uid.isNull)
			ret ~= toPacked!(int[],toSInt)(uid,4);
		// Serialize member 5 Field Name user_sid
		if(!user_sid.isNull)
			ret ~= toPacked!(int[],toSInt)(user_sid,5);
		// Serialize member 6 Field Name visible
		if(!visible.isNull)
			ret ~= toPacked!(bool[],toVarint)(visible,6);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static DenseInfo Deserialize(ref ubyte[] manip, bool isroot=true) {return DenseInfo(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name version
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type int32");

				if (wireType == WireType.lenDelimited) {
					if(version_.isNull) version_ = new int[](0);
					version_ ~=
					   fromPacked!(int,fromVarint!(int))(input);
					//Accept data even when not packed
				} else {
					if(version_.isNull) version_ = new int[](0);
					version_ ~= fromVarint!(int)(input);
				}
			break;
			case 2:// Deserialize member 2 Field Name timestamp
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(timestamp.isNull) timestamp = new long[](0);
					timestamp ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(timestamp.isNull) timestamp = new long[](0);
					timestamp ~= fromSInt!(long)(input);
				}
			break;
			case 3:// Deserialize member 3 Field Name changeset
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(changeset.isNull) changeset = new long[](0);
					changeset ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(changeset.isNull) changeset = new long[](0);
					changeset ~= fromSInt!(long)(input);
				}
			break;
			case 4:// Deserialize member 4 Field Name uid
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint32");

				if (wireType == WireType.lenDelimited) {
					if(uid.isNull) uid = new int[](0);
					uid ~=
					   fromPacked!(int,fromSInt!(int))(input);
					//Accept data even when not packed
				} else {
					if(uid.isNull) uid = new int[](0);
					uid ~= fromSInt!(int)(input);
				}
			break;
			case 5:// Deserialize member 5 Field Name user_sid
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint32");

				if (wireType == WireType.lenDelimited) {
					if(user_sid.isNull) user_sid = new int[](0);
					user_sid ~=
					   fromPacked!(int,fromSInt!(int))(input);
					//Accept data even when not packed
				} else {
					if(user_sid.isNull) user_sid = new int[](0);
					user_sid ~= fromSInt!(int)(input);
				}
			break;
			case 6:// Deserialize member 6 Field Name visible
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type bool");

				if (wireType == WireType.lenDelimited) {
					if(visible.isNull) visible = new bool[](0);
					visible ~=
					   fromPacked!(bool,fromVarint!(bool))(input);
					//Accept data even when not packed
				} else {
					if(visible.isNull) visible = new bool[](0);
					visible ~= fromVarint!(bool)(input);
				}
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(DenseInfo merger) {
		if (!merger.version_.isNull) version_ ~= merger.version_;
		if (!merger.timestamp.isNull) timestamp ~= merger.timestamp;
		if (!merger.changeset.isNull) changeset ~= merger.changeset;
		if (!merger.uid.isNull) uid ~= merger.uid;
		if (!merger.user_sid.isNull) user_sid ~= merger.user_sid;
		if (!merger.visible.isNull) visible ~= merger.visible;
	}

	static DenseInfo opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
/// THIS IS STUB DESIGN FOR CHANGESETS. NOT USED RIGHT NOW.
/// TODO:    REMOVE THIS?
struct ChangeSet {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(long) id;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name id
		ret ~= toVarint(id.get(),1);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static ChangeSet Deserialize(ref ubyte[] manip, bool isroot=true) {return ChangeSet(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name id
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				id = fromVarint!(long)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (id.isNull) throw new Exception("Did not find a id in the message parse.");
	}

	void MergeFrom(ChangeSet merger) {
		if (!merger.id.isNull) id = merger.id;
	}

	static ChangeSet opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct Node {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(long) id;
	/// Parallel arrays.
	Nullable!(uint[]) keys;
	/// String IDs.
	Nullable!(uint[]) vals;
	/// String IDs.
	Nullable!(Info) info;
	/// May be omitted in omitmeta
	Nullable!(long) lat;
	///
	Nullable!(long) lon;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name id
		ret ~= toSInt(id.get(),1);
		// Serialize member 2 Field Name keys
		if(!keys.isNull)
			ret ~= toPacked!(uint[],toVarint)(keys,2);
		// Serialize member 3 Field Name vals
		if(!vals.isNull)
			ret ~= toPacked!(uint[],toVarint)(vals,3);
		// Serialize member 4 Field Name info
		static if (is(Info == struct)) {
			ret ~= info.Serialize(4);
		} else static if (is(Info == enum)) {
			if (!info.isNull) ret ~= toVarint(cast(int)info.get(),4);
		} else
			static assert(0,"Can't identify type `Info`");
		// Serialize member 8 Field Name lat
		ret ~= toSInt(lat.get(),8);
		// Serialize member 9 Field Name lon
		ret ~= toSInt(lon.get(),9);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
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
			case 1:// Deserialize member 1 Field Name id
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				id = fromSInt!(long)(input);
			break;
			case 2:// Deserialize member 2 Field Name keys
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type uint32");

				if (wireType == WireType.lenDelimited) {
					if(keys.isNull) keys = new uint[](0);
					keys ~=
					   fromPacked!(uint,fromVarint!(uint))(input);
					//Accept data even when not packed
				} else {
					if(keys.isNull) keys = new uint[](0);
					keys ~= fromVarint!(uint)(input);
				}
			break;
			case 3:// Deserialize member 3 Field Name vals
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type uint32");

				if (wireType == WireType.lenDelimited) {
					if(vals.isNull) vals = new uint[](0);
					vals ~=
					   fromPacked!(uint,fromVarint!(uint))(input);
					//Accept data even when not packed
				} else {
					if(vals.isNull) vals = new uint[](0);
					vals ~= fromVarint!(uint)(input);
				}
			break;
			case 4:// Deserialize member 4 Field Name info
				static if (is(Info == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Info");

					info = Info.Deserialize(input,false);
				} else static if (is(Info == enum)) {
					if (wireType == WireType.varint) {
						info = cast(Info)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Info");

				} else
					static assert(0,
					  "Can't identify type `Info`");
			break;
			case 8:// Deserialize member 8 Field Name lat
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				lat = fromSInt!(long)(input);
			break;
			case 9:// Deserialize member 9 Field Name lon
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type sint64");

				lon = fromSInt!(long)(input);
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (id.isNull) throw new Exception("Did not find a id in the message parse.");
		if (lat.isNull) throw new Exception("Did not find a lat in the message parse.");
		if (lon.isNull) throw new Exception("Did not find a lon in the message parse.");
	}

	void MergeFrom(Node merger) {
		if (!merger.id.isNull) id = merger.id;
		if (!merger.keys.isNull) keys ~= merger.keys;
		if (!merger.vals.isNull) vals ~= merger.vals;
		if (!merger.info.isNull) info = merger.info;
		if (!merger.lat.isNull) lat = merger.lat;
		if (!merger.lon.isNull) lon = merger.lon;
	}

	static Node opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct DenseNodes {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(long[]) id;
	/// DELTA coded

	///repeated Info info = 4;
	Nullable!(DenseInfo) denseinfo;
	///
	Nullable!(long[]) lat;
	/// DELTA coded
	Nullable!(long[]) lon;
	/// DELTA coded

	/// Special packing of keys and vals into one array. May be empty if all nodes in this block are tagless.
	Nullable!(int[]) keys_vals;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name id
		if(!id.isNull)
			ret ~= toPacked!(long[],toSInt)(id,1);
		// Serialize member 5 Field Name denseinfo
		static if (is(DenseInfo == struct)) {
			ret ~= denseinfo.Serialize(5);
		} else static if (is(DenseInfo == enum)) {
			if (!denseinfo.isNull) ret ~= toVarint(cast(int)denseinfo.get(),5);
		} else
			static assert(0,"Can't identify type `DenseInfo`");
		// Serialize member 8 Field Name lat
		if(!lat.isNull)
			ret ~= toPacked!(long[],toSInt)(lat,8);
		// Serialize member 9 Field Name lon
		if(!lon.isNull)
			ret ~= toPacked!(long[],toSInt)(lon,9);
		// Serialize member 10 Field Name keys_vals
		if(!keys_vals.isNull)
			ret ~= toPacked!(int[],toVarint)(keys_vals,10);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static DenseNodes Deserialize(ref ubyte[] manip, bool isroot=true) {return DenseNodes(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name id
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(id.isNull) id = new long[](0);
					id ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(id.isNull) id = new long[](0);
					id ~= fromSInt!(long)(input);
				}
			break;
			case 5:// Deserialize member 5 Field Name denseinfo
				static if (is(DenseInfo == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type DenseInfo");

					denseinfo = DenseInfo.Deserialize(input,false);
				} else static if (is(DenseInfo == enum)) {
					if (wireType == WireType.varint) {
						denseinfo = cast(DenseInfo)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type DenseInfo");

				} else
					static assert(0,
					  "Can't identify type `DenseInfo`");
			break;
			case 8:// Deserialize member 8 Field Name lat
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(lat.isNull) lat = new long[](0);
					lat ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(lat.isNull) lat = new long[](0);
					lat ~= fromSInt!(long)(input);
				}
			break;
			case 9:// Deserialize member 9 Field Name lon
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(lon.isNull) lon = new long[](0);
					lon ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(lon.isNull) lon = new long[](0);
					lon ~= fromSInt!(long)(input);
				}
			break;
			case 10:// Deserialize member 10 Field Name keys_vals
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type int32");

				if (wireType == WireType.lenDelimited) {
					if(keys_vals.isNull) keys_vals = new int[](0);
					keys_vals ~=
					   fromPacked!(int,fromVarint!(int))(input);
					//Accept data even when not packed
				} else {
					if(keys_vals.isNull) keys_vals = new int[](0);
					keys_vals ~= fromVarint!(int)(input);
				}
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
	}

	void MergeFrom(DenseNodes merger) {
		if (!merger.id.isNull) id ~= merger.id;
		if (!merger.denseinfo.isNull) denseinfo = merger.denseinfo;
		if (!merger.lat.isNull) lat ~= merger.lat;
		if (!merger.lon.isNull) lon ~= merger.lon;
		if (!merger.keys_vals.isNull) keys_vals ~= merger.keys_vals;
	}

	static DenseNodes opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct Way {
	// deal with unknown fields
	ubyte[] ufields;
	///
	Nullable!(long) id;
	/// Parallel arrays.
	Nullable!(uint[]) keys;
	///
	Nullable!(uint[]) vals;
	///
	Nullable!(Info) info;
	///
	Nullable!(long[]) refs;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name id
		ret ~= toVarint(id.get(),1);
		// Serialize member 2 Field Name keys
		if(!keys.isNull)
			ret ~= toPacked!(uint[],toVarint)(keys,2);
		// Serialize member 3 Field Name vals
		if(!vals.isNull)
			ret ~= toPacked!(uint[],toVarint)(vals,3);
		// Serialize member 4 Field Name info
		static if (is(Info == struct)) {
			ret ~= info.Serialize(4);
		} else static if (is(Info == enum)) {
			if (!info.isNull) ret ~= toVarint(cast(int)info.get(),4);
		} else
			static assert(0,"Can't identify type `Info`");
		// Serialize member 8 Field Name refs
		if(!refs.isNull)
			ret ~= toPacked!(long[],toSInt)(refs,8);
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Way Deserialize(ref ubyte[] manip, bool isroot=true) {return Way(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name id
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				id = fromVarint!(long)(input);
			break;
			case 2:// Deserialize member 2 Field Name keys
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type uint32");

				if (wireType == WireType.lenDelimited) {
					if(keys.isNull) keys = new uint[](0);
					keys ~=
					   fromPacked!(uint,fromVarint!(uint))(input);
					//Accept data even when not packed
				} else {
					if(keys.isNull) keys = new uint[](0);
					keys ~= fromVarint!(uint)(input);
				}
			break;
			case 3:// Deserialize member 3 Field Name vals
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type uint32");

				if (wireType == WireType.lenDelimited) {
					if(vals.isNull) vals = new uint[](0);
					vals ~=
					   fromPacked!(uint,fromVarint!(uint))(input);
					//Accept data even when not packed
				} else {
					if(vals.isNull) vals = new uint[](0);
					vals ~= fromVarint!(uint)(input);
				}
			break;
			case 4:// Deserialize member 4 Field Name info
				static if (is(Info == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Info");

					info = Info.Deserialize(input,false);
				} else static if (is(Info == enum)) {
					if (wireType == WireType.varint) {
						info = cast(Info)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Info");

				} else
					static assert(0,
					  "Can't identify type `Info`");
			break;
			case 8:// Deserialize member 8 Field Name refs
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(refs.isNull) refs = new long[](0);
					refs ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(refs.isNull) refs = new long[](0);
					refs ~= fromSInt!(long)(input);
				}
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (id.isNull) throw new Exception("Did not find a id in the message parse.");
	}

	void MergeFrom(Way merger) {
		if (!merger.id.isNull) id = merger.id;
		if (!merger.keys.isNull) keys ~= merger.keys;
		if (!merger.vals.isNull) vals ~= merger.vals;
		if (!merger.info.isNull) info = merger.info;
		if (!merger.refs.isNull) refs ~= merger.refs;
	}

	static Way opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
struct Relation {
	// deal with unknown fields
	ubyte[] ufields;
	enum MemberType {
		NODE = 0,
		WAY = 1,
		RELATION = 2,
	}


	///
	Nullable!(long) id;
	/// Parallel arrays.
	Nullable!(uint[]) keys;
	///
	Nullable!(uint[]) vals;
	///
	Nullable!(Info) info;
	/// Parallel arrays
	Nullable!(int[]) roles_sid;
	///
	Nullable!(long[]) memids;
	/// DELTA encoded
	Nullable!(MemberType[]) types;

	ubyte[] Serialize(int field = -1) {
		ubyte[] ret;
		// Serialize member 1 Field Name id
		ret ~= toVarint(id.get(),1);
		// Serialize member 2 Field Name keys
		if(!keys.isNull)
			ret ~= toPacked!(uint[],toVarint)(keys,2);
		// Serialize member 3 Field Name vals
		if(!vals.isNull)
			ret ~= toPacked!(uint[],toVarint)(vals,3);
		// Serialize member 4 Field Name info
		static if (is(Info == struct)) {
			ret ~= info.Serialize(4);
		} else static if (is(Info == enum)) {
			if (!info.isNull) ret ~= toVarint(cast(int)info.get(),4);
		} else
			static assert(0,"Can't identify type `Info`");
		// Serialize member 8 Field Name roles_sid
		if(!roles_sid.isNull)
			ret ~= toPacked!(int[],toVarint)(roles_sid,8);
		// Serialize member 9 Field Name memids
		if(!memids.isNull)
			ret ~= toPacked!(long[],toSInt)(memids,9);
		// Serialize member 10 Field Name types
		static if (is(MemberType == struct)) {
			foreach(iter;types			) {
				ret ~= iter.Serialize(10);
			}
		} else static if (is(MemberType == enum)) {
			if(!types.isNull)
				ret ~= toPacked!(int[],toVarint)(cast(int[])types,10);
		} else
			static assert(0,"Can't identify type `MemberType`");
		ret ~= ufields;
		// take care of header and length generation if necessary
		if (field != -1) {
			ret = genHeader(field,2)~toVarint(ret.length,field)[1..$]~ret;
		}
		return ret;
	}

	// if we're root, we can assume we own the whole string
	// if not, the first thing we need to do is pull the length that belongs to us
	static Relation Deserialize(ref ubyte[] manip, bool isroot=true) {return Relation(manip,isroot);}
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
			case 1:// Deserialize member 1 Field Name id
				if (wireType != WireType.varint)
					throw new Exception("Invalid wiretype " ~
					   to!(string)(wireType) ~
					   " for variable type int64");

				id = fromVarint!(long)(input);
			break;
			case 2:// Deserialize member 2 Field Name keys
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type uint32");

				if (wireType == WireType.lenDelimited) {
					if(keys.isNull) keys = new uint[](0);
					keys ~=
					   fromPacked!(uint,fromVarint!(uint))(input);
					//Accept data even when not packed
				} else {
					if(keys.isNull) keys = new uint[](0);
					keys ~= fromVarint!(uint)(input);
				}
			break;
			case 3:// Deserialize member 3 Field Name vals
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type uint32");

				if (wireType == WireType.lenDelimited) {
					if(vals.isNull) vals = new uint[](0);
					vals ~=
					   fromPacked!(uint,fromVarint!(uint))(input);
					//Accept data even when not packed
				} else {
					if(vals.isNull) vals = new uint[](0);
					vals ~= fromVarint!(uint)(input);
				}
			break;
			case 4:// Deserialize member 4 Field Name info
				static if (is(Info == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Info");

					info = Info.Deserialize(input,false);
				} else static if (is(Info == enum)) {
					if (wireType == WireType.varint) {
						info = cast(Info)
						   fromVarint!(int)(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type Info");

				} else
					static assert(0,
					  "Can't identify type `Info`");
			break;
			case 8:// Deserialize member 8 Field Name roles_sid
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type int32");

				if (wireType == WireType.lenDelimited) {
					if(roles_sid.isNull) roles_sid = new int[](0);
					roles_sid ~=
					   fromPacked!(int,fromVarint!(int))(input);
					//Accept data even when not packed
				} else {
					if(roles_sid.isNull) roles_sid = new int[](0);
					roles_sid ~= fromVarint!(int)(input);
				}
			break;
			case 9:// Deserialize member 9 Field Name memids
				if (wireType != WireType.lenDelimited)
					if (wireType != WireType.varint)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type sint64");

				if (wireType == WireType.lenDelimited) {
					if(memids.isNull) memids = new long[](0);
					memids ~=
					   fromPacked!(long,fromSInt!(long))(input);
					//Accept data even when not packed
				} else {
					if(memids.isNull) memids = new long[](0);
					memids ~= fromSInt!(long)(input);
				}
			break;
			case 10:// Deserialize member 10 Field Name types
				static if (is(MemberType == struct)) {
					if(wireType != WireType.lenDelimited)
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type MemberType");

					if(types.isNull) types = new MemberType[](0);
					types ~= MemberType.Deserialize(input,false);
				} else static if (is(MemberType == enum)) {
					if (wireType == WireType.varint) {
						if(types.isNull) types = new MemberType[](0);
						types ~= cast(MemberType)
						   fromVarint!(int)(input);
					} else if (wireType == WireType.lenDelimited) {
						if(types.isNull) types = new MemberType[](0);
						types ~=
						   fromPacked!(MemberType,fromVarint!(int))(input);
					} else
						throw new Exception("Invalid wiretype " ~
						   to!(string)(wireType) ~
						   " for variable type MemberType");

				} else
					static assert(0,
					  "Can't identify type `MemberType`");
			break;
			default:
				// rip off unknown fields
			if(input.length)
				ufields ~= _toVarint(header)~
				   ripUField(input,getWireType(header));
			break;
			}
		}
		if (id.isNull) throw new Exception("Did not find a id in the message parse.");
	}

	void MergeFrom(Relation merger) {
		if (!merger.id.isNull) id = merger.id;
		if (!merger.keys.isNull) keys ~= merger.keys;
		if (!merger.vals.isNull) vals ~= merger.vals;
		if (!merger.info.isNull) info = merger.info;
		if (!merger.roles_sid.isNull) roles_sid ~= merger.roles_sid;
		if (!merger.memids.isNull) memids ~= merger.memids;
		if (!merger.types.isNull) types ~= merger.types;
	}

	static Relation opCall(ref ubyte[]input) {
		return Deserialize(input);
	}
}
