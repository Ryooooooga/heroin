module request;

import std.algorithm;
import std.array;
import std.exception;
import std.string;
import stream;

enum Method
{
    GET = "GET",
    POST = "POST",
    PUT = "PUT",
    DELETE = "DELETE",
    HEAD = "HEAD",
}

enum HttpVersion
{
    HTTP_1_1 = "HTTP/1.1",
}

class Request
{
    private InputStream _stream;
    private string _body;

    string method;
    string requestUri;
    string httpVersion;
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
        req.requestUri = stream.readln(" ").strip;
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
        if (_body)
        {
            return _body;
        }

        return _body = _stream.readAll();
    }

    unittest
    {
        auto req = Request.parse(
                "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: unittest \r\n\r\nbody\r\n");

        assert(req.method == Method.GET);
        assert(req.requestUri == "/");
        assert(req.httpVersion == HttpVersion.HTTP_1_1);

        assert(req.headers == [
                "Host": "example.com",
                "User-Agent": "unittest",
                ]);

        assert(req.body == "body\r\n");
    }
}
