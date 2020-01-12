module stream;

import std.algorithm;
import std.string;

abstract class InputStream
{
    private char[] _lookahead;
    private bool _eof;

    @property bool eof() const
    {
        return _eof;
    }

    string readAll()
    {
        string all = _lookahead.idup;
        _lookahead = [];

        while (true)
        {
            char[1024] buffer;
            const len = readBlock(buffer);

            if (len <= 0)
            {
                return all;
            }

            all ~= buffer[0 .. len];
        }
    }

    string readln(string delimitor = "\r\n")
    {
        while (true)
        {
            const index = _lookahead.indexOf(delimitor);

            if (index >= 0)
            {
                const end = index + delimitor.length;
                const line = _lookahead[0 .. end];
                _lookahead = _lookahead[end .. $];

                return line.idup;
            }

            if (_eof)
            {
                throw new Error("stream already reached eof");
            }

            char[1024] buffer;
            const len = readBlock(buffer);

            if (len <= 0)
            {
                _eof = true;
            }

            _lookahead ~= buffer[0 .. max(len, 0)];
        }
    }

    protected ptrdiff_t readBlock(char[] buffer);
}

class MemoryStream : InputStream
{
    private string _data;
    private size_t _cursor_read;

    this(string data)
    {
        _data = data;
        _cursor_read = 0;
    }

    protected override ptrdiff_t readBlock(char[] buffer)
    {
        const rest = _data.length - _cursor_read;
        const size_read = min(buffer.length, rest);

        _data[_cursor_read .. _cursor_read + size_read].copy(buffer);
        _cursor_read += size_read;
        return size_read;
    }
}
