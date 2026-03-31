FROM golang:1.23-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -o api cmd/api/main.go
RUN CGO_ENABLED=0 go build -o kafka-consumer cmd/kafka-consumer/main.go
RUN CGO_ENABLED=0 go build -o rebuild-pgsql cmd/rebuild-pgsql/main.go

FROM alpine:3.20
RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Bangkok

WORKDIR /app
COPY --from=builder /app/api .
COPY --from=builder /app/kafka-consumer .
COPY --from=builder /app/rebuild-pgsql .

EXPOSE 8080
CMD ["./api"]
