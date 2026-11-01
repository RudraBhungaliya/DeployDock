package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"deploydock/build-server/internal/handler"
)

func main() {
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()
	os.Exit(handler.Run(ctx))
}
