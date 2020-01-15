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

    string read(size_t max_size)
    {
        char[] buffer = new char[max_size - _lookahead.length];

        string data = _lookahead.idup;
        _lookahead = [];

        const len = readBlock(buffer);

        if (len <= 0)
        {
            return data;
        }

        data ~= buffer[0 .. len];
        return data;
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
    private size_t _cursorRead;

    this(string data)
    {
        _data = data;
        _cursorRead = 0;
    }

    protected override ptrdiff_t readBlock(char[] buffer)
    {
        const rest = _data.length - _cursorRead;
        const sizeRead = min(buffer.length, rest);

        _data[_cursorRead .. _cursorRead + sizeRead].copy(buffer);
        _cursorRead += sizeRead;
        return sizeRead;
    }
}
