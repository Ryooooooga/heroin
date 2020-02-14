module httpserver;

import std.concurrency : spawn;
import std.socket : InternetAddress, Socket, SocketShutdown, SocketOption,
    SocketOptionLevel, TcpSocket;
import http : HttpStatus, Request, Response;
import socketstream : SocketStream;
import application : Application;

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
        _socket.setOption(SocketOptionLevel.SOCKET, SocketOption.REUSEADDR, 1);
        _socket.bind(new InternetAddress(port));
        _socket.listen(backlog);

        _app.onListened(port);

        while (true)
        {
            try
            {
                spawn(function(shared Application app, shared Socket client_socket) {
                    onConnected(app, cast() client_socket);
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
        auto response = new Response();

        try
        {
            auto request = Request.parse(new SocketStream(socket));

            app.onConnected(request, response);
        }
        catch (Throwable e)
        {
            response.status = HttpStatus.INTERNAL_SERVER_ERROR;
            response.body = e.toString();

            app.onError(e);
        }

        socket.send(response.toString());

        socket.shutdown(SocketShutdown.BOTH);
        socket.close();
    }
}
