module http_server;

import std.concurrency;
import std.socket;
import std.stdio;
import std.string;
import std.algorithm.searching;
import http;
import socket_stream;

class HttpServer
{
    private TcpSocket socket;

    this()
    {
        socket = new TcpSocket();
    }

    void listen(ushort port = 3000, int backlog = 10)
    {
        socket.bind(new InternetAddress(port));
        socket.listen(backlog);

        writef("server listening at port %d...\n", port);

        while (true)
        {
            try
            {
                spawn(function(shared Socket client_socket) {
                    onConnect(cast(Socket) client_socket);
                }, cast(shared) socket.accept());
            }
            catch (Throwable e)
            {
                stderr.writeln(e);
            }
        }
    }

    private static void onConnect(Socket socket)
    {
        auto request = Request.parse(new SocketStream(socket));

        switch (request.method)
        {
        case Method.GET:
            socket.send("HTTP/1.1 200 OK\r\n\r\n");
            break;

        case Method.HEAD:
            socket.send("HTTP/1.1 200 OK\r\n\r\n");
            break;

        default:
            assert(0);
        }

        socket.shutdown(SocketShutdown.BOTH);
        socket.close();
    }
}
