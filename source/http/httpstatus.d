module httpstatus;

enum HttpStatus : int
{
    OK = 200,
    CREATED = 201,

    BAD_REQUEST = 400,
    NOT_FOUND = 404,

    INTERNAL_SERVER_ERROR = 500,
}

string text(HttpStatus status)
{
    final switch (status)
    {
    case HttpStatus.OK:
        return "OK";
    case HttpStatus.CREATED:
        return "Created";
    case HttpStatus.BAD_REQUEST:
        return "Bad Request";
    case HttpStatus.NOT_FOUND:
        return "Not Found";
    case HttpStatus.INTERNAL_SERVER_ERROR:
        return "Internal Server Error";
    }
}
