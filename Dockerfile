# Dockerfile
FROM golang:1.19-alpine AS builder

WORKDIR /app
COPY . .
RUN go build -o invoicer .

FROM alpine:latest
RUN addgroup -g 10001 app && \
    adduser -G app -u 10001 -D -h /app -s /bin/nologin app

COPY --from=builder /app/invoicer /app/invoicer
COPY statics /app/statics 2>/dev/null || echo "No statics directory"

USER app
EXPOSE 8080
WORKDIR /app
CMD ["/app/invoicer"]
