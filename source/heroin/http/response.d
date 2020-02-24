module heroin.http.response;

import heroin.http.httpheaders : HttpHeaders;
import heroin.http.httpstatus : HttpStatus;
import heroin.http.httpversion : HttpVersion;

class Response
{
    private string _httpVersion;
    private HttpStatus _status;
    private HttpHeaders _headers;
    private string _body;

    this(string httpVersion, HttpStatus status)
    {
        _httpVersion = httpVersion;
        _status = status;
        _headers = new HttpHeaders();
    }

    @property string httpVersion() const
    {
        return _httpVersion;
    }

    @property void httpVersion(string httpVersion)
    {
        _httpVersion = httpVersion;
    }

    @property HttpStatus status() const
    {
        return _status;
    }

    @property void status(HttpStatus status)
    {
        _status = status;
    }

    @property inout(HttpHeaders) headers() inout
    {
        return _headers;
    }

    @property string body_() const
    {
        return _body;
    }

    @property void body_(string body_)
    {
        _body = body_;
    }

    unittest
    {
        auto r = new Response(HttpVersion.HTTP_1_1, HttpStatus.OK);

        assert(r.httpVersion == HttpVersion.HTTP_1_1);
        assert(r.status == HttpStatus.OK);
        assert(r.headers.fields == null);
        assert(r.body_ == "");
    }

    override string toString() const
    {
        import std.format : format;
        import std.outbuffer : OutBuffer;

        auto o = new OutBuffer();

        // response-line
        switch (_httpVersion)
        {
        case HttpVersion.HTTP_1_1:
            o.writef("%s %s %s\r\n", _httpVersion,
                    _status.code, _status.toString());
            break;

        default:
            throw new Exception("Unsupported HTTP version %s".format(_httpVersion));
        }

        // header*
        foreach (key, value; _headers.fields)
        {
            o.writef("%s: %s\r\n", key, value);
        }

        o.write("\r\n");
        o.write(_body);

        return o.toString();
    }

    unittest
    {
        auto r = new Response(HttpVersion.HTTP_1_1, HttpStatus.OK);
        r.body_ = "<html><body>Hello, world!</body></html>";
        r.headers.contentLength = r.body_.length;

        assert(r.toString() == "HTTP/1.1 200 OK\r
content-length: 39\r
\r
<html><body>Hello, world!</body></html>");
    }
}
