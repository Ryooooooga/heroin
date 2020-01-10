module http_server;

import std.concurrency;
import std.socket;
import std.stdio;
import std.string;
import std.algorithm.searching;
import http;

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
                worker(socket.accept());
            }
            catch (Throwable e)
            {
                stderr.writeln(e);
            }
        }
    }

    private void worker(Socket socket)
    {
        char[1024] buffer;
        string request_text;

        long length;
        while ((length = socket.receive(buffer)) > 0)
        {
            request_text ~= buffer[0 .. length];

            if (request_text.canFind("\r\n\r\n"))
            {
                break;
            }
        }

        auto request = Request.parse(request_text);
        request.writeln();

        switch (request.method.text)
        {
        case Method.GET.text:
            socket.send("HTTP/1.1 200 OK\r\n\r\n");
            break;

        case Method.HEAD.text:
            socket.send("HTTP/1.1 200 OK\r\n\r\n");
            break;

        default:
            assert(0);
        }

        socket.shutdown(SocketShutdown.BOTH);
        socket.close();
    }
}
