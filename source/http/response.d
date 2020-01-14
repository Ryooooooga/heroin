module response;

import std.outbuffer;
import httpversion;
import httpstatus;

class Response
{
    HttpVersion httpVersion;
    HttpStatus status;
    string[string] headers;
    string body;

    override string toString()
    {
        OutBuffer buf = new OutBuffer();

        buf.writef("%s %s %s\r\n", httpVersion, cast(int) status, status.text);

        foreach (key, value; headers)
        {
            buf.writef("%s: %s\r\n", key, value);
        }

        buf.writef("Content-Length: %d\r\n", body.length);
        buf.write("\r\n");
        buf.write(body);

        return buf.toString();
    }

    unittest
    {
        Response res = new Response();
        res.httpVersion = HttpVersions.HTTP_1_1;
        res.status = HttpStatus.OK;
        res.headers["Content-Type"] = "text/html; charset=utf-8";
        res.body = "<html></html>";

        assert(res.toString() == "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: 13\r\n\r\n<html></html>");
    }
}
