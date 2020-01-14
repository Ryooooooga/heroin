module file_renderer;

import std.file;
import std.path;
import std.exception;
import request;
import response;
import httpstatus;

immutable string[string] knownContentTypes;

pure shared static this()
{
    knownContentTypes = [
        ".html": "text/html; charset=utf-8",
        ".css": "text/css; charset=utf-8",
        ".js": "text/javascript; charset=utf-8",
        ".json": "application/json; charset=utf-8",
    ];
}

void render_file(Request req, Response res, string file, string contentType = null)
{
    try
    {
        if (contentType is null)
        {
            const estimatedContentType = file.extension in knownContentTypes;
            if (estimatedContentType)
            {
                contentType = *estimatedContentType;
            }
        }

        const content = cast(string) read(file);

        res.headers["Content-Type"] = contentType;
        res.body = content;
    }
    catch (FileException e)
    {
        res.status = HttpStatus.NOT_FOUND;
        res.body = e.toString();
    }
}
