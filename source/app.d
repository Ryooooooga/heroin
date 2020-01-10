import std.stdio;
import http;
import server;

void main()
{
    new HttpServer().listen(3000);
}
