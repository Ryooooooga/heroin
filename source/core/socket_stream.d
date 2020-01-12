module socket_stream;

import std.socket;
import stream;

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
