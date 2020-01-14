import std.algorithm;
import std.stdio;
import std.path;
import std.format;
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

        auto article_files = [
            "./static/01-test.md", "./static/02-also-test.md",
        ];

        // Static resources
        _router.get("/", render_file("./static/index.html"));
        _router.get("/app.js", render_file("./static/app.js"));

        foreach(file; article_files)
        {
            const uri = format("/%s", file.baseName.stripExtension);

            _router.get(uri, render_md(file));
        }

        // JSON API
        _router.get("/articles.json", render_file("./static/articles.json"));
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
