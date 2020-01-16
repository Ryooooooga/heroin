module routers;

public import router;

import request;
import response;

interface RequestHandler
{
    void handleRequest(Request, Response) shared;
}

alias RequestHandlerDelegate = void delegate(Request, Response);

class DelegateRequestHandler : RequestHandler
{
    private RequestHandlerDelegate _delegate;

    this(RequestHandlerDelegate delegate_) shared
    {
        _delegate = delegate_;
    }

    void handleRequest(Request req, Response res) shared
    {
        _delegate(req, res);
    }
}
