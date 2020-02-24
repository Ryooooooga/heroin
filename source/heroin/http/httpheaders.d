module heroin.http.httpheaders;

import std.conv : to;
import std.typecons : Nullable, nullable;
import std.uni : toLower;

class HttpHeaders
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
        auto h = new HttpHeaders();
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
        _fields[key.toLower] = value;
    }

    void append(string key, string value)
    {
        key = key.toLower;

        if (auto v = key in _fields)
        {
            *v ~= ", ";
            *v ~= value;
        }
        else
        {
            set(key, value);
        }
    }

    Nullable!string get(string key) const
    {
        key = key.toLower;

        if (const v = key in _fields)
        {
            return (*v).nullable;
        }
        else
        {
            return Nullable!string.init;
        }
    }

    string opIndex(string key) const
    {
        return _fields[key.toLower];
    }

    void opIndexAssign(string value, string key)
    {
        set(key, value);
    }

    unittest
    {
        import core.exception : RangeError;
        import std.exception : assertThrown;

        auto h = new HttpHeaders();
        h.set("Host", "example.com");
        h.set("Content-Type", "application/json");
        h.set("Content-Length", "2");

        assert(h.get("Host") == "example.com");
        assert(h.get("Content-Type") == "application/json");
        assert(h.get("content-type") == "application/json");
        assert(h.get("Content-Length") == "2");
        assert(h.get("CONTENT-LENGTH") == "2");
        assert(h.get("Accept").isNull);

        assert(h["Host"] == "example.com");
        assert(h["Content-Type"] == "application/json");
        assert(h["content-type"] == "application/json");
        assert(h["Content-Length"] == "2");
        assert(h["CONTENT-LENGTH"] == "2");
        assertThrown!RangeError(h["Accept"]);
    }

    unittest
    {
        auto h = new HttpHeaders();
        h["Host"] = "localhost";
        h["Host"] = "example.com";
        h.set("Content-Type", "text/html");
        h.set("Content-Type", "application/json");
        h.append("Vary", "Accept-Encoding");
        h.append("Vary", "User-Agent");

        assert(h.get("Host") == "example.com");
        assert(h.get("Content-Type") == "application/json");
        assert(h.get("Vary") == "Accept-Encoding, User-Agent");
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
        auto h = new HttpHeaders();

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
        auto h = new HttpHeaders();
        h.contentType = "text/html";
        h.contentLength = 128;
        h.contentEncoding = "gzip";

        assert(h.contentType == "text/html");
        assert(h.contentLength == 128);
        assert(h.contentEncoding == "gzip");
    }
}
