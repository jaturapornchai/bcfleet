# BC Fleet UCP Manifest

UCP (Universal Commerce Protocol) — มาตรฐาน open protocol สำหรับ AI Agent ซื้อ-ขายบริการ

---

## Manifest JSON

```json
{
  "protocol": "ucp",
  "version": "1.0",
  "merchant": {
    "name": "{{shop_name}}",
    "category": "transportation",
    "subcategory": "freight",
    "coverage": ["เชียงใหม่", "ลำพูน", "เชียงราย", "ลำปาง"],
    "currency": "THB",
    "timezone": "Asia/Bangkok",
    "language": "th"
  },
  "capabilities": {
    "discovery": {
      "endpoint": "/ucp/discovery",
      "methods": ["service_catalog", "availability", "coverage_area"]
    },
    "cart": {
      "endpoint": "/ucp/cart",
      "methods": ["create_booking", "get_quote", "update_booking"]
    },
    "checkout": {
      "endpoint": "/ucp/checkout",
      "methods": ["process_payment"],
      "payment_methods": ["promptpay", "bank_transfer", "stripe"],
      "requires_customer_input": [
        "delivery_date",
        "pickup_address",
        "destination_address",
        "cargo_description",
        "cargo_weight_kg"
      ]
    },
    "fulfillment": {
      "endpoint": "/ucp/fulfillment",
      "methods": ["track_delivery", "get_pod", "confirm_delivery"]
    },
    "identity": {
      "endpoint": "/ucp/identity",
      "methods": ["merchant_profile"]
    }
  },
  "mcp_compatible": true,
  "a2a_agent_card": "/ucp/agent-card.json"
}
```

---

## A2A Agent Card

```json
{
  "name": "BC Fleet Transport Agent",
  "description": "AI Agent สำหรับจัดการรถขนส่ง SME ไทย — จอง ติดตาม และรับ POD",
  "url": "https://fleet.bcaccount.com/a2a",
  "version": "1.0",
  "capabilities": [
    "transport.freight.booking",
    "transport.freight.tracking",
    "transport.freight.pricing",
    "transport.freight.pod"
  ],
  "authentication": {
    "type": "api_key",
    "header": "X-Agent-Key"
  },
  "languages": ["th", "en"],
  "contact": {
    "email": "api@bcaccount.com",
    "line": "@bcfleet"
  }
}
```

---

## UCP Endpoints

### Discovery

#### `GET /ucp/manifest`
ดึง UCP manifest JSON

**Response:** manifest JSON ด้านบน

---

#### `POST /ucp/discovery/catalog`
รายการบริการขนส่งที่มีให้

**Request:**
```json
{
  "shop_id": "shop_001"
}
```

**Response:**
```json
{
  "services": [
    {
      "id": "freight_4wheel",
      "name": "รถ 4 ล้อ",
      "description": "สำหรับสินค้าทั่วไป น้ำหนักไม่เกิน 2 ตัน",
      "max_weight_kg": 2000,
      "base_price": 800,
      "price_per_km": 8,
      "available": true
    },
    {
      "id": "freight_6wheel",
      "name": "รถ 6 ล้อ",
      "description": "สินค้าขนาดกลาง น้ำหนักไม่เกิน 6 ตัน",
      "max_weight_kg": 6000,
      "base_price": 1500,
      "price_per_km": 12,
      "available": true
    },
    {
      "id": "freight_10wheel",
      "name": "รถ 10 ล้อ",
      "description": "สินค้าหนัก น้ำหนักไม่เกิน 15 ตัน",
      "max_weight_kg": 15000,
      "base_price": 2500,
      "price_per_km": 18,
      "available": true
    }
  ]
}
```

---

#### `POST /ucp/discovery/availability`
ตรวจสอบรถว่าง

**Request:**
```json
{
  "shop_id": "shop_001",
  "service_id": "freight_6wheel",
  "date": "2024-12-20",
  "zone": "ลำพูน"
}
```

**Response:**
```json
{
  "available": true,
  "vehicles_count": 2,
  "earliest_time": "06:00",
  "slots": ["06:00", "08:00", "10:00", "14:00"]
}
```

---

#### `POST /ucp/discovery/coverage`
พื้นที่ให้บริการ

**Request:** `{ "shop_id": "shop_001" }`

**Response:**
```json
{
  "provinces": ["เชียงใหม่", "ลำพูน", "เชียงราย", "ลำปาง"],
  "zones": [
    { "name": "เชียงใหม่-ลำพูน", "distance_km": 25, "avg_duration_min": 30 },
    { "name": "เชียงใหม่-ลำปาง", "distance_km": 100, "avg_duration_min": 90 },
    { "name": "เชียงใหม่-เชียงราย", "distance_km": 180, "avg_duration_min": 150 }
  ]
}
```

---

### Cart

#### `POST /ucp/cart/quote`
ขอใบเสนอราคา

**Request:**
```json
{
  "shop_id": "shop_001",
  "service_id": "freight_6wheel",
  "pickup_address": "123 ถ.เชียงใหม่-ลำปาง ต.ช้างเผือก",
  "delivery_address": "456 ถ.ลำพูน ต.เวียง จ.ลำพูน",
  "delivery_date": "2024-12-20",
  "cargo_weight_kg": 3000,
  "cargo_description": "ปูนซีเมนต์ 100 ถุง"
}
```

**Response:**
```json
{
  "quote_id": "QT-2024-001234",
  "valid_until": "2024-12-19T23:59:59+07:00",
  "distance_km": 28,
  "duration_min": 35,
  "price_breakdown": {
    "base_price": 1500,
    "distance_charge": 336,
    "fuel_surcharge": 0,
    "total": 1836
  },
  "currency": "THB"
}
```

---

#### `POST /ucp/cart/booking`
จองเที่ยวรถ

**Request:**
```json
{
  "quote_id": "QT-2024-001234",
  "shop_id": "shop_001",
  "customer": {
    "name": "บจก.วัสดุก่อสร้าง",
    "phone": "089-123-4567",
    "line_id": "@material_co"
  },
  "pickup": {
    "address": "123 ถ.เชียงใหม่-ลำปาง",
    "contact_name": "สมศรี",
    "contact_phone": "089-234-5678",
    "time": "2024-12-20T06:00:00+07:00"
  },
  "delivery": {
    "address": "456 ถ.ลำพูน",
    "contact_name": "สมปอง",
    "contact_phone": "089-345-6789"
  }
}
```

**Response:**
```json
{
  "booking_id": "BK-2024-001234",
  "trip_id": "TRIP-2024-001234",
  "status": "pending",
  "payment_required": true,
  "payment_methods": ["promptpay", "bank_transfer"],
  "total_amount": 1836,
  "currency": "THB"
}
```

---

#### `PUT /ucp/cart/booking/:id`
แก้ไขการจอง

**Request:** fields ที่ต้องการแก้ไข (delivery_date, address, cargo)

---

### Checkout

#### `POST /ucp/checkout/payment`
ชำระเงิน

**Request:**
```json
{
  "booking_id": "BK-2024-001234",
  "payment_method": "promptpay",
  "amount": 1836
}
```

**Response (PromptPay):**
```json
{
  "payment_id": "PAY-2024-001234",
  "status": "pending",
  "promptpay_qr": "data:image/png;base64,...",
  "promptpay_ref": "REF001234",
  "expires_at": "2024-12-19T12:30:00+07:00"
}
```

---

### Fulfillment

#### `GET /ucp/fulfillment/track/:booking_id`
ติดตามการจัดส่ง real-time

**Response:**
```json
{
  "booking_id": "BK-2024-001234",
  "status": "in_transit",
  "driver": {
    "name": "สมชาย ใจดี",
    "phone": "081-234-5678"
  },
  "vehicle": {
    "plate": "กท-1234",
    "type": "6ล้อ"
  },
  "current_location": {
    "lat": 18.6200,
    "lng": 98.9600,
    "address": "ถ.เชียงใหม่-ลำพูน กม.10"
  },
  "eta_minutes": 15,
  "updated_at": "2024-12-20T09:45:00+07:00"
}
```

---

#### `GET /ucp/fulfillment/pod/:booking_id`
หลักฐานส่งมอบ (POD)

**Response:**
```json
{
  "booking_id": "BK-2024-001234",
  "delivered_at": "2024-12-20T10:15:00+07:00",
  "receiver_name": "สมปอง",
  "photos": [
    "https://files.bcfleet.com/pod/pod_001.jpg",
    "https://files.bcfleet.com/pod/pod_002.jpg"
  ],
  "signature_url": "https://files.bcfleet.com/pod/sig_001.png",
  "notes": "รับครบ ไม่มีความเสียหาย"
}
```

---

#### `POST /ucp/fulfillment/confirm/:booking_id`
ยืนยันรับสินค้า (ลูกค้า confirm)

**Request:** `{ "confirmed_by": "สมปอง", "rating": 5, "comment": "บริการดีมาก" }`

---

### Identity

#### `GET /ucp/identity/merchant`
ข้อมูลร้านค้า/ผู้ให้บริการ

**Response:**
```json
{
  "shop_id": "shop_001",
  "name": "บจก.ขนส่ง BC",
  "category": "transportation",
  "phone": "053-123-456",
  "line_id": "@bc_transport",
  "address": "เชียงใหม่",
  "coverage_zones": ["เชียงใหม่", "ลำพูน", "ลำปาง"],
  "rating": 4.7,
  "total_deliveries": 1250,
  "member_since": "2024-01-01"
}
```

---

## Authentication

ทุก UCP request ต้องมี header:

```
Authorization: Bearer <jwt_token>
X-Shop-ID: <shop_id>
```

สำหรับ A2A (agent-to-agent):
```
X-Agent-Key: <api_key>
```

---

## Error Format

```json
{
  "error": {
    "code": "VEHICLE_NOT_AVAILABLE",
    "message": "ไม่มีรถว่างในวันที่ระบุ",
    "details": {
      "date": "2024-12-20",
      "zone": "ลำพูน"
    }
  }
}
```

| Error Code | Description |
|-----------|-------------|
| VEHICLE_NOT_AVAILABLE | ไม่มีรถว่าง |
| QUOTE_EXPIRED | ใบเสนอราคาหมดอายุ |
| PAYMENT_FAILED | ชำระเงินล้มเหลว |
| BOOKING_NOT_FOUND | ไม่พบการจอง |
| INVALID_ZONE | zone ไม่อยู่ในพื้นที่ให้บริการ |
| WEIGHT_EXCEEDED | น้ำหนักเกินกำหนด |
