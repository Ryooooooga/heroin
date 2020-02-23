module heroin.http.httpstatus;

struct HttpStatus
{
    private int _code;

    enum
    {
        // 2xx
        OK = HttpStatus(200),
        CREATED = HttpStatus(201),

        // 4xx
        BAD_REQUEST = HttpStatus(400),
        NOT_FOUND = HttpStatus(404),
        UNSUPPORTED_MEDIA_TYPE = HttpStatus(415),

        // 5xx
        INTERNAL_SERVER_ERROR = HttpStatus(500),
    }

    this(int code)
    {
        _code = code;
    }

    @property int code() const
    {
        return _code;
    }

    string toString() const
    {
        switch (_code)
        {
            // 2xx
        case OK.code:
            return "OK";
        case CREATED.code:
            return "Created";

            // 4xx
        case BAD_REQUEST.code:
            return "Bad Request";
        case NOT_FOUND.code:
            return "Not Found";
        case UNSUPPORTED_MEDIA_TYPE.code:
            return "Unsupported Media Type";

            // 5xx
        case INTERNAL_SERVER_ERROR.code:
            return "Internal Server Error";

        default:
            return "Unknown";
        }
    }
}
