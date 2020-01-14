import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.file;
import std.path;
import std.format;
import std.json;
import http;
import server;
import application;
import routers;
import renderers;

shared class SimpleApplication : Application
{
    private Router _router;

    this() shared
    {
        _router = new shared(Router)();

        // Static resources
        serveStatic("/", "./static", "*");
        _router.get_alias("/", "/index.html");

        // Articles
        servePosts("/", "./posts");
    }

    void serveStatic(string root, string path, string pattern)
    {
        const absPath = path.asAbsolutePath.to!string;
        auto files = absPath.dirEntries(pattern, SpanMode.depth).filter!"a.isFile";

        foreach (dirEntry; files)
        {
            const relative = relativePath(dirEntry.name, absPath);
            const uri = buildNormalizedPath(root, relative);

            _router.get(uri, render_file(dirEntry.name));
        }
    }

    void servePosts(string root, string path)
    {
        const absPath = path.asAbsolutePath.to!string;
        auto files = absPath.dirEntries("*.md", SpanMode.depth).filter!"a.isFile";

        foreach (dirEntry; files)
        {
            const relative = relativePath(dirEntry.name, absPath);
            const uri = buildNormalizedPath(root, relative.stripExtension);

            _router.get(uri, render_md(dirEntry.name));
        }
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
    new HttpServer(new shared(SimpleApplication)()).listen(3000);
}
