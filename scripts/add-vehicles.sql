-- เพิ่มรถอีก 85 คัน (รวม 100) กระจายทั่วไทย
INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v016','shop_001','กก-0016','ISUZU','FRR 210','6ล้อ',2023,'ขาว','ดีเซล',6000,'own','active',45000,13.8451,100.5386,'green',NOW(),NOW()),
('v017','shop_001','กก-0017','HINO','500','10ล้อ',2022,'น้ำเงิน','ดีเซล',15000,'own','active',88000,13.6900,100.7501,'green',NOW(),NOW()),
('v018','shop_001','กก-0018','TOYOTA','Revo','กระบะ',2024,'ดำ','ดีเซล',1000,'own','active',12000,13.9230,100.4230,'green',NOW(),NOW()),
('v019','shop_001','กก-0019','ISUZU','NPR','6ล้อ',2021,'เขียว','ดีเซล',5500,'own','active',132000,14.0723,100.6048,'green',NOW(),NOW()),
('v020','shop_001','กก-0020','MITSUBISHI','Canter','6ล้อ',2023,'ขาว','ดีเซล',5000,'own','maintenance',58000,14.3495,100.5771,'yellow',NOW(),NOW()),
('v021','shop_001','กก-0021','HINO','700','หัวลาก',2020,'แดง','ดีเซล',30000,'own','active',275000,14.5896,100.4548,'green',NOW(),NOW()),
('v022','shop_001','กก-0022','ISUZU','Deca','10ล้อ',2022,'ขาว','ดีเซล',16000,'own','active',105000,14.8741,100.6581,'green',NOW(),NOW()),
('v023','shop_001','กก-0023','TOYOTA','Hilux','กระบะ',2024,'เทา','ดีเซล',1200,'own','active',6500,15.2297,104.8574,'green',NOW(),NOW()),
('v024','shop_001','กก-0024','FUSO','Fighter','6ล้อ',2023,'ขาว','ดีเซล',6500,'rental','active',31000,15.8700,100.9925,'green',NOW(),NOW()),
('v025','shop_001','กก-0025','HINO','300','4ล้อ',2024,'ฟ้า','ดีเซล',3500,'own','active',9800,16.4419,102.8360,'green',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v026','shop_001','กก-0026','NISSAN','NV350','4ล้อ',2023,'ขาว','ดีเซล',1500,'own','active',19000,16.7500,100.1950,'green',NOW(),NOW()),
('v027','shop_001','กก-0027','ISUZU','GXR','หัวลาก',2019,'แดง','ดีเซล',32000,'own','active',310000,17.0000,104.0500,'green',NOW(),NOW()),
('v028','shop_001','กก-0028','MITSUBISHI','Triton','กระบะ',2024,'ส้ม','ดีเซล',1100,'own','active',4200,17.4048,104.7768,'green',NOW(),NOW()),
('v029','shop_001','กก-0029','ISUZU','FRR','6ล้อ',2022,'ขาว','ดีเซล',6000,'own','active',67000,17.9647,102.6331,'green',NOW(),NOW()),
('v030','shop_001','กก-0030','HINO','500','10ล้อ',2021,'เหลือง','ดีเซล',14000,'own','active',189000,18.3450,103.4500,'green',NOW(),NOW()),
('v031','shop_001','กก-0031','TOYOTA','Revo','กระบะ',2023,'แดง','ดีเซล',1000,'own','active',22000,18.7500,99.0200,'green',NOW(),NOW()),
('v032','shop_001','กก-0032','ISUZU','NPR','6ล้อ',2022,'ขาว','ดีเซล',5500,'own','maintenance',145000,19.1700,99.9010,'yellow',NOW(),NOW()),
('v033','shop_001','กก-0033','HINO','300','4ล้อ',2024,'เงิน','ดีเซล',3500,'own','active',8000,19.9090,99.8318,'green',NOW(),NOW()),
('v034','shop_001','กก-0034','FUSO','Fighter','6ล้อ',2021,'ขาว','ดีเซล',6500,'own','active',155000,19.3000,97.9700,'green',NOW(),NOW()),
('v035','shop_001','กก-0035','ISUZU','FVM','10ล้อ',2022,'น้ำเงิน','ดีเซล',14000,'own','active',92000,18.4700,98.9700,'green',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v036','shop_001','กก-0036','HINO','700','หัวลาก',2020,'แดง','ดีเซล',30000,'own','active',285000,13.3611,100.9847,'green',NOW(),NOW()),
('v037','shop_001','กก-0037','TOYOTA','Hilux','กระบะ',2024,'ขาว','ดีเซล',1200,'own','active',3500,12.5684,99.9582,'green',NOW(),NOW()),
('v038','shop_001','กก-0038','ISUZU','Deca','10ล้อ',2023,'ขาว','ดีเซล',16000,'own','active',45000,12.6131,102.1028,'green',NOW(),NOW()),
('v039','shop_001','กก-0039','MITSUBISHI','Canter','6ล้อ',2022,'เขียว','ดีเซล',5000,'own','active',78000,11.9500,99.9700,'green',NOW(),NOW()),
('v040','shop_001','กก-0040','HINO','500','10ล้อ',2021,'ขาว','ดีเซล',15000,'own','active',167000,10.4860,99.1800,'green',NOW(),NOW()),
('v041','shop_001','กก-0041','ISUZU','FRR','6ล้อ',2023,'ขาว','ดีเซล',6000,'own','active',38000,9.9653,98.6337,'green',NOW(),NOW()),
('v042','shop_001','กก-0042','TOYOTA','Revo','กระบะ',2024,'ดำ','ดีเซล',1000,'own','active',11000,9.1382,99.3267,'green',NOW(),NOW()),
('v043','shop_001','กก-0043','NISSAN','NV350','4ล้อ',2023,'ขาว','ดีเซล',1500,'own','maintenance',25000,8.6234,99.0947,'yellow',NOW(),NOW()),
('v044','shop_001','กก-0044','HINO','300','4ล้อ',2024,'ฟ้า','ดีเซล',3500,'own','active',7500,8.4305,99.9633,'green',NOW(),NOW()),
('v045','shop_001','กก-0045','FUSO','Fighter','6ล้อ',2022,'ขาว','ดีเซล',6500,'own','active',82000,7.8804,98.3923,'green',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v046','shop_001','กก-0046','ISUZU','GXR','หัวลาก',2019,'แดง','ดีเซล',32000,'own','active',340000,7.5560,99.6119,'green',NOW(),NOW()),
('v047','shop_001','กก-0047','HINO','700','หัวลาก',2020,'แดง','ดีเซล',30000,'own','active',260000,7.1951,100.5959,'green',NOW(),NOW()),
('v048','shop_001','กก-0048','ISUZU','FVM','10ล้อ',2021,'เหลือง','ดีเซล',14000,'own','active',195000,6.8725,100.4736,'green',NOW(),NOW()),
('v049','shop_001','กก-0049','TOYOTA','Hilux','กระบะ',2024,'เทา','ดีเซล',1200,'own','active',5200,6.5422,100.0699,'green',NOW(),NOW()),
('v050','shop_001','กก-0050','MITSUBISHI','Triton','กระบะ',2023,'ส้ม','ดีเซล',1100,'own','active',18000,6.4281,101.8226,'green',NOW(),NOW()),
('v051','shop_001','กก-0051','ISUZU','FRR','6ล้อ',2023,'ขาว','ดีเซล',6000,'own','active',42000,13.8000,100.0500,'green',NOW(),NOW()),
('v052','shop_001','กก-0052','HINO','500','10ล้อ',2022,'น้ำเงิน','ดีเซล',15000,'own','active',95000,13.5500,100.2800,'green',NOW(),NOW()),
('v053','shop_001','กก-0053','TOYOTA','Revo','กระบะ',2024,'ขาว','ดีเซล',1000,'own','active',8500,13.9500,100.9000,'green',NOW(),NOW()),
('v054','shop_001','กก-0054','FUSO','Fighter','6ล้อ',2022,'ขาว','ดีเซล',6500,'own','active',71000,14.2200,101.2100,'green',NOW(),NOW()),
('v055','shop_001','กก-0055','ISUZU','NPR','6ล้อ',2021,'เขียว','ดีเซล',5500,'own','maintenance',140000,14.4700,101.8300,'yellow',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v056','shop_001','กก-0056','HINO','300','4ล้อ',2024,'ฟ้า','ดีเซล',3500,'own','active',6800,14.8800,103.4900,'green',NOW(),NOW()),
('v057','shop_001','กก-0057','NISSAN','NV350','4ล้อ',2023,'ขาว','ดีเซล',1500,'own','active',21000,15.0000,103.0000,'green',NOW(),NOW()),
('v058','shop_001','กก-0058','ISUZU','Deca','10ล้อ',2022,'ขาว','ดีเซล',16000,'own','active',110000,15.4000,105.0000,'green',NOW(),NOW()),
('v059','shop_001','กก-0059','MITSUBISHI','Canter','6ล้อ',2023,'ขาว','ดีเซล',5000,'own','active',55000,15.7900,100.2600,'green',NOW(),NOW()),
('v060','shop_001','กก-0060','HINO','700','หัวลาก',2020,'แดง','ดีเซล',30000,'own','active',290000,16.0000,100.5000,'green',NOW(),NOW()),
('v061','shop_001','กก-0061','ISUZU','FRR','6ล้อ',2023,'ขาว','ดีเซล',6000,'own','active',35000,16.2500,103.2500,'green',NOW(),NOW()),
('v062','shop_001','กก-0062','TOYOTA','Hilux','กระบะ',2024,'ดำ','ดีเซล',1000,'own','active',9200,16.7500,102.7700,'green',NOW(),NOW()),
('v063','shop_001','กก-0063','HINO','500','10ล้อ',2021,'เหลือง','ดีเซล',14000,'own','active',178000,17.0000,101.7500,'green',NOW(),NOW()),
('v064','shop_001','กก-0064','FUSO','Fighter','6ล้อ',2022,'ขาว','ดีเซล',6500,'own','active',65000,17.4000,102.7900,'green',NOW(),NOW()),
('v065','shop_001','กก-0065','ISUZU','GXR','หัวลาก',2019,'แดง','ดีเซล',32000,'own','active',355000,17.8700,102.7500,'green',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v066','shop_001','กก-0066','TOYOTA','Revo','กระบะ',2023,'แดง','ดีเซล',1000,'own','active',24000,18.0000,100.0000,'green',NOW(),NOW()),
('v067','shop_001','กก-0067','MITSUBISHI','Triton','กระบะ',2024,'ส้ม','ดีเซล',1100,'own','active',3800,18.2888,99.4987,'green',NOW(),NOW()),
('v068','shop_001','กก-0068','HINO','300','4ล้อ',2024,'เงิน','ดีเซล',3500,'own','active',5500,18.5741,98.9847,'green',NOW(),NOW()),
('v069','shop_001','กก-0069','ISUZU','FVM','10ล้อ',2022,'น้ำเงิน','ดีเซล',14000,'own','active',87000,19.1600,99.8500,'green',NOW(),NOW()),
('v070','shop_001','กก-0070','NISSAN','NV350','4ล้อ',2023,'ขาว','ดีเซล',1500,'own','active',16000,19.5400,100.0900,'green',NOW(),NOW()),
('v071','shop_001','กก-0071','ISUZU','FRR','6ล้อ',2022,'ขาว','ดีเซล',6000,'own','active',72000,13.3500,99.1600,'green',NOW(),NOW()),
('v072','shop_001','กก-0072','HINO','500','10ล้อ',2022,'ขาว','ดีเซล',15000,'own','active',102000,12.2500,99.8200,'green',NOW(),NOW()),
('v073','shop_001','กก-0073','TOYOTA','Revo','กระบะ',2024,'เทา','ดีเซล',1000,'own','active',7800,11.4000,99.9500,'green',NOW(),NOW()),
('v074','shop_001','กก-0074','FUSO','Fighter','6ล้อ',2023,'ขาว','ดีเซล',6500,'own','active',28000,10.8800,99.0300,'green',NOW(),NOW()),
('v075','shop_001','กก-0075','ISUZU','NPR','6ล้อ',2021,'เขียว','ดีเซล',5500,'own','active',148000,10.0000,98.8000,'green',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fleet_vehicles (id, shop_id, plate, brand, model, type, year, color, fuel_type, max_weight_kg, ownership, status, mileage_km, current_lat, current_lng, health_status, created_at, updated_at) VALUES
('v076','shop_001','กก-0076','HINO','700','หัวลาก',2020,'แดง','ดีเซล',30000,'own','maintenance',305000,9.5000,100.0600,'yellow',NOW(),NOW()),
('v077','shop_001','กก-0077','MITSUBISHI','Canter','6ล้อ',2022,'ขาว','ดีเซล',5000,'own','active',62000,8.9700,98.8200,'green',NOW(),NOW()),
('v078','shop_001','กก-0078','TOYOTA','Hilux','กระบะ',2024,'ขาว','ดีเซล',1200,'own','active',4500,8.4500,98.5200,'green',NOW(),NOW()),
('v079','shop_001','กก-0079','ISUZU','Deca','10ล้อ',2023,'ขาว','ดีเซล',16000,'own','active',39000,7.6300,100.0800,'green',NOW(),NOW()),
('v080','shop_001','กก-0080','HINO','300','4ล้อ',2024,'ฟ้า','ดีเซล',3500,'own','active',8200,7.0100,100.4800,'green',NOW(),NOW()),
('v081','shop_001','กก-0081','ISUZU','FRR','6ล้อ',2023,'ขาว','ดีเซล',6000,'own','active',47000,13.8700,100.6500,'green',NOW(),NOW()),
('v082','shop_001','กก-0082','NISSAN','NV350','4ล้อ',2023,'ขาว','ดีเซล',1500,'own','active',20000,13.6700,100.3400,'green',NOW(),NOW()),
('v083','shop_001','กก-0083','FUSO','Fighter','6ล้อ',2022,'ขาว','ดีเซล',6500,'own','active',76000,14.0100,100.7200,'green',NOW(),NOW()),
('v084','shop_001','กก-0084','HINO','500','10ล้อ',2021,'ขาว','ดีเซล',15000,'own','active',185000,14.5300,100.9100,'green',NOW(),NOW()),
('v085','shop_001','กก-0085','ISUZU','GXR','หัวลาก',2019,'แดง','ดีเซล',32000,'own','active',325000,15.1200,104.2300,'green',NOW(),NOW()),
('v086','shop_001','กก-0086','TOYOTA','Revo','กระบะ',2024,'ดำ','ดีเซล',1000,'own','active',6200,15.6800,100.1100,'green',NOW(),NOW()),
('v087','shop_001','กก-0087','MITSUBISHI','Triton','กระบะ',2023,'ส้ม','ดีเซล',1100,'own','active',15000,16.1800,103.6500,'green',NOW(),NOW()),
('v088','shop_001','กก-0088','HINO','300','4ล้อ',2024,'ฟ้า','ดีเซล',3500,'own','active',4800,16.8200,100.2600,'green',NOW(),NOW()),
('v089','shop_001','กก-0089','ISUZU','FVM','10ล้อ',2022,'เหลือง','ดีเซล',14000,'own','maintenance',175000,17.2500,104.1300,'yellow',NOW(),NOW()),
('v090','shop_001','กก-0090','FUSO','Fighter','6ล้อ',2021,'ขาว','ดีเซล',6500,'own','active',125000,17.6200,100.1000,'green',NOW(),NOW()),
('v091','shop_001','กก-0091','HINO','700','หัวลาก',2020,'แดง','ดีเซล',30000,'own','active',270000,18.1100,100.8200,'green',NOW(),NOW()),
('v092','shop_001','กก-0092','ISUZU','FRR','6ล้อ',2023,'ขาว','ดีเซล',6000,'own','active',33000,18.5200,99.2200,'green',NOW(),NOW()),
('v093','shop_001','กก-0093','TOYOTA','Hilux','กระบะ',2024,'เทา','ดีเซล',1200,'own','active',7100,19.0300,100.0800,'green',NOW(),NOW()),
('v094','shop_001','กก-0094','HINO','500','10ล้อ',2022,'น้ำเงิน','ดีเซล',15000,'own','active',99000,19.7100,100.1200,'green',NOW(),NOW()),
('v095','shop_001','กก-0095','NISSAN','NV350','4ล้อ',2023,'ขาว','ดีเซล',1500,'own','active',17500,12.7400,101.0200,'green',NOW(),NOW()),
('v096','shop_001','กก-0096','ISUZU','NPR','6ล้อ',2021,'เขียว','ดีเซล',5500,'own','active',138000,13.1200,100.9200,'green',NOW(),NOW()),
('v097','shop_001','กก-0097','MITSUBISHI','Canter','6ล้อ',2022,'ขาว','ดีเซล',5000,'own','active',59000,11.8100,99.8000,'green',NOW(),NOW()),
('v098','shop_001','กก-0098','HINO','300','4ล้อ',2024,'เงิน','ดีเซล',3500,'own','active',5900,10.5100,99.1900,'green',NOW(),NOW()),
('v099','shop_001','กก-0099','FUSO','Fighter','6ล้อ',2023,'ขาว','ดีเซล',6500,'own','active',26000,9.7600,98.7800,'green',NOW(),NOW()),
('v100','shop_001','กก-0100','ISUZU','Deca','10ล้อ',2022,'ขาว','ดีเซล',16000,'own','active',83000,8.0500,98.9100,'green',NOW(),NOW())
ON CONFLICT (id) DO NOTHING;

SELECT count(*) as total FROM fleet_vehicles;
