package kafka

import (
	"context"
	"encoding/json"
	"log"
	stdSync "sync"
	"strings"

	"sml-fleet/internal/database"

	kafkago "github.com/segmentio/kafka-go"
)

// FleetConsumer อ่าน Kafka events แล้ว route ไปยัง handler
type FleetConsumer struct {
	brokers []string
	groupID string
	pgDB    *database.PostgresDB
	readers map[string]*kafkago.Reader
	mu      stdSync.Mutex
}

// Topics ทั้งหมดที่ FleetConsumer ต้องฟัง
var FleetTopics = []string{
	"fleet.vehicles",
	"fleet.drivers",
	"fleet.trips",
	"fleet.maintenance",
	"fleet.partners",
	"fleet.expenses",
	"fleet.gps",
	"fleet.alerts",
	"fleet.parts",
	"fleet.movement.analysis",
	"fleet.customers",
}

// NewFleetConsumer สร้าง FleetConsumer
func NewFleetConsumer(brokers, groupID string, pgDB *database.PostgresDB) *FleetConsumer {
	return &FleetConsumer{
		brokers: strings.Split(brokers, ","),
		groupID: groupID,
		pgDB:    pgDB,
		readers: make(map[string]*kafkago.Reader),
	}
}

// getReader ดึง Reader สำหรับ topic (สร้างใหม่ถ้ายังไม่มี)
func (fc *FleetConsumer) getReader(topic string) *kafkago.Reader {
	fc.mu.Lock()
	defer fc.mu.Unlock()

	if r, ok := fc.readers[topic]; ok {
		return r
	}

	r := kafkago.NewReader(kafkago.ReaderConfig{
		Brokers:  fc.brokers,
		GroupID:  fc.groupID,
		Topic:    topic,
		MinBytes: 1,
		MaxBytes: 10e6, // 10 MB
	})
	fc.readers[topic] = r
	return r
}

// Start เริ่ม consume messages จากทุก topic พร้อมกัน
func (fc *FleetConsumer) Start(ctx context.Context) error {
	syncer := NewFleetSyncConsumer(
		strings.Join(fc.brokers, ","),
		fc.groupID,
		fc.pgDB,
	)

	var wg stdSync.WaitGroup
	for _, topic := range FleetTopics {
		wg.Add(1)
		go func(t string) {
			defer wg.Done()
			fc.consumeTopic(ctx, t, syncer)
		}(topic)
	}

	wg.Wait()
	return nil
}

// consumeTopic อ่าน messages จาก topic แล้ว route ไป handler
func (fc *FleetConsumer) consumeTopic(ctx context.Context, topic string, sync *FleetSyncConsumer) {
	reader := fc.getReader(topic)
	log.Printf("[Kafka Consumer] เริ่มฟัง topic: %s", topic)

	for {
		select {
		case <-ctx.Done():
			log.Printf("[Kafka Consumer] หยุดฟัง topic: %s", topic)
			return
		default:
			msg, err := reader.ReadMessage(ctx)
			if err != nil {
				if ctx.Err() != nil {
					return
				}
				log.Printf("[Kafka Consumer] อ่าน topic %s ล้มเหลว: %v", topic, err)
				continue
			}

			var event database.KafkaEvent
			if err := json.Unmarshal(msg.Value, &event); err != nil {
				log.Printf("[Kafka Consumer] parse event ล้มเหลว [%s]: %v", topic, err)
				continue
			}

			if err := sync.HandleEvent(event); err != nil {
				log.Printf("[Kafka Consumer] HandleEvent ล้มเหลว [%s/%s]: %v", topic, event.Type, err)
			}
		}
	}
}

// Close ปิด readers ทั้งหมด
func (fc *FleetConsumer) Close() {
	fc.mu.Lock()
	defer fc.mu.Unlock()

	for topic, r := range fc.readers {
		if err := r.Close(); err != nil {
			log.Printf("[Kafka Consumer] ปิด reader %s ล้มเหลว: %v", topic, err)
		}
	}
}
