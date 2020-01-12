module stream;

import std.algorithm;
import std.string;

interface InputStream
{
    @property bool eof() const;

    byte[] peek(size_t max_size);

    byte[] read(size_t max_size);

    string readln(string delimitor = "\r\n");
}

class MemoryStream : InputStream
{
    private const(byte[]) _data;
    private size_t _cursor_read;

    this(const(byte[]) data)
    {
        _data = data;
        _cursor_read = 0;
    }

    this(string data)
    {
        this(cast(const(byte[])) data);
    }

    @property bool eof() const
    {
        return _cursor_read >= _data.length;
    }

    byte[] peek(size_t max_size)
    {
        if (eof)
        {
            throw new Error("input stream already reached eof");
        }

        return _data[_cursor_read .. min(_cursor_read + max_size, $)].dup;
    }

    byte[] read(size_t max_size)
    {
        auto bytes = peek(max_size);
        _cursor_read += bytes.length;

        return bytes;
    }

    string readln(string delimitor = "\r\n")
    {
        auto index = indexOf(cast(string) _data, delimitor, _cursor_read);
        if (index < 0)
        {
            return cast(string) read(_data.length - _cursor_read);
        }
        return cast(string) read(index - _cursor_read + delimitor.length);
    }
}
