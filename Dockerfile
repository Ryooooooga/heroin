FROM dlanguage/dmd:latest

COPY . /app
WORKDIR /app

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y libsqlite3-dev \
    && dub build
CMD ["/app/heroin"]
