module uri;

import std.algorithm;
import std.string;

class Uri
{
    private string _text;
    private string _path;
    private string _query;
    private string _hash;

    this(string text)
    {
        auto query_index = text.indexOf('?');
        query_index = query_index == -1 ? text.length : query_index;

        auto hash_index = text.indexOf('#', query_index);
        hash_index = hash_index == -1 ? text.length : hash_index;

        const path = text[0 .. query_index];
        const query = text[query_index .. hash_index];
        const hash = text[hash_index .. $];

        _text = text;
        _path = path;
        _query = query;
        _hash = hash;
    }

    @property string text() const
    {
        return _text;
    }

    @property string path() const
    {
        return _path;
    }

    @property string query() const
    {
        return _query;
    }

    @property string hash() const
    {
        return _hash;
    }

    override string toString() const
    {
        return _text;
    }
}

unittest
{
    const uri = new Uri("/test%20path?b=0&c=Hello%20world#hash");

    assert(uri.text == "/test%20path?b=0&c=Hello%20world#hash");
    assert(uri.path == "/test%20path");
    assert(uri.query == "?b=0&c=Hello%20world");
    assert(uri.hash == "#hash");
}
