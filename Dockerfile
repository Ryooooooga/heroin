FROM dlanguage/dmd:latest

COPY . /src

CMD [ "dub" ]
