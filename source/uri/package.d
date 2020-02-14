module uri;

import std.string : indexOf;

class Uri
{
    private string _text;

    this(string text)
    {
        _text = text;
    }

    @property string text() const
    {
        return _text;
    }

    @property string path() const
    {
        const query_index = _text.indexOf('?');
        return query_index >= 0 ? _text[0 .. query_index] : _text;
    }

    @property string query() const
    {
        const query_index = _text.indexOf('?');
        return query_index >= 0 ? _text[query_index .. $] : null;
    }

    override string toString() const
    {
        return _text;
    }
}

unittest
{
    {
        const uri = new Uri("/test");

        assert(uri.text == "/test");
        assert(uri.path == "/test");
        assert(uri.query == null);
    }
    {
        const uri = new Uri("/test%20path?b=0&c=Hello%20world");

        assert(uri.text == "/test%20path?b=0&c=Hello%20world");
        assert(uri.path == "/test%20path");
        assert(uri.query == "?b=0&c=Hello%20world");
    }
}
