module heroin.http.request;

import std.exception : assumeUnique, enforce;
import std.regex : ctRegex, matchFirst;
import std.string : strip;
import heroin.core.stream : InputStream, StreamException;
import heroin.http : HttpException;
import heroin.http.httpbody : HttpBody;
import heroin.http.httpheaders : HttpHeaders;
import heroin.http.httpstatus : HttpStatus;

class Request
{
    private string _method;
    private string _requestUri;
    private string _httpVersion;
    private HttpHeaders _headers;
    private HttpBody _body;

    this(string method, string requestUri, string httpVersion,
            HttpHeaders headers, InputStream stream)
    in
    {
        assert(headers);
        assert(stream);
    }
    body
    {
        _method = method;
        _requestUri = requestUri;
        _httpVersion = httpVersion;
        _headers = headers;
        _body = new HttpBody(_headers, stream);
    }

    @property string method() const
    {
        return _method;
    }

    @property string requestUri() const
    {
        return _requestUri;
    }

    @property string httpVersion() const
    {
        return _httpVersion;
    }

    @property inout(HttpHeaders) headers() inout
    {
        return _headers;
    }

    @property inout(HttpBody) body_() inout
    {
        return _body;
    }

    static Request parse(InputStream stream)
    in
    {
        assert(stream);
    }
    body
    {
        try
        {
            enum CRLF = "\r\n";
            char[] line;

            // request-line
            line = stream.readUntil(CRLF);

            const requestLinePattern = ctRegex!"^(.*) (.*) (.*)\r\n$";
            const requestMatch = matchFirst(line, requestLinePattern);
            enforce(requestMatch, new HttpException(HttpStatus.BAD_REQUEST));

            const method = requestMatch[1].strip.assumeUnique();
            const requestUri = requestMatch[2].strip.assumeUnique();
            const httpVersion = requestMatch[3].strip.assumeUnique();

            // header*
            auto headers = new HttpHeaders();

            while ((line = stream.readUntil(CRLF)) != CRLF)
            {
                const headerPattern = ctRegex!"^(.*):(.*)\r\n$";
                const headerMatch = matchFirst(line, headerPattern);
                enforce(headerMatch, new HttpException(HttpStatus.BAD_REQUEST));

                const key = headerMatch[1].strip.assumeUnique();
                const value = headerMatch[2].strip.assumeUnique();

                headers.append(key, value);
            }

            return new Request(method, requestUri, httpVersion, headers, stream);
        }
        catch (StreamException e)
        {
            throw new HttpException(HttpStatus.BAD_REQUEST, null, __FILE__, __LINE__, e);
        }
    }

    unittest
    {
        import heroin.core.stream.memorystream : MemoryInputStream;

        auto r = Request.parse(new MemoryInputStream("POST / HTTP/1.1\r
Host: localhost\r
Content-Type: application/json\r
Content-Length: 13\r
\r
Hello, world!"));

        assert(r.method == "POST");
        assert(r.requestUri == "/");
        assert(r.httpVersion == "HTTP/1.1");

        assert(r.headers.fields == cast(const)[
                "host": "localhost",
                "content-type": "application/json",
                "content-length": "13"
                ]);

        assert(r.body_.text == "Hello, world!");
    }
}
