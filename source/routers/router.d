module router;

import std.format;
import routers;
import httpstatus;
import request;
import response;

shared class Router : RequestHandler
{
    private RequestHandler[string][string] _handlers;

    void get(string uri, RequestHandlerDelegate handler)
    {
        get(uri, new shared(DelegateRequestHandler)(handler));
    }

    void get(string uri, shared RequestHandler handler)
    {
        _handlers[Method.GET][uri] = handler;
    }

    void get_alias(string alias_, string as_)
    {
        _handlers[Method.GET][alias_] = _handlers[Method.GET][as_];
    }

    void post(string uri, RequestHandlerDelegate handler)
    {
        post(uri, new shared(DelegateRequestHandler)(handler));
    }

    void post(string uri, shared RequestHandler handler)
    {
        _handlers[Method.POST][uri] = handler;
    }

    void handleRequest(Request req, Response res)
    {
        auto method_handlers = req.method in _handlers;
        if (method_handlers)
        {
            auto handler = req.requestUri.path in *method_handlers;
            if (handler)
            {
                handler.handleRequest(req, res);
                return;
            }
        }

        // Not found
        res.status = HttpStatus.NOT_FOUND;
        res.body = format("%s %s %d %s", req.method, req.requestUri,
                cast(int) res.status, res.status.text);
    }
}
