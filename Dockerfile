# Dockerfile
FROM golang:1.19-alpine

WORKDIR /app
COPY . .

# Просто собираем без сложных условий
RUN go build -o invoicer .

EXPOSE 8080
CMD ["./invoicer"]
