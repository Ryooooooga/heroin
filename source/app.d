import std.stdio;
import http;
import server;
import application;

shared class SimpleApplication : Application
{
    void onListened(ushort port)
    {
        writef("server listening at port %d...\n", port);
    }

    void onConnected(Request req)
    {
        writef("Request: %s %s %s\n", req.method, req.requestUri, req.httpVersion);
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
