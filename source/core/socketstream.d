module core.socketstream;

import std.socket : Socket;
import core.stream : InputStream;

class SocketStream : InputStream
{
    private Socket _socket;

    this(Socket socket)
    in
    {
        assert(socket);
    }
    body
    {
        _socket = socket;
    }

    protected override ptrdiff_t readBlock(char[] buffer)
    {
        return _socket.receive(buffer);
    }
}
