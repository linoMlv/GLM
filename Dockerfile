FROM golang:1.26-alpine AS builder

ENV GOTOOLCHAIN=auto

WORKDIR /app

COPY . .

RUN go mod init zai-api && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=linux go build -o zai-api -trimpath -ldflags="-s -w" .

FROM alpine:latest

RUN apk add --no-cache ca-certificates tzdata

WORKDIR /app

COPY --from=builder /app/zai-api /app/zai-api

EXPOSE 3001

CMD ["/app/zai-api"]
