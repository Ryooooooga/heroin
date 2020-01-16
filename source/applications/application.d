module application;

import request;
import response;

interface Application
{
    void onListened(ushort port) shared;
    void onConnected(Request req, Response res) shared;
    void onError(Throwable e) shared;
}
