module application;

import request;
import response;

shared interface Application
{
    void onListened(ushort port);
    void onConnected(Request req, Response res);
    void onError(Throwable e);
}
