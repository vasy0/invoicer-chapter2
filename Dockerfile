# Этап сборки
FROM golang:1.21-alpine AS builder

# Устанавливаем git для загрузки зависимостей
RUN apk add --no-cache git

WORKDIR /app

# Сначала копируем файлы зависимостей
COPY go.mod go.sum ./
RUN go mod download

# Затем копируем остальной код
COPY . .

# Компилируем статический бинарник
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o invoicer .

# Этап запуска
FROM alpine:latest

# Устанавливаем CA certificates для HTTPS
RUN apk add --no-cache ca-certificates

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

# Переменные окружения
ENV PORT=8080

# Запускаем приложение
CMD ["/app/invoicer"]
