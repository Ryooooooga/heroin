module heroin.http;

public import heroin.http.httpbody;
public import heroin.http.httpheader;
public import heroin.http.httpstatus;

class HttpException : Exception
{
    private HttpStatus _status;
    private string _description;

    this(HttpStatus status)
    {
        this(status, status.toString());
    }

    this(HttpStatus status, string description)
    {
        import std.format : format;

        _status = status;
        _description = description;

        super("HttpException status: %d %s, description: %s".format(_status.code,
                _status, _description));
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
