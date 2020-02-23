module heroin.core.stream.socketstream;

import std.socket : Socket;
import heroin.core.stream : InputStream;

class SocketInputStream : InputStream
{
    private Socket _socket;

    this(Socket socket)
    {
        _socket = socket;
    }

    protected override size_t readBlock(void* buffer, size_t size)
    {
        auto cbuffer = cast(ubyte*) buffer;
        const readSize = _socket.receive(cbuffer[0 .. size]);

        if (readSize <= 0)
        {
            return 0;
        }

        return cast(size_t) readSize;
    }
}
