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

struct Request
{
    private InputStream _stream;

    string method;
    string request_uri;
    string http_version;
    string[string] headers;

    static Request parse(string text)
    {
        return parse(new MemoryStream(text.dup));
    }

    static Request parse(InputStream stream)
    {
        Request req;
        req._stream = stream;

        // request-line
        req.method = stream.readln(" ").strip;
        req.request_uri = stream.readln(" ").strip;
        req.http_version = stream.readln("\r\n").strip;

        // *(header)
        string line;
        while ((line = stream.readln("\r\n")) != "\r\n")
        {
            const key_value = line.findSplit(":").enforce("missing ':' in a meassage-header");

            req.headers[key_value[0]] = key_value[2].strip;
        }

        return req;
    }

    string body()
    {
        string body_text;
        while (!_stream.eof)
        {
            body_text ~= cast(string) _stream.read(1024);
        }

        return body_text;
    }

    unittest
    {
        auto req = Request.parse(
                "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: unittest \r\n\r\nbody\r\n");

        assert(req.method == Method.GET);
        assert(req.request_uri == "/");
        assert(req.http_version == HttpVersion.HTTP_1_1);

        assert(req.headers == [
                "Host": "example.com",
                "User-Agent": "unittest",
                ]);

        assert(req.body() == "body\r\n");
    }
}
