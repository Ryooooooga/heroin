import std.stdio;
import std.format;
import http;
import server;
import application;

shared class SimpleApplication : Application
{
    void onListened(ushort port)
    {
        writef("server listening at port %d...\n", port);
    }

    void onConnected(Request req, Response res)
    {
        writef("Request: %s %s %s\n", req.method, req.requestUri, req.httpVersion);

        switch (req.method)
        {
        case Method.GET:
            switch (req.requestUri.path)
            {
            case "/":
                res.body = "hello";
                return;

            default:
                break;
            }
            goto default;

        default:
            res.status = HttpStatus.NOT_FOUND;
            res.body = format("%s %s %d %s", req.method, req.requestUri,
                    cast(int) res.status, res.status.text);
            break;
        }
    }

    void onError(Throwable e)
    {
        stderr.writeln(e);
    }
}

void main()
{
    new HttpServer(new SimpleApplication()).listen(3000);
}
