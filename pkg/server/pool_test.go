package server

import (
	"github.com/prometheus/common/log"
	"testing"
	"time"
)

func TestStart(t *testing.T) {
	pool := NewPool()

	for i := 0; i < 20; i++ {
		a := i
		pool.Commit(func() {
			log.Infof("task id %d", a)
			time.Sleep(10 * time.Second)
		})
	}
	select {}
}
