module markdown_renderer;

import std.file;
import std.path;
import std.exception;
import dmarkdown.markdown;
import routers;
import request;
import response;
import httpstatus;

RequestHandlerDelegate render_md(string file)
{
    return (req, res) {
        try
        {
            const markdown = readText(file);
            const content = markdown.filterMarkdown(
                    MarkdownFlags.githubInspired | MarkdownFlags.noInlineHtml);

            res.headers["Content-Type"] = "text/html; charset=utf-8";
            res.body = content;
        }
        catch (FileException e)
        {
            res.status = HttpStatus.NOT_FOUND;
            res.body = e.toString();
        }
    };
}
