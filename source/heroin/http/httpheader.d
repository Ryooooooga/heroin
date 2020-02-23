module heroin.http.httpheader;

import std.conv : to;
import std.typecons : Nullable, nullable;
import std.uni : toLower;

class HttpHeader
{
    private string[string] _fields;

    enum
    {
        CONTENT_TYPE = "content-type",
        CONTENT_LENGTH = "content-length",
        CONTENT_ENCODING = "content-encoding",
    }

    this()
    {
    }

    @property const(string[string]) fields() const
    {
        return _fields;
    }

    @property string[] keys() const
    {
        return _fields.keys;
    }

    bool contains(string key) const
    {
        return !!(key.toLower in _fields);
    }

    unittest
    {
        auto h = new HttpHeader();
        h.set("Host", "example.com");
        h.set("Content-Type", "application/json");
        h.set("Content-Length", "2");

        assert(h.fields == cast(const)[
                "host": "example.com",
                "content-type": "application/json",
                "content-length": "2",
                ]);

        assert(h.keys.length == 3);

        assert(h.contains("Host"));
        assert(h.contains("Content-Type"));
        assert(h.contains("Content-Length"));
        assert(!h.contains("Accept"));
    }

    void set(string key, string value)
    {
        key = key.toLower;

        if (auto v = key in _fields)
        {
            *v ~= ",";
            *v ~= value;
        }
        else
        {
            _fields[key] = value;
        }
    }

    unittest
    {
        auto h = new HttpHeader();
        h.set("Vary", "Accept-Encoding");
        h.set("Vary", "User-Agent");

        assert(h.get("Vary") == "Accept-Encoding,User-Agent");
    }

    Nullable!string get(string key) const
    {
        if (const v = key.toLower in _fields)
        {
            return (*v).nullable;
        }
        else
        {
            return Nullable!string.init;
        }
    }

    unittest
    {
        auto h = new HttpHeader();
        h.set("Host", "example.com");
        h.set("Content-Type", "application/json");
        h.set("Content-Length", "2");

        assert(h.get("Host") == "example.com");
        assert(h.get("Content-Type") == "application/json");
        assert(h.get("content-type") == "application/json");
        assert(h.get("Content-Length") == "2");
        assert(h.get("CONTENT-LENGTH") == "2");
        assert(h.get("Accept").isNull);
    }

    @property Nullable!string contentType() const
    {
        return get(CONTENT_TYPE);
    }

    @property void contentType(string value)
    {
        _fields[CONTENT_TYPE] = value;
    }

    @property Nullable!size_t contentLength() const
    {
        if (const v = CONTENT_LENGTH in _fields)
        {
            return (*v).to!size_t.nullable;
        }
        else
        {
            return Nullable!size_t.init;
        }
    }

    @property void contentLength(size_t value)
    {
        _fields[CONTENT_LENGTH] = value.to!string();
    }

    /// `identity` if `Content-Encoding` is not set
    @property string contentEncoding() const
    {
        if (auto v = CONTENT_ENCODING in _fields)
        {
            return *v;
        }
        else
        {
            return "identity";
        }
    }

    @property void contentEncoding(string value)
    {
        _fields[CONTENT_ENCODING] = value;
    }

    unittest
    {
        auto h = new HttpHeader();

        assert(h.contentType.isNull);
        assert(h.contentLength.isNull);
        assert(h.contentEncoding == "identity");

        h.set("Content-Type", "application/json");
        h.set("Content-Length", "2");
        h.set("Content-Encoding", "gzip");

        assert(h.contentType == "application/json");
        assert(h.contentLength == 2);
        assert(h.contentEncoding == "gzip");
    }

    unittest
    {
        auto h = new HttpHeader();
        h.contentType = "text/html";
        h.contentLength = 128;
        h.contentEncoding = "gzip";

        assert(h.contentType == "text/html");
        assert(h.contentLength == 128);
        assert(h.contentEncoding == "gzip");
    }
}
