// BC Fleet Demo Seed Data
db.fleet_vehicles.drop();
db.fleet_drivers.drop();
db.fleet_trips.drop();
db.fleet_maintenance_work_orders.drop();
db.fleet_partner_vehicles.drop();
db.fleet_expenses.drop();
db.fleet_alerts.drop();
db.fleet_parts_inventory.drop();

// ===== 15 Vehicles =====
db.fleet_vehicles.insertMany([
  {shop_id:"shop_001",plate:"กท-1234",brand:"ISUZU",model:"FRR 210",type:"6ล้อ",year:2023,color:"ขาว",fuel_type:"ดีเซล",max_weight_kg:6000,ownership:"own",status:"active",mileage_km:85000,current_location:{lat:18.7883,lng:98.9853},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"2กบ-5678",brand:"HINO",model:"500 Series",type:"10ล้อ",year:2022,color:"น้ำเงิน",fuel_type:"ดีเซล",max_weight_kg:15000,ownership:"own",status:"active",mileage_km:120000,current_location:{lat:18.795,lng:98.972},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"ขก-9012",brand:"TOYOTA",model:"Revo Rocco",type:"กระบะ",year:2024,color:"ดำ",fuel_type:"ดีเซล",max_weight_kg:1000,ownership:"own",status:"active",mileage_km:15000,current_location:{lat:18.81,lng:98.95},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"3กจ-3456",brand:"ISUZU",model:"NPR 150",type:"6ล้อ",year:2021,color:"เขียว",fuel_type:"ดีเซล",max_weight_kg:5500,ownership:"own",status:"active",mileage_km:145000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"ฉฉ-7890",brand:"MITSUBISHI",model:"Canter FE85",type:"6ล้อ",year:2023,color:"ขาว",fuel_type:"ดีเซล",max_weight_kg:5000,ownership:"own",status:"maintenance",mileage_km:62000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"4กม-1122",brand:"HINO",model:"700 Series",type:"หัวลาก",year:2020,color:"แดง",fuel_type:"ดีเซล",max_weight_kg:30000,ownership:"own",status:"active",mileage_km:250000,current_location:{lat:18.83,lng:99.01},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"กข-3344",brand:"ISUZU",model:"Deca 360",type:"10ล้อ",year:2022,color:"ขาว",fuel_type:"ดีเซล",max_weight_kg:16000,ownership:"own",status:"active",mileage_km:98000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"ษษ-5566",brand:"TOYOTA",model:"Hilux Revo",type:"กระบะ",year:2024,color:"เทา",fuel_type:"ดีเซล",max_weight_kg:1200,ownership:"own",status:"active",mileage_km:8000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"6กว-7788",brand:"FUSO",model:"Fighter FK65",type:"6ล้อ",year:2023,color:"ขาว",fuel_type:"ดีเซล",max_weight_kg:6500,ownership:"rental",status:"active",mileage_km:35000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"พพ-9900",brand:"HINO",model:"300 Series",type:"4ล้อ",year:2024,color:"ฟ้า",fuel_type:"ดีเซล",max_weight_kg:3500,ownership:"own",status:"active",mileage_km:12000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"ดด-8899",brand:"NISSAN",model:"NV350",type:"4ล้อ",year:2023,color:"ขาว",fuel_type:"ดีเซล",max_weight_kg:1500,ownership:"own",status:"active",mileage_km:22000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"ตต-1010",brand:"ISUZU",model:"GXR 360",type:"หัวลาก",year:2019,color:"แดง",fuel_type:"ดีเซล",max_weight_kg:32000,ownership:"own",status:"active",mileage_km:320000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"บบ-2020",brand:"MITSUBISHI",model:"Triton",type:"กระบะ",year:2024,color:"ส้ม",fuel_type:"ดีเซล",max_weight_kg:1100,ownership:"own",status:"active",mileage_km:5000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"ชช-6677",brand:"ISUZU",model:"FVM 240",type:"10ล้อ",year:2021,color:"เหลือง",fuel_type:"ดีเซล",max_weight_kg:14000,ownership:"own",status:"inactive",mileage_km:200000,created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",plate:"2กร-4455",brand:"HINO",model:"500",type:"10ล้อ",year:2022,color:"ขาว",fuel_type:"ดีเซล",max_weight_kg:15000,ownership:"partner",status:"active",mileage_km:110000,created_at:new Date(),updated_at:new Date()}
]);

// ===== 10 Drivers =====
db.fleet_drivers.insertMany([
  {shop_id:"shop_001",employee_id:"EMP-001",name:"สมชาย ใจดี",nickname:"ชาย",phone:"081-234-5678",status:"active",employment:{type:"permanent",salary:15000,daily_allowance:300,trip_bonus:200},performance:{total_trips:450,on_time_rate:0.95,fuel_efficiency:5.2,customer_rating:4.8,score:92},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-002",name:"สมหญิง แก้วใส",nickname:"หญิง",phone:"082-345-6789",status:"active",employment:{type:"permanent",salary:14000,daily_allowance:300,trip_bonus:200},performance:{total_trips:280,on_time_rate:0.98,fuel_efficiency:6.1,customer_rating:4.9,score:96},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-003",name:"วิชัย รักงาน",nickname:"ชัย",phone:"083-456-7890",status:"active",employment:{type:"permanent",salary:16000,daily_allowance:350,trip_bonus:250},performance:{total_trips:680,on_time_rate:0.92,fuel_efficiency:4.8,customer_rating:4.6,score:85},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-004",name:"ประพันธ์ ซื่อตรง",nickname:"พันธ์",phone:"084-567-8901",status:"active",employment:{type:"permanent",salary:14000},performance:{total_trips:180,on_time_rate:0.97,score:94},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-005",name:"สุภาพ ขยันทำ",nickname:"ภาพ",phone:"085-678-9012",status:"active",employment:{type:"permanent",salary:14500},performance:{total_trips:320,on_time_rate:0.93,score:88},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-006",name:"อนุชา เก่งกาจ",nickname:"ชา",phone:"086-789-0123",status:"active",employment:{type:"permanent",salary:17000,daily_allowance:400},performance:{total_trips:920,on_time_rate:0.91,score:80},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-007",name:"พิมพ์ใจ สะอาด",nickname:"พิมพ์",phone:"087-890-1234",status:"active",employment:{type:"contract",salary:13000},performance:{total_trips:95,on_time_rate:0.99,customer_rating:5.0,score:98},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-008",name:"ธนกร มั่นคง",nickname:"กร",phone:"088-901-2345",status:"on_leave",employment:{type:"permanent",salary:15000},performance:{total_trips:380,score:89},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-009",name:"กมลวรรณ ใจเย็น",nickname:"วรรณ",phone:"089-012-3456",status:"active",employment:{type:"daily",daily_allowance:500},performance:{total_trips:45,on_time_rate:1.0,score:97},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",employee_id:"EMP-010",name:"เกียรติศักดิ์ แข็งแรง",nickname:"เกียรติ",phone:"090-123-4567",status:"active",employment:{type:"permanent",salary:16500},performance:{total_trips:750,on_time_rate:0.90,score:78},created_at:new Date(),updated_at:new Date()}
]);

// ===== 12 Trips =====
db.fleet_trips.insertMany([
  {shop_id:"shop_001",trip_no:"TRIP-2026-000001",status:"completed",vehicle_id:"กท-1234",driver_id:"EMP-001",origin:{name:"คลังสินค้า ABC เชียงใหม่"},destinations:[{seq:1,name:"ร้าน XYZ วัสดุ ลำพูน",status:"delivered"}],cargo:{description:"ปูนซีเมนต์ 200 ถุง",weight_kg:10000},costs:{fuel:800,toll:60,total:1160,revenue:2500,profit:1340},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000002",status:"completed",vehicle_id:"2กบ-5678",driver_id:"EMP-003",origin:{name:"โรงงาน DEF นิคมลำพูน"},destinations:[{seq:1,name:"ห้าง BigC ลำปาง",status:"delivered"}],cargo:{description:"เหล็กเส้น 10 ตัน",weight_kg:10000},costs:{fuel:1500,toll:120,total:2200,revenue:5500,profit:3300},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000003",status:"completed",vehicle_id:"ขก-9012",driver_id:"EMP-002",origin:{name:"ศูนย์กระจายสินค้าเซ็นทรัล"},destinations:[{seq:1,name:"โรงแรมเชียงราย",status:"delivered"}],cargo:{description:"อุปกรณ์อิเล็กทรอนิกส์ 50 กล่อง",weight_kg:500},costs:{fuel:600,toll:80,total:980,revenue:1800,profit:820},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000004",status:"completed",vehicle_id:"กข-3344",driver_id:"EMP-010",origin:{name:"โกดังวัสดุก่อสร้าง JKL"},destinations:[{seq:1,name:"ร้านค้าส่ง พะเยา",status:"delivered"}],cargo:{description:"วัสดุก่อสร้าง",weight_kg:12000},costs:{fuel:1800,toll:150,total:2600,revenue:6000,profit:3400},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000005",status:"completed",vehicle_id:"ษษ-5566",driver_id:"EMP-007",origin:{name:"ร้านเฟอร์นิเจอร์สันทราย"},destinations:[{seq:1,name:"โรงพยาบาลนครพิงค์",status:"delivered"}],cargo:{description:"เวชภัณฑ์ 20 กล่อง",weight_kg:300},costs:{fuel:200,total:400,revenue:1500,profit:1100},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000006",status:"in_progress",vehicle_id:"3กจ-3456",driver_id:"EMP-004",origin:{name:"ศูนย์กระจายสินค้า GHI"},destinations:[{seq:1,name:"ตลาดวโรรส",status:"pending"}],cargo:{description:"สินค้าแห้ง 300 กล่อง",weight_kg:3000},costs:{revenue:3200},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000007",status:"in_progress",vehicle_id:"4กม-1122",driver_id:"EMP-006",origin:{name:"คลังสินค้าถนนเชียงใหม่-ลำปาง"},destinations:[{seq:1,name:"กรุงเทพมหานคร",status:"pending"}],cargo:{description:"วัสดุก่อสร้าง",weight_kg:25000},costs:{revenue:15000},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000008",status:"started",vehicle_id:"พพ-9900",driver_id:"EMP-005",origin:{name:"คลัง PTT สันทราย"},destinations:[{seq:1,name:"แม็คโคร หางดง",status:"pending"}],cargo:{description:"น้ำดื่ม 1000 แพ็ค",weight_kg:8000},costs:{revenue:2000},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000009",status:"pending",origin:{name:"คลังสินค้า ABC"},destinations:[{seq:1,name:"ม.เชียงใหม่",status:"pending"}],cargo:{description:"เฟอร์นิเจอร์ 30 ชิ้น",weight_kg:2000},costs:{revenue:3500},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000010",status:"pending",origin:{name:"เซ็นทรัลเฟสติวัล เชียงใหม่"},destinations:[{seq:1,name:"ร้านอาหาร แม่ฮ่องสอน",status:"pending"}],cargo:{description:"อาหารสด 500 กล่อง",weight_kg:5000},costs:{revenue:4500},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000011",status:"draft",origin:{name:"โรงงานเชียงใหม่"},destinations:[{seq:1,name:"ลำพูน",status:"pending"}],cargo:{description:"อะไหล่รถยนต์",weight_kg:1500},costs:{revenue:1200},created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",trip_no:"TRIP-2026-000012",status:"cancelled",vehicle_id:"ดด-8899",origin:{name:"สนามบินเชียงใหม่"},destinations:[{seq:1,name:"เชียงราย",status:"pending"}],cargo:{description:"พัสดุ 100 ชิ้น",weight_kg:800},created_at:new Date(),updated_at:new Date()}
]);

// ===== 5 Alerts =====
db.fleet_alerts.insertMany([
  {shop_id:"shop_001",type:"insurance_expiry",entity:"vehicle",entity_id:"กท-1234",title:"ประกันภัยใกล้หมดอายุ",message:"รถ กท-1234 ประกันหมดอายุ 01/06/2025 (เหลือ 62 วัน)",severity:"warning",days_remaining:62,status:"active",created_at:new Date()},
  {shop_id:"shop_001",type:"maintenance_due",entity:"vehicle",entity_id:"กท-1234",title:"ครบรอบเปลี่ยนน้ำมันเครื่อง",message:"รถ กท-1234 ครบรอบเปลี่ยนน้ำมันเครื่องที่ 90,000 กม.",severity:"info",status:"active",created_at:new Date()},
  {shop_id:"shop_001",type:"license_expiry",entity:"driver",entity_id:"EMP-008",title:"ใบขับขี่หมดอายุ",message:"คนขับ ธนกร มั่นคง ใบขับขี่หมดอายุแล้ว",severity:"critical",days_remaining:-1,status:"active",created_at:new Date()},
  {shop_id:"shop_001",type:"tax_due",entity:"vehicle",entity_id:"2กบ-5678",title:"ภาษีรถใกล้กำหนด",message:"รถ 2กบ-5678 ภาษีครบกำหนด 15/05/2025",severity:"warning",days_remaining:45,status:"active",created_at:new Date()},
  {shop_id:"shop_001",type:"speeding",entity:"vehicle",entity_id:"4กม-1122",title:"ขับเร็วเกินกำหนด",message:"รถ 4กม-1122 ขับเร็ว 105 กม./ชม. บนทางหลวง 11",severity:"critical",status:"acknowledged",created_at:new Date()}
]);

// ===== 7 Parts =====
db.fleet_parts_inventory.insertMany([
  {shop_id:"shop_001",part_no:"PART-001",name:"น้ำมันเครื่อง SHELL 15W-40",category:"น้ำมันหล่อลื่น",unit:"ลิตร",qty_in_stock:40,min_qty:16,unit_cost:280,supplier:"Shell",created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",part_no:"PART-002",name:"กรองน้ำมันเครื่อง ISUZU",category:"กรอง",unit:"ชิ้น",qty_in_stock:10,min_qty:5,unit_cost:350,supplier:"ISUZU",created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",part_no:"PART-003",name:"ผ้าเบรคหน้า (6ล้อ)",category:"เบรค",unit:"ชุด",qty_in_stock:4,min_qty:2,unit_cost:1200,supplier:"Bendix",created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",part_no:"PART-004",name:"กรองอากาศ ISUZU FRR",category:"กรอง",unit:"ชิ้น",qty_in_stock:8,min_qty:4,unit_cost:450,supplier:"ISUZU",created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",part_no:"PART-005",name:"ยางรถบรรทุก 11R22.5",category:"ยาง",unit:"เส้น",qty_in_stock:6,min_qty:4,unit_cost:8500,supplier:"Bridgestone",created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",part_no:"PART-006",name:"แบตเตอรี่ 3K 120Ah",category:"ไฟฟ้า",unit:"ลูก",qty_in_stock:3,min_qty:2,unit_cost:4500,supplier:"3K Battery",created_at:new Date(),updated_at:new Date()},
  {shop_id:"shop_001",part_no:"PART-007",name:"กรองดีเซล ISUZU",category:"กรอง",unit:"ชิ้น",qty_in_stock:1,min_qty:4,unit_cost:380,supplier:"ISUZU",created_at:new Date(),updated_at:new Date()}
]);

print("=== Seed Complete ===");
print("Vehicles: " + db.fleet_vehicles.countDocuments());
print("Drivers: " + db.fleet_drivers.countDocuments());
print("Trips: " + db.fleet_trips.countDocuments());
print("Alerts: " + db.fleet_alerts.countDocuments());
print("Parts: " + db.fleet_parts_inventory.countDocuments());
