FROM alpine:3.12.1 AS stage1
RUN apk update && apk add --update alpine-sdk
RUN mkdir /app
WORKDIR /app
COPY code.c .
RUN mkdir bin/
RUN gcc -Wall code.c -o bin/code
FROM alpine:3.12.1
COPY --from=stage1 /app/bin/code /app/code
CMD /app/code
