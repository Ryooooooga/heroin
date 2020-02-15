module applications.application;

import http : Request, Response;

shared interface Application
{
    void onListened(ushort port);
    void onConnected(Request req, Response res);
    void onError(Throwable e);
}
