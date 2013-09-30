module compression.compressible_pbf_struct;

import compression.pb_encoding;


struct CompressiblePbfStruct(T)
{
    T s;
    alias s this;
    
    ubyte[] compress()
    out(r)
    {
        CompressiblePbfStruct d;
        size_t offset = d.decompress(&r[0]);
        
        assert( offset == r.length );
    }
    body
    {
        auto bytes = s.Serialize;
        auto size = packVarint(bytes.length);
        
        return size ~ bytes;
    }
    
    size_t decompress( inout ubyte* from )
    {
        size_t blob_size;
        size_t offset = blob_size.unpackVarint( from );
        size_t end = offset + blob_size;
        
        auto arr = from[offset..end].dup;
        s = Deserialize( arr );
        
        return end;
    }
}
