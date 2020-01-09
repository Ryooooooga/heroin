module request;

import std.algorithm;
import std.array;
import std.exception;
import std.string;

struct Method
{
    static immutable Method GET = Method("GET");
    static immutable Method POST = Method("POST");
    static immutable Method PUT = Method("PUT");
    static immutable Method DELETE = Method("DELETE");
    static immutable Method HEAD = Method("HEAD");

    string text;
}

struct HttpVersion
{
    static immutable HttpVersion HTTP_1_1 = HttpVersion("HTTP/1.1");

    string text;
}

struct Request
{
    Method method;
    string request_uri;
    HttpVersion http_version;
    string[string] headers;
    string body;

    static Request parse(string text)
    {
        Request req;

        auto split = text.findSplit("\r\n").enforce("empty requests");

        // request-line
        const request_line = split[0].split(" ");
        enforce(request_line.length == 3, "invalid request-line formats");

        req.method = Method(request_line[0]);
        req.request_uri = request_line[1];
        req.http_version = HttpVersion(request_line[2]);

        text = split[2];

        // *(header)
        split = text.findSplit("\r\n\r\n").enforce("missing the end of message-headers");

        auto key_values = split[0].split("\r\n").map!(line => line.findSplit(":")
                .enforce("missing ':' in a meassage-header"));

        foreach (key, _, value; key_values)
        {
            req.headers[key] = value.strip;
        }

        text = split[2];

        // body
        req.body = text;

        return req;
    }

    unittest
    {
        const req = Request.parse(
                "GET / HTTP/1.1\r\nHost: example.com\r\nUser-Agent: unittest \r\n\r\nbody\r\n");

        assert(req.method == Method.GET);
        assert(req.request_uri == "/");
        assert(req.http_version == HttpVersion.HTTP_1_1);

        assert(req.headers == cast(const)[
                "Host": "example.com",
                "User-Agent": "unittest",
                ]);

        assert(req.body == "body\r\n");
    }
}
