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
import dmarkdown;
import http;
import server;
import application;
import routers;
import renderers;

synchronized class Post
{
    private long _id;
    private string _author;
    private string _markdownText;
    private string _htmlText;
    private DateTime _createdAt;

    this(string author, string markdownText, string htmlText,
            DateTime createdAt = cast(DateTime) Clock.currTime(UTC())) shared
    {
        _id = 0;
        _author = author;
        _markdownText = markdownText;
        _htmlText = htmlText;
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

    @property string markdownText() const
    {
        return _markdownText;
    }

    @property string htmlText() const
    {
        return _htmlText;
    }

    @property DateTime createdAt() const
    {
        return _createdAt;
    }
}

shared class PostController
{
    private Post[] _posts;

    // GET /posts
    void onGetPosts(Request req, Response res)
    {
        res.status = HttpStatus.OK;
        res.headers["Content-Type"] = "application/json; charset=utf-8";
        res.body = posts.toString();
    }

    // POST /posts
    void onPostPosts(Request req, Response res)
    {
        const json = parseJSON(req.body);
        const author = json["author"].str.strip;
        const markdownText = json["text"].str.strip;
        const markdownFlags = MarkdownFlags.githubInspired
            | MarkdownFlags.noInlineHtml | MarkdownFlags.keepLineBreaks;
        const htmlText = filterMarkdown(markdownText, markdownFlags);
        const createdAt = cast(DateTime) Clock.currTime();

        if (author.length == 0 || 32 < author.length || markdownText.length == 0
                || 1024 < markdownText.length)
        {
            res.status = HttpStatus.BAD_REQUEST;
            res.body = "{\"error\": \"POST /posts error\"}";
            return;
        }

        auto post = new shared(Post)(author, markdownText, htmlText, createdAt);

        _posts ~= post;

        res.status = HttpStatus.CREATED;
        res.headers["Content-Type"] = "application/json; charset=utf-8";
        res.body = posts.toString();
    }

    private @property JSONValue posts()
    {
        return JSONValue(_posts.map!(post => JSONValue([
                    "id": JSONValue(post.id),
                    "author": JSONValue(post.author),
                    "markdownText": JSONValue(post.markdownText),
                    "htmlText": JSONValue(post.htmlText),
                    "createdAt": JSONValue(post.createdAt.toISOExtString()),
                ])).array);
    }
}

void serveStatic(Router router, string root, string path, string pattern)
{
    const absPath = path.asAbsolutePath.to!string;
    auto files = absPath.dirEntries(pattern, SpanMode.depth).filter!"a.isFile";

    foreach (dirEntry; files)
    {
        const relative = relativePath(dirEntry.name, absPath);
        const uri = buildNormalizedPath(root, relative);

        router.get(uri, render_file(dirEntry.name));
    }
}

shared class SimpleApplication : Application
{
    private Router _router;

    this() shared
    {
        auto router = new Router();

        // Static resources
        router.serveStatic("/", "./static", "*");
        router.forwardGet("/", "/index.html");

        // JSON APIs
        auto postController = new shared(PostController)();
        router.get("/posts", (req, res) => postController.onGetPosts(req, res));
        router.post("/posts", (req, res) => postController.onPostPosts(req, res));

        _router = cast(shared)router;
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
