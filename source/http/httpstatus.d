module httpstatus;

enum HttpStatus : int
{
    OK = 200,
}

string text(HttpStatus status)
{
    final switch (status)
    {
    case HttpStatus.OK:
        return "OK";
    }
}
