module httpserver;

import std.concurrency;
import std.socket;
import std.string;
import std.algorithm.searching;
import http;
import socketstream;
import application;

class HttpServer
{
    private shared Application _app;
    private TcpSocket _socket;

    this(shared Application app)
    {
        _app = app;
        _socket = new TcpSocket();
    }

    void listen(ushort port = 3000, int backlog = 10)
    {
        _socket.bind(new InternetAddress(port));
        _socket.listen(backlog);

        _app.onListened(port);

        while (true)
        {
            try
            {
                spawn(function(shared Application app, shared Socket client_socket) {
                    onConnected(app, cast(Socket) client_socket);
                }, _app, cast(shared) _socket.accept());
            }
            catch (Throwable e)
            {
                _app.onError(e);
            }
        }
    }

    private static void onConnected(shared Application app, Socket socket)
    {
        try
        {
            auto request = Request.parse(new SocketStream(socket));
            auto response = new Response();

            app.onConnected(request, response);

            socket.send(response.toString());

            socket.shutdown(SocketShutdown.BOTH);
            socket.close();
        }
        catch (Throwable e)
        {
            app.onError(e);
        }
    }
}
