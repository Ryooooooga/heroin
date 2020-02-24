module heroin.core.stream;

import std.algorithm : endsWith, min;
import std.exception : basicExceptionCtors;

class StreamException : Exception
{
    mixin basicExceptionCtors;
}

abstract class InputStream
{
    private bool _readEof = false;
    private ubyte[] _lookahead = [];

    @property bool eof()
    {
        return _readEof && _lookahead.length == 0;
    }

    void readExact(void* buffer, size_t size)
    {
        ubyte* cbuffer = cast(ubyte*) buffer;
        size_t pos = 0;

        if (_lookahead.length > 0)
        {
            pos += min(_lookahead.length, size);

            cbuffer[0 .. pos] = _lookahead[0 .. pos];
            _lookahead = _lookahead[pos .. $];
        }

        while (pos < size)
        {
            const readSize = readBlock(cbuffer + pos, size - pos);

            if (readSize == 0)
            {
                throw new StreamException("the stream has already reached EOF");
            }

            pos += readSize;
        }
    }

    void readExact(void[] buffer)
    {
        readExact(buffer.ptr, buffer.length);
    }

    char peekChar()
    {
        if (_lookahead.length == 0)
        {
            enum BLOCK_SIZE = 1024;
            ubyte[BLOCK_SIZE] block;
            const readSize = readBlock(block.ptr, block.length);

            if (readSize == 0)
            {
                throw new StreamException("the stream has already reached EOF");
            }

            _lookahead = block[0 .. readSize].dup;
        }

        return cast(char) _lookahead[0];
    }

    char readChar()
    {
        char c = peekChar();
        _lookahead = _lookahead[1 .. $];

        return c;
    }

    char[] readUntil(string terminator)
    {
        char[] s;

        while (!s.endsWith(terminator))
        {
            char c = readChar();
            s ~= c;
        }

        return s;
    }

    protected abstract size_t readBlock(void* buffer, size_t size);
}
