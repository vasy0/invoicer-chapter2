# Создай go.mod с правильными зависимостями
cat > go.mod << 'EOF'
module github.com/Securing-DevOps/invoicer-chapter2

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
    gorm.io/driver/postgres v1.5.0
)

// Указываем использовать локальный vendor
replace (
    go.mozilla.org/mozlog => ./vendor/go.mozilla.org/mozlog
    golang.org/x/crypto => ./vendor/golang.org/x/crypto
    golang.org/x/net => ./vendor/golang.org/x/net
    golang.org/x/sys => ./vendor/golang.org/x/sys
    google.golang.org/appengine => ./vendor/google.golang.org/appengine
)
EOF
