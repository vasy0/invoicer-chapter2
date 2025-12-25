# Dockerfile
FROM golang:1.19-alpine AS builder

WORKDIR /app

# Копируем исходный код
COPY . .

# Собираем бинарник
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o invoicer .

# Финальный образ
FROM alpine:latest

# Создаем пользователя app
RUN addgroup -g 10001 app && \
    adduser -G app -u 10001 -D -h /app -s /bin/nologin app

# Создаем директорию для статики
RUN mkdir -p /app/statics

# Копируем бинарник из builder
COPY --from=builder /app/invoicer /app/invoicer

# Копируем статику из исходного кода
COPY --from=builder /app/statics /app/statics 2>/dev/null || echo "No statics found"

USER app
EXPOSE 8080
WORKDIR /app
ENTRYPOINT ["/app/invoicer"]
