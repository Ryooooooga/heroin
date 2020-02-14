module request;

import std.algorithm : findSplit;
import std.array : array;
import std.conv : to;
import std.exception : enforce;
import std.string : strip;
import stream : InputStream, MemoryStream;
import httpversion : HttpVersion, HttpVersions;
import uri : Uri;

alias Method = string;

enum Methods : Method
{
    GET = "GET",
    POST = "POST",
    PUT = "PUT",
    DELETE = "DELETE",
    HEAD = "HEAD",
}

class Request
{
    private InputStream _stream;
    private string _body;

    Method method;
    Uri requestUri;
    HttpVersion httpVersion;
    string[string] headers;

    static Request parse(string text)
    {
        return parse(new MemoryStream(text.dup));
    }

    static Request parse(InputStream stream)
    {
        Request req = new Request();
        req._stream = stream;

        // request-line
        req.method = stream.readln(" ").strip;
        req.requestUri = new Uri(stream.readln(" ").strip);
        req.httpVersion = stream.readln("\r\n").strip;

        // *(header)
        string line;
        while ((line = stream.readln("\r\n")) != "\r\n")
        {
            const keyValue = line.findSplit(":").enforce("missing ':' in a meassage-header");

            req.headers[keyValue[0]] = keyValue[2].strip;
        }

        return req;
    }

    string body()
    {
        if (_body is null)
        {
            _body = _stream.read(headers["Content-Length"].to!size_t);
        }

        return _body;
    }

    unittest
    {
        auto req = Request.parse(
                "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: unittest \r\nContent-Length: 6\r\n\r\nbody\r\n");

        assert(req.method == Methods.GET);
        assert(req.requestUri.text == "/");
        assert(req.httpVersion == HttpVersions.HTTP_1_1);

        assert(req.headers == [
                "Host": "example.com",
                "User-Agent": "unittest",
                "Content-Length": "6",
                ]);

        assert(req.body == "body\r\n");
    }
}
