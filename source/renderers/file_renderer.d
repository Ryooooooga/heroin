module file_renderer;

import std.file;
import std.path;
import std.exception;
import routers;
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

RequestHandlerDelegate render_file(string file, string contentType = null)
{
    return (req, res) {
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
    };
}
