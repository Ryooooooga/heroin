module httpstatus;

enum HttpStatus : int
{
    OK = 200,

    NOT_FOUND = 404
}

string text(HttpStatus status)
{
    final switch (status)
    {
    case HttpStatus.OK:
        return "OK";
    case HttpStatus.NOT_FOUND:
        return "Not Found";
    }
}
