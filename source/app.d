import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.file;
import std.path;
import std.format;
import std.json;
import std.datetime;
import std.string;
import http;
import server;
import application;
import routers;
import renderers;

synchronized class Post
{
    private long _id;
    private string _author;
    private string _text;
    private DateTime _createdAt;

    this(string author, string text, DateTime createdAt = cast(DateTime) Clock.currTime(UTC())) shared
    {
        _id = 0;
        _author = author;
        _text = text;
        _createdAt = createdAt;
    }

    @property long id() const
    {
        return _id;
    }

    @property string author() const
    {
        return _author;
    }

    @property string text() const
    {
        return _text;
    }

    @property DateTime createdAt() const
    {
        return _createdAt;
    }
}

shared class SimpleApplication : Application
{
    private Router _router;

    private Post[] _posts;

    @property JSONValue posts()
    {
        return JSONValue(_posts.map!(post => JSONValue([
                    "id": JSONValue(post.id),
                    "author": JSONValue(post.author),
                    "text": JSONValue(post.text),
                    "createdAt": JSONValue(post.createdAt.toISOExtString()),
                ])).array);
    }

    this() shared
    {
        _router = new shared(Router)();

        // Static resources
        serveStatic("/", "./static", "*");
        _router.get_alias("/", "/index.html");

        // JSON APIs
        _router.get("/posts", (req, res) {
            res.status = HttpStatus.OK;
            res.headers["Content-Type"] = "application/json; charset=utf-8";
            res.body = posts.toString();
        });

        _router.post("/posts", (req, res) {
            const json = parseJSON(req.body);
            const author = json["author"].str.strip;
            const text = json["text"].str.strip;
            const createdAt = cast(DateTime)Clock.currTime(UTC());

            if (author.length == 0 || 32 < author.length || text.length == 0 || 1024 < text.length) {
                res.status = HttpStatus.BAD_REQUEST;
                res.body = "{\"error\": \"POST /posts error\"}";
                return;
            }

            auto post = new shared(Post)(author, text, createdAt);

            _posts ~= post;

            res.status = HttpStatus.CREATED;
            res.headers["Content-Type"] = "application/json; charset=utf-8";
            res.body = posts.toString();
        });
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
