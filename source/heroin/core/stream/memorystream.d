module heroin.core.stream.memorystream;

import std.algorithm : min;
import heroin.core.stream : InputStream;

class MemoryInputStream : InputStream
{
    private immutable(ubyte)[] _data;

    this(immutable ubyte[] data)
    {
        _data = data;
    }

    unittest
    {
        immutable ubyte[] bytes = [0, 1, 2];
        auto m = new MemoryInputStream(bytes);
    }

    this(string data)
    {
        this(cast(immutable ubyte[]) data);
    }

    unittest
    {
        auto m = new MemoryInputStream("string");
    }

    protected override size_t readBlock(void* buffer, size_t size)
    {
        const readSize = min(size, _data.length);
        auto cbuffer = cast(ubyte*) buffer;

        cbuffer[0 .. readSize] = _data[0 .. readSize];
        _data = _data[readSize .. $];

        return readSize;
    }
}

unittest
{
    import std.exception : assertThrown;
    import heroin.core.stream : StreamException;

    auto m = new MemoryInputStream("This is test stream.\nThis is 2nd line.");

    assert(m.eof == false);

    assert(m.readChar() == 'T');
    assert(m.peekChar() == 'h');
    assert(m.peekChar() == 'h');
    assert(m.readChar() == 'h');
    assert(m.peekChar() == 'i');
    assert(m.readUntil("test") == "is is test");
    assert(m.readUntil("\n") == " stream.\n");

    char[4] s;
    m.readExact(s.ptr, s.length);
    assert(s == "This");
    assert(m.readUntil(".") == " is 2nd line.");

    assertThrown!StreamException(m.readChar());
}
