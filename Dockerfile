# Dockerfile
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Копируем весь проект
COPY . .

# Если есть vendor, используем его
# Если нет vendor и есть go.mod/go.sum, скачиваем зависимости
RUN if [ -d "./vendor" ]; then \
        echo "Using vendor directory for dependencies"; \
    else \
        if [ -f "go.mod" ] && [ -f "go.sum" ]; then \
            echo "Downloading dependencies..."; \
            go mod download; \
        else \
            echo "No vendor directory or go.mod found, trying to build anyway..."; \
        fi; \
    fi

# Компилируем приложение
# Ищем main.go файл
RUN if [ -f "main.go" ]; then \
        CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o invoicer .; \
    else \
        echo "main.go not found, searching for Go files..."; \
        CGO_ENABLED=0 GOOS=linux go build -ldflags '-extldflags "-static"' -o invoicer ./...; \
    fi

# Финальный образ
FROM alpine:latest

# Добавляем SSL сертификаты
RUN apk add --no-cache ca-certificates

# Создаем непривилегированного пользователя
RUN addgroup -g 10001 app && \
    adduser -G app -u 10001 -D -h /app -s /bin/nologin app

WORKDIR /app

# Копируем бинарник
COPY --from=builder /app/invoicer /app/invoicer
RUN chmod +x /app/invoicer

# Копируем статические файлы если есть
RUN if [ -d "/app/statics" ]; then \
        mkdir -p /app/statics && \
        cp -r /app/statics/* /app/statics/ 2>/dev/null || true; \
    fi

# Меняем владельца
RUN chown -R app:app /app

USER app

# Порт
EXPOSE 8080

# Команда запуска
CMD ["/app/invoicer"]
