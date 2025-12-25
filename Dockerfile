# Используем многоступенчатую сборку для безопасности
# Этап сборки
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY . .

# Компилируем статический бинарник
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o invoicer ./main.go

# Этап запуска
FROM alpine:latest

# Создаем непривилегированного пользователя
RUN addgroup -g 10001 app && \
    adduser -G app -u 10001 -D -h /app -s /bin/nologin app

WORKDIR /app

# Копируем бинарник из этапа сборки
COPY --from=builder /app/invoicer /app/invoicer

# Копируем статические файлы (если есть)
COPY --from=builder /app/static /app/static
COPY --from=builder /app/templates /app/templates

# Меняем владельца
RUN chown -R app:app /app

USER app

# Открываем порт
EXPOSE 8080

# Запускаем приложение
ENTRYPOINT ["/app/invoicer"]
