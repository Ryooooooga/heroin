module routers;

public import router;

import request;
import response;

shared interface RequestHandler
{
    void handleRequest(Request, Response);
}

alias RequestHandlerDelegate = void delegate(Request, Response);

shared class DelegateRequestHandler : RequestHandler
{
    private RequestHandlerDelegate _delegate;

    this(RequestHandlerDelegate delegate_)
    {
        _delegate = delegate_;
    }

    void handleRequest(Request req, Response res)
    {
        _delegate(req, res);
    }
}
