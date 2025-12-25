# Dockerfile для проекта с vendor
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Копируем всё
COPY . .

# Проверяем структуру
RUN echo "=== Project structure ===" && \
    ls -la && \
    echo "=== Vendor exists ===" && \
    [ -d "vendor" ] && echo "✓ Vendor directory found"

# Создаем go.mod если его нет
RUN if [ ! -f "go.mod" ]; then \
        echo "Creating go.mod..." && \
        cat > go.mod << 'MOD'
module invoicer-app

go 1.16

require (
    github.com/gin-gonic/gin v1.9.0
    github.com/lib/pq v1.10.9
    go.mozilla.org/mozlog v0.0.0
    golang.org/x/crypto v0.0.0
    golang.org/x/net v0.0.0
    golang.org/x/sys v0.0.0
    google.golang.org/appengine v1.6.7
    gorm.io/gorm v1.25.0
)

replace (
    go.mozilla.org/mozlog => ./vendor/go.mozilla.org/mozlog
    golang.org/x/crypto => ./vendor/golang.org/x/crypto
    golang.org/x/net => ./vendor/golang.org/x/net
    golang.org/x/sys => ./vendor/golang.org/x/sys
    google.golang.org/appengine => ./vendor/google.golang.org/appengine
)
MOD
    fi

# Собираем приложение с использованием vendor
RUN echo "=== Building application ===" && \
    CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -mod=vendor -a \
    -ldflags="-w -s -extldflags '-static'" \
    -o invoicer .

# Проверяем бинарник
RUN ls -la invoicer && \
    echo "✅ Build successful! Binary size:" && \
    du -h invoicer

# Финальный образ
FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

# Создаем непривилегированного пользователя
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Копируем бинарник
COPY --from=builder --chown=appuser:appgroup /app/invoicer /app/invoicer

# Копируем статические файлы
COPY --from=builder --chown=appuser:appgroup /app/statics /app/statics 2>/dev/null || true

# Делаем исполняемым
RUN chmod +x /app/invoicer

USER appuser

EXPOSE 8080

# Переменные окружения
ENV PORT=8080
ENV GIN_MODE=release

CMD ["/app/invoicer"]
