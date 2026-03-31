package kafka

import (
	"fmt"
	"time"

	"sml-fleet/internal/database"

	"github.com/google/uuid"
)

// FleetProducer wraps database.KafkaProducer สำหรับ fleet events
type FleetProducer struct {
	producer *database.KafkaProducer
}

// NewFleetProducer สร้าง FleetProducer
func NewFleetProducer(producer *database.KafkaProducer) *FleetProducer {
	return &FleetProducer{producer: producer}
}

// ProduceEvent ส่ง event ไปยัง Kafka topic
func (fp *FleetProducer) ProduceEvent(topic, eventType, shopID, entityID string, payload interface{}) error {
	if topic == "" || eventType == "" || shopID == "" {
		return fmt.Errorf("topic, eventType และ shopID ต้องไม่ว่าง")
	}

	event := database.KafkaEvent{
		Type:      eventType,
		ShopID:    shopID,
		EntityID:  entityID,
		Payload:   payload,
		Timestamp: time.Now(),
		EventID:   uuid.New().String(),
	}

	return fp.producer.Produce(topic, event)
}

// ProduceVehicleEvent ส่ง event สำหรับ vehicle
func (fp *FleetProducer) ProduceVehicleEvent(eventType, shopID, vehicleID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.vehicles", eventType, shopID, vehicleID, payload)
}

// ProduceDriverEvent ส่ง event สำหรับ driver
func (fp *FleetProducer) ProduceDriverEvent(eventType, shopID, driverID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.drivers", eventType, shopID, driverID, payload)
}

// ProduceTripEvent ส่ง event สำหรับ trip
func (fp *FleetProducer) ProduceTripEvent(eventType, shopID, tripID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.trips", eventType, shopID, tripID, payload)
}

// ProduceMaintenanceEvent ส่ง event สำหรับ maintenance work order
func (fp *FleetProducer) ProduceMaintenanceEvent(eventType, shopID, woID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.maintenance", eventType, shopID, woID, payload)
}

// ProducePartnerEvent ส่ง event สำหรับ partner vehicle
func (fp *FleetProducer) ProducePartnerEvent(eventType, shopID, partnerID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.partners", eventType, shopID, partnerID, payload)
}

// ProduceExpenseEvent ส่ง event สำหรับ expense
func (fp *FleetProducer) ProduceExpenseEvent(eventType, shopID, expenseID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.expenses", eventType, shopID, expenseID, payload)
}

// ProduceGPSEvent ส่ง GPS location event (high frequency)
func (fp *FleetProducer) ProduceGPSEvent(shopID, vehicleID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.gps", "gps.location_updated", shopID, vehicleID, payload)
}

// ProduceAlertEvent ส่ง alert event
func (fp *FleetProducer) ProduceAlertEvent(eventType, shopID, alertID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.alerts", eventType, shopID, alertID, payload)
}

// ProducePartsEvent ส่ง parts inventory event
func (fp *FleetProducer) ProducePartsEvent(eventType, shopID, partID string, payload interface{}) error {
	return fp.ProduceEvent("fleet.parts", eventType, shopID, partID, payload)
}
