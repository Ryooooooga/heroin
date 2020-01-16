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

class Post
{
    long id;
    string author;
    string markdownText;
    string htmlText;
    DateTime createdAt;

    this(string author, string markdownText, string htmlText)
    {
        this.id = 0;
        this.author = author;
        this.markdownText = markdownText;
        this.htmlText = htmlText;
        this.createdAt = DateTime();
    }
}

JSONValue toJSON(Post post)
{
    return JSONValue([
        "id": JSONValue(post.id),
        "author": JSONValue(post.author),
        "markdownText": JSONValue(post.markdownText),
        "htmlText": JSONValue(post.htmlText),
        "createdAt": JSONValue(post.createdAt.toISOExtString()),
    ]);
}

JSONValue toJSON(Post[] posts)
{
    return JSONValue(posts.map!(post => post.toJSON()).array);
}

interface Model(T) {
    T[] all();
    void insert(T x);
}

class PostController
{
    Model!Post _model;

    this(shared Model!Post model) shared
    {
        _model = model;
    }

    // GET /posts
    void onGetPosts(Request req, Response res) shared
    {
        synchronized(_model) {
            auto model = cast(Model!Post)_model;

            res.status = HttpStatus.OK;
            res.headers["Content-Type"] = "application/json; charset=utf-8";
            res.body = model.all().toJSON().toString();
        }
    }

    // POST /posts
    void onPostPosts(Request req, Response res) shared
    {
        synchronized(_model) {
            auto model = cast(Model!Post)_model;

            const json = parseJSON(req.body);
            const author = json["author"].str.strip;
            const markdownText = json["text"].str.strip;
            const markdownFlags = MarkdownFlags.githubInspired
                | MarkdownFlags.noInlineHtml | MarkdownFlags.keepLineBreaks;
            const htmlText = filterMarkdown(markdownText, markdownFlags);

            if (author.length == 0 || 32 < author.length || markdownText.length == 0
                    || 1024 < markdownText.length)
            {
                res.status = HttpStatus.BAD_REQUEST;
                res.body = "{\"error\": \"POST /posts error\"}";
                return;
            }

            auto post = new Post(author, markdownText, htmlText);
            model.insert(post);

            res.status = HttpStatus.CREATED;
            res.headers["Content-Type"] = "application/json; charset=utf-8";
            res.body = model.all().toJSON().toString();
        }
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

class SimpleApplication : Application
{
    private Router _router;

    this() shared
    {
        auto router = new Router();

        // Static resources
        router.serveStatic("/", "./static", "*");
        router.forwardGet("/", "/index.html");

        // JSON APIs
        shared Model!Post model = null;
        auto postController = new shared(PostController)(model);
        router.get("/posts", (req, res) => postController.onGetPosts(req, res));
        router.post("/posts", (req, res) => postController.onPostPosts(req, res));

        _router = cast(shared) router;
    }

    void onListened(ushort port) shared
    {
        writef("server listening at port %d...\n", port);
    }

    void onConnected(Request req, Response res) shared
    {
        writef("Request: %s %s %s\n", req.method, req.requestUri, req.httpVersion);

        _router.handleRequest(req, res);
    }

    void onError(Throwable e) shared
    {
        stderr.writeln(e);
    }
}

void main()
{
    new HttpServer(new shared(SimpleApplication)()).listen(3000);
}
