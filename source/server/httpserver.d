module server.httpserver;

import std.concurrency : spawn;
import std.socket : InternetAddress, Socket, SocketShutdown, SocketOption,
    SocketOptionLevel, TcpSocket;
import http : HttpStatus, Request, Response;
import core.socketstream : SocketStream;
import applications.application : Application;

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
                spawn(function(shared HttpServer self, shared Socket client_socket) {
                    onConnected(self, cast() client_socket);
                }, cast(shared) this, cast(shared) _socket.accept());
            }
            catch (Throwable e)
            {
                _app.onError(e);
            }
        }
    }

    private static void onConnected(shared HttpServer self, Socket socket)
    {
        auto response = new Response();

        try
        {
            auto request = Request.parse(new SocketStream(socket));

            self._app.onConnected(request, response);
        }
        catch (Throwable e)
        {
            response.status = HttpStatus.INTERNAL_SERVER_ERROR;
            response.body = e.toString();

            self._app.onError(e);
        }

        socket.send(response.toString());

        socket.shutdown(SocketShutdown.BOTH);
        socket.close();
    }
}
