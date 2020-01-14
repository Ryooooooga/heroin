module application;

import request;

shared interface Application
{
    void onListened(ushort port);
    void onConnected(Request req);
    void onError(Throwable e);
}
