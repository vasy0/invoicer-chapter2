# Этап сборки
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .

# Загружаем зависимости
RUN go mod download

# Компилируем статический бинарник
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o invoicer ./main.go

# Этап запуска
FROM alpine:latest

# Создаем непривилегированного пользователя
RUN addgroup -g 10001 app && \
    adduser -G app -u 10001 -D -h /app -s /bin/nologin app

WORKDIR /app

# Копируем бинарник
COPY --from=builder /app/invoicer /app/invoicer
RUN chmod +x /app/invoicer

# Меняем владельца
RUN chown -R app:app /app

USER app

# Открываем порт
EXPOSE 8080

# Переменные окружения для Render
ENV PORT=8080

# Запускаем приложение
ENTRYPOINT ["/app/invoicer"]
