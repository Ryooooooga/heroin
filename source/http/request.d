struct Method {
    static immutable string GET = "GET";
    static immutable string POST = "POST";
    static immutable string PUT = "PUT";
    static immutable string DELETE = "DELETE";
    static immutable string HEAD = "HEAD";

    string method;
}

struct HttpVersion {
    static immutable string HTTP_1_1 = "HTTP/1.1";

    string http_version;
}

struct Request {
    Method method;
    string path;
    HttpVersion http_version;
    string[string] headers;
    string body;
}
