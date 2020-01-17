module router;

import std.algorithm;
import std.string;
import std.format;
import routers;
import httpstatus;
import request;
import response;

private struct RoutingTree
{
    private RoutingTree[string] _children;
    private shared(RequestHandler)[Method] _handlers;

    enum WILDCARD = "?";

    void insert(Method method, string path, shared(RequestHandler) handler)
    {
        // '/a/b' -> 'a/b'
        path.skipOver('/');

        if (path.length == 0)
        {
            _handlers[method] = handler;
            return;
        }

        auto sep_index = path.indexOf('/');
        sep_index = sep_index >= 0 ? sep_index : path.length;

        auto head = path[0 .. sep_index];
        const tail = path[sep_index .. $];

        if (head == "*")
        {
            head = WILDCARD;
        }

        if ((head in _children) is null)
        {
            _children[head] = RoutingTree();
        }

        _children[head].insert(method, tail, handler);
    }

    shared(RequestHandler) find(Method method, string path) shared
    {
        // '/a/b' -> 'a/b'
        path.skipOver('/');

        if (path.length == 0)
        {
            auto handler = method in _handlers;
            return handler !is null ? *handler : null;
        }

        auto sep_index = path.indexOf('/');
        sep_index = sep_index >= 0 ? sep_index : path.length;

        const head = path[0 .. sep_index];
        const tail = path[sep_index .. $];

        auto child = head in _children;
        if (child is null)
        {
            child = WILDCARD in _children;
            if (child is null)
            {
                return null;
            }
        }

        return child.find(method, tail);
    }
}

class Router : RequestHandler
{
    private RoutingTree _tree;

    void insertHandler(Method method, string path, shared(RequestHandler) handler)
    {
        _tree.insert(method, path, handler);
    }

    void get(string path, RequestHandlerDelegate handler)
    {
        get(path, new shared(DelegateRequestHandler)(handler));
    }

    void get(string path, shared RequestHandler handler)
    {
        insertHandler(Methods.GET, path, handler);
    }

    void forwardGet(string path, string as_)
    {
        get(path, (req, res) => (cast(shared)this).doHandleRequest(as_, req, res));
    }

    void post(string path, RequestHandlerDelegate handler)
    {
        post(path, new shared(DelegateRequestHandler)(handler));
    }

    void post(string path, shared RequestHandler handler)
    {
        insertHandler(Methods.POST, path, handler);
    }

    shared(RequestHandler) findHandler(Method method, string path) shared
    {
        return _tree.find(method, path);
    }

    private void doHandleRequest(string path, Request req, Response res) shared
    {
        if (auto handler = findHandler(req.method, path))
        {
            handler.handleRequest(req, res);
            return;
        }

        // Not found
        res.status = HttpStatus.NOT_FOUND;
        res.body = format("%s %s %d %s", req.method, req.requestUri,
                cast(int) res.status, res.status.text);
    }

    void handleRequest(Request req, Response res) shared
    {
        doHandleRequest(req.requestUri.path, req, res);
    }
}

unittest
{
    class StubHandler : RequestHandler
    {
        shared int called = 0;

        void handleRequest(Request req, Response res) shared
        {
            import core.atomic;

            atomicOp!"+="(this.called, 1);
        }
    }

    auto router = new Router();
    auto handlerRoot = new shared(StubHandler)();
    auto handlerA = new shared(StubHandler)();
    auto handlerB = new shared(StubHandler)();
    auto handlerC = new shared(StubHandler)();

    router.get("/", handlerRoot);
    router.get("/a", handlerA);
    router.get("a/b", handlerB);
    router.post("/a/b", handlerB);
    router.post("/a/*", handlerC);

    auto r = cast(shared)router;

    assert(r.findHandler("GET", "/") is handlerRoot);
    assert(r.findHandler("GET", "/a") is handlerA);
    assert(r.findHandler("GET", "a") is handlerA);
    assert(r.findHandler("GET", "/a/b") is handlerB);
    assert(r.findHandler("GET", "a/b") is handlerB);
    assert(r.findHandler("GET", "/a/X") is null);
    assert(r.findHandler("GET", "a/Y") is null);
    assert(r.findHandler("GET", "b/Z/z") is null);
    assert(r.findHandler("GET", "/b/X") is null);
    assert(r.findHandler("GET", "b/Y") is null);

    assert(r.findHandler("POST", "/") is null);
    assert(r.findHandler("POST", "/a") is null);
    assert(r.findHandler("POST", "a") is null);
    assert(r.findHandler("POST", "/a/b") is handlerB);
    assert(r.findHandler("POST", "a/b") is handlerB);
    assert(r.findHandler("POST", "/a/X") is handlerC);
    assert(r.findHandler("POST", "a/Y") is handlerC);
    assert(r.findHandler("POST", "a/Z/z") is null);
    assert(r.findHandler("POST", "/b/X") is null);
    assert(r.findHandler("POST", "b/Y") is null);
}
