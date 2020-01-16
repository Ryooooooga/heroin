import std.algorithm;
import std.array;
import std.conv;
import std.stdio;
import std.file;
import std.path;
import std.format;
import std.json;
import std.string;
import dmarkdown;
import sqlite;
import http;
import server;
import application;
import routers;
import renderers;

class Post
{
    int id;
    string author;
    string markdownText;
    string htmlText;
    string createdAt;

    this()
    {
    }

    this(string author, string markdownText, string htmlText)
    {
        this.id = 0;
        this.author = author;
        this.markdownText = markdownText;
        this.htmlText = htmlText;
        this.createdAt = null;
    }
}

JSONValue toJSON(Post post)
{
    return JSONValue([
        "id": JSONValue(post.id),
        "author": JSONValue(post.author),
        "markdownText": JSONValue(post.markdownText),
        "htmlText": JSONValue(post.htmlText),
        "createdAt": JSONValue(post.createdAt),
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

class PostModel: Model!Post
{
    private SQLite3 _db;

    this(SQLite3 db)
    {
        _db = db;
    }

    Post[] all()
    {
        Post[] posts = [];
        auto q = _db.query("SELECT id, author, markdownText, htmlText, createdAt FROM post ORDER BY createdAt DESC");
        while (q.step())
        {
            auto values = q.get!(int, string, string, string, string);
            auto post = new Post();
            post.id = values[0];
            post.author = values[1];
            post.markdownText = values[2];
            post.htmlText = values[3];
            post.createdAt = values[4];
            posts ~= post;
        }

        return posts;
    }

    void insert(Post post)
    {
        _db.exec("INSERT INTO post (author, markdownText, htmlText) VALUES (?, ?, ?)", post.author, post.markdownText, post.htmlText);
    }
}

class PostController
{
    private shared Model!Post _model;

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
    private shared Router _router;

    this() shared
    {
        // Setup database
        auto db = new SQLite3("./db/database.db");
        db.exec(`
            CREATE TABLE IF NOT EXISTS post (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                author TEXT NOT NULL,
                markdownText TEXT NOT NULL,
                htmlText TEXT NOT NULL,
                createdAt DATETIME NOT NULL DEFAULT (datetime('now', 'localtime'))
            )
        `);

        // Setup routing
        auto router = new Router();

        // Static resources
        router.serveStatic("/", "./static", "*");
        router.forwardGet("/", "/index.html");

        // JSON APIs
        auto model = new PostModel(db);
        auto postController = new shared(PostController)(cast(shared)model);
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
