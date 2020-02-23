module heroin.http.httpbody;

import std.typecons : Nullable, nullable;
import heroin.core.stream : InputStream;
import heroin.http.httpheader : HttpHeader;

class HttpBody
{
    private HttpHeader _header;
    private InputStream _stream;
    private Nullable!(ubyte[]) _bytes;

    this(HttpHeader header, InputStream stream)
    in
    {
        assert(header);
        assert(stream);
    }
    body
    {
        _header = header;
        _stream = stream;
    }

    const(ubyte)[] bytes()
    {
        if (!_bytes.isNull)
        {
            return _bytes.get();
        }

        const length = _header.contentLength;
        const encoding = _header.contentEncoding;

        switch (encoding)
        {
        case "identity":
            if (length.isNull)
            {
                assert(0); // TODO: 400 error
            }

            _bytes = new ubyte[length.get()].nullable;
            _stream.readExact(_bytes.get());
            break;

        default:
            assert(0); // TODO: 415 error
        }

        return _bytes.get();
    }

    string text()
    {
        return cast(string) bytes();
    }
}

unittest
{
    import heroin.core.stream.memorystream : MemoryInputStream;

    auto b = {
        auto text = "Hello, world!";

        auto header = new HttpHeader();
        header.contentLength = text.length;

        return new HttpBody(header, new MemoryInputStream(text));
    }();

    assert(b.text == "Hello, world!");
    assert(b.text == "Hello, world!");
}
