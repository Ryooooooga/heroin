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

    bool handleRequest(Request req, Response res, Method method, string path) shared
    {
        // '/a/b' -> 'a/b'
        path.skipOver('/');

        if (path.length == 0)
        {
            if (auto handler = method in _handlers)
            {
                handler.handleRequest(req, res);
                return true;
            }
            else
            {
                return false;
            }
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
                return false;
            }
        }

        return child.handleRequest(req, res, method, tail);
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
        get(path, (req, res) => (cast(shared) this).doHandleRequest(as_, req, res));
    }

    void post(string path, RequestHandlerDelegate handler)
    {
        post(path, new shared(DelegateRequestHandler)(handler));
    }

    void post(string path, shared RequestHandler handler)
    {
        insertHandler(Methods.POST, path, handler);
    }

    private void doHandleRequest(string path, Request req, Response res) shared
    {
        if (_tree.handleRequest(req, res, req.method, path))
        {
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
    import uri : Uri;
    import http : HttpVersions;

    class StubHandler : RequestHandler
    {
        bool accepting = false;

        void handleRequest(Request req, Response res) shared
        {
            assert(accepting);
            res.status = HttpStatus.OK;
            res.body = "OK!";
        }
    }

    void checkRequestOK(Router router, Method method, string path, shared(StubHandler) handler)
    {
        auto req = new Request();
        req.method = method;
        req.requestUri = new Uri(path);
        req.httpVersion = HttpVersions.HTTP_1_1;

        auto res = new Response();

        handler.accepting = true;
        (cast(shared) router).handleRequest(req, res);
        handler.accepting = false;

        assert(res.status == HttpStatus.OK);
        assert(res.body == "OK!");
    }

    void checkRequest404(Router router, Method method, string path)
    {
        auto req = new Request();
        req.method = method;
        req.requestUri = new Uri(path);
        req.httpVersion = HttpVersions.HTTP_1_1;

        auto res = new Response();

        (cast(shared) router).handleRequest(req, res);

        assert(res.status == HttpStatus.NOT_FOUND);
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

    checkRequestOK(router, "GET", "/", handlerRoot);
    checkRequestOK(router, "GET", "/a", handlerA);
    checkRequestOK(router, "GET", "a", handlerA);
    checkRequestOK(router, "GET", "/a/b", handlerB);
    checkRequestOK(router, "GET", "a/b", handlerB);
    checkRequest404(router, "GET", "/a/X");
    checkRequest404(router, "GET", "a/Y");
    checkRequest404(router, "GET", "b/Z/z");
    checkRequest404(router, "GET", "/b/X");
    checkRequest404(router, "GET", "b/Y");

    checkRequest404(router, "POST", "/");
    checkRequest404(router, "POST", "/a");
    checkRequest404(router, "POST", "a");
    checkRequestOK(router, "POST", "/a/b", handlerB);
    checkRequestOK(router, "POST", "a/b", handlerB);
    checkRequestOK(router, "POST", "/a/X", handlerC);
    checkRequestOK(router, "POST", "a/Y", handlerC);
    checkRequest404(router, "POST", "a/Z/z");
    checkRequest404(router, "POST", "/b/X");
    checkRequest404(router, "POST", "b/Y");
}
