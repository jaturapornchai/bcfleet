package database

import (
	"context"
	"encoding/json"
	"log"
	"strings"
	"time"

	kafkago "github.com/segmentio/kafka-go"
)

// KafkaEvent โครงสร้าง event ที่ส่งผ่าน Kafka
type KafkaEvent struct {
	Type      string      `json:"type"`
	ShopID    string      `json:"shop_id"`
	EntityID  string      `json:"entity_id"`
	Payload   interface{} `json:"payload"`
	Timestamp time.Time   `json:"timestamp"`
	EventID   string      `json:"event_id"`
}

// KafkaProducer สำหรับส่ง events ไป Kafka
type KafkaProducer struct {
	writers map[string]*kafkago.Writer
	brokers string
}

// NewKafkaProducer สร้าง Kafka producer
func NewKafkaProducer(brokers string) *KafkaProducer {
	return &KafkaProducer{
		writers: make(map[string]*kafkago.Writer),
		brokers: brokers,
	}
}

// getWriter ดึง writer สำหรับ topic (สร้างใหม่ถ้ายังไม่มี)
func (kp *KafkaProducer) getWriter(topic string) *kafkago.Writer {
	if w, ok := kp.writers[topic]; ok {
		return w
	}
	w := &kafkago.Writer{
		Addr:         kafkago.TCP(strings.Split(kp.brokers, ",")...),
		Topic:        topic,
		Balancer:     &kafkago.LeastBytes{},
		BatchTimeout: 10 * time.Millisecond,
	}
	kp.writers[topic] = w
	return w
}

// Produce ส่ง event ไปยัง Kafka topic
func (kp *KafkaProducer) Produce(topic string, event KafkaEvent) error {
	data, err := json.Marshal(event)
	if err != nil {
		return err
	}

	writer := kp.getWriter(topic)
	err = writer.WriteMessages(context.Background(), kafkago.Message{
		Key:   []byte(event.EntityID),
		Value: data,
	})
	if err != nil {
		log.Printf("Kafka produce error [%s]: %v", topic, err)
		return err
	}
	return nil
}

// Close ปิด writers ทั้งหมด
func (kp *KafkaProducer) Close() {
	for _, w := range kp.writers {
		w.Close()
	}
}
