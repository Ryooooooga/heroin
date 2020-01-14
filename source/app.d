import std.stdio;
import http;
import server;
import application;
import routers;

shared class SimpleApplication : Application
{
    private Router _router;

    this() shared
    {
        _router = new shared(Router)();

        _router.get("/", (req, res) {
            res.body = "Hello";
        });
    }

    void onListened(ushort port)
    {
        writef("server listening at port %d...\n", port);
    }

    void onConnected(Request req, Response res)
    {
        writef("Request: %s %s %s\n", req.method, req.requestUri, req.httpVersion);

        _router.handleRequest(req, res);
    }

    void onError(Throwable e)
    {
        stderr.writeln(e);
    }
}

void main()
{
    new HttpServer(new shared(SimpleApplication)()).listen(3001);
}
