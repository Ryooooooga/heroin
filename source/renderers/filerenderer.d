module renderers.filerenderer;

import std.file : FileException, read;
import std.path : extension;
import routers : RequestHandlerDelegate;
import http : HttpStatus, Request, Response;

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

void renderFile(Request req, Response res, string file, string contentType = null)
{
    try
    {
        if (contentType is null)
        {
            if (const estimatedContentType = file.extension in knownContentTypes)
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
