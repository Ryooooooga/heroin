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
        req.writeln;
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
