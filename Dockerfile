FROM golang:1.24-alpine AS builder

ENV GOTOOLCHAIN=auto

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build \
    -ldflags="-X main.Version=render -X main.GitCommit=unknown -X main.BuildTime=unknown" \
    -o bin/registry \
    ./cmd/registry


FROM alpine:3.21

RUN apk --no-cache add ca-certificates

WORKDIR /app

COPY --from=builder /app/bin/registry ./registry
COPY --from=builder /app/data ./data

EXPOSE 8080

CMD ["./registry"]
