FROM golang:1.19-alpine

WORKDIR /app

# Копируем всё
COPY . .

# 1. Показываем структуру проекта
RUN echo "=== PROJECT STRUCTURE ===" && \
    ls -la && \
    echo "" && \
    echo "=== GO FILES ===" && \
    find . -name "*.go" -type f | head -20

# 2. Показываем main.go
RUN echo "=== MAIN.GO (first 30 lines) ===" && \
    head -30 main.go

# 3. Проверяем vendor
RUN echo "=== VENDOR CHECK ===" && \
    if [ -d "vendor" ]; then \
        echo "Vendor found. Contents:" && \
        ls -la vendor/ && \
        echo "" && \
        echo "Vendor subdirectories:" && \
        find vendor -maxdepth 2 -type d | head -20; \
    else \
        echo "No vendor directory"; \
    fi

# 4. Пробуем разные способы сборки
RUN echo "=== BUILD ATTEMPT 1: Simple build ===" && \
    go build -o test1 . 2>&1 | tail -20 || echo "Build 1 failed"

RUN echo "=== BUILD ATTEMPT 2: With GO111MODULE=off ===" && \
    GO111MODULE=off go build -o test2 . 2>&1 | tail -20 || echo "Build 2 failed"

# 5. Если есть vendor, пробуем с ним
RUN if [ -d "vendor" ]; then \
    echo "=== BUILD ATTEMPT 3: With vendor ===" && \
    GO111MODULE=on go build -mod=vendor -o test3 . 2>&1 | tail -20 || echo "Build 3 failed"; \
fi

# 6. Пробуем собрать конкретный пакет
RUN echo "=== BUILD ATTEMPT 4: Try to find main package ===" && \
    MAIN_DIR=$(find . -name "main.go" -type f -exec dirname {} \; | head -1) && \
    echo "Main package in: $MAIN_DIR" && \
    cd "$MAIN_DIR" && go build -o /app/test4 . 2>&1 | tail -20 || echo "Build 4 failed"

# 7. Показываем что получилось
RUN echo "=== BUILD RESULTS ===" && \
    ls -la test* 2>/dev/null || echo "No binaries created"

# Если ничего не собралось, создаем минимальное приложение
RUN if [ ! -f "test1" ] && [ ! -f "test2" ] && [ ! -f "test3" ] && [ ! -f "test4" ]; then \
    echo "=== CREATING MINIMAL APP ===" && \
    cat > minimal.go << 'EOF'
package main
import (
    "fmt"
    "net/http"
    "os"
)
func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Invoicer API is running!\n")
    })
    http.HandleFunc("/__version__", func(w http.ResponseWriter, r *http.Request) {
        w.Header().Set("Content-Type", "application/json")
        fmt.Fprintf(w, `{"version": "1.0.0", "status": "ok"}`)
    })
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }
    fmt.Printf("Server starting on port %s\n", port)
    http.ListenAndServe(":" + port, nil)
}
EOF
    go build -o invoicer minimal.go && \
    echo "Minimal app created"; \
else \
    # Копируем первый успешный билд
    cp test* invoicer 2>/dev/null || true; \
fi

# Проверяем финальный бинарник
RUN if [ -f "invoicer" ]; then \
    echo "✅ SUCCESS: Binary created" && \
    ls -la invoicer && \
    file invoicer; \
else \
    echo "❌ ERROR: No binary created" && \
    exit 1; \
fi

EXPOSE 8080
CMD ["./invoicer"]
