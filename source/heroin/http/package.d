module heroin.http;

public import heroin.http.httpbody;
public import heroin.http.httpheaders;
public import heroin.http.httpstatus;
public import heroin.http.httpversion;
public import heroin.http.request;
public import heroin.http.response;

class HttpException : Exception
{
    private HttpStatus _status;
    private string _description;

    this(HttpStatus status, string description = null, string file = __FILE__,
            size_t line = __LINE__, Throwable next = null)
    {
        import std.format : format;

        _status = status;
        _description = description ? description : _status.toString();

        string message = "HttpException status: %d %s, description: %s".format(_status.code,
                _status, _description);

        super(message, file, line, next);
    }

    @property HttpStatus status() const
    {
        return _status;
    }

    @property string description() const
    {
        return _description;
    }
}
