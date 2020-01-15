FROM dlanguage/dmd:latest

COPY . /app
WORKDIR /app

RUN dub build
CMD ["/app/heroin"]
