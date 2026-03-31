#!/usr/bin/env python3
"""Seed trips only - vehicles and drivers already exist"""
import json, urllib.request, sys

API = "http://172.23.0.5:8080/api/v1/fleet"

def get_list(endpoint):
    req = urllib.request.Request(API + endpoint)
    with urllib.request.urlopen(req, timeout=10) as r:
        d = json.loads(r.read())
        return d.get("data", [])

def post(endpoint, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(API + endpoint, data=body,
          headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            resp = json.loads(r.read())
            return resp.get("data", {}).get("id") or resp.get("id")
    except Exception as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        return None

def put(endpoint, data):
    body = json.dumps(data).encode()
    req = urllib.request.Request(API + endpoint, data=body,
          headers={"Content-Type": "application/json"}, method="PUT")
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return True
    except:
        return False

vehicles = [v["id"] for v in get_list("/vehicles?limit=100")]
drivers  = [d["id"] for d in get_list("/drivers?limit=100")]
print(f"Got {len(vehicles)} vehicles, {len(drivers)} drivers")

trips_data = [
    {"on": {"name": "คลังสินค้า ABC", "address": "ถ.พระราม 2 กรุงเทพ", "lat": 13.6815, "lng": 100.4744}, "dn": "โรงงาน XYZ สมุทรปราการ", "dlat": 13.5991, "dlng": 100.6039, "cargo": "ปูนซีเมนต์ 200 ถุง", "wt": 10000, "rev": 3500, "st": "started"},
    {"on": {"name": "โกดังสินค้า ไทยบริการ", "address": "ถ.บางนา กรุงเทพ", "lat": 13.6764, "lng": 100.6000}, "dn": "ท่าเรือแหลมฉบัง ชลบุรี", "dlat": 13.0849, "dlng": 100.8792, "cargo": "เครื่องจักร 3 ชุด", "wt": 15000, "rev": 6500, "st": "started"},
    {"on": {"name": "โรงงานน้ำตาลไทย", "address": "สมุทรปราการ", "lat": 13.5950, "lng": 100.5430}, "dn": "นครราชสีมา", "dlat": 14.9799, "dlng": 102.0978, "cargo": "น้ำตาลทราย 500 กระสอบ", "wt": 25000, "rev": 12000, "st": "delivering"},
    {"on": {"name": "ท่าเรือกรุงเทพ", "address": "ถ.เจริญกรุง", "lat": 13.7030, "lng": 100.5117}, "dn": "ชลบุรี เมือง", "dlat": 13.3611, "dlng": 100.9847, "cargo": "ตู้คอนเทนเนอร์", "wt": 20000, "rev": 9000, "st": "started"},
    {"on": {"name": "ศูนย์กระจายสินค้า DC1", "address": "บางนา-ตราด กม.19", "lat": 13.6200, "lng": 100.7800}, "dn": "พัทยา ชลบุรี", "dlat": 12.9236, "dlng": 100.8825, "cargo": "เฟอร์นิเจอร์", "wt": 2000, "rev": 4500, "st": "delivering"},
    {"on": {"name": "คลังสินค้า บริษัท A", "address": "ถ.พหลโยธิน กรุงเทพ", "lat": 13.8400, "lng": 100.5600}, "dn": "สระบุรี", "dlat": 14.5289, "dlng": 100.9105, "cargo": "วัสดุก่อสร้าง", "wt": 18000, "rev": 7000, "st": "started"},
    {"on": {"name": "ตลาดวโรรส เชียงใหม่", "address": "ถ.วิชยานนท์ เชียงใหม่", "lat": 18.7883, "lng": 98.9853}, "dn": "ลำพูน เมือง", "dlat": 18.5741, "dlng": 99.0093, "cargo": "ผลิตภัณฑ์หัตถกรรม", "wt": 1500, "rev": 2500, "st": "completed"},
    {"on": {"name": "โรงงานเซรามิก เชียงใหม่", "address": "ถ.เชียงใหม่-ลำปาง", "lat": 18.7600, "lng": 98.9900}, "dn": "กรุงเทพ คลองเตย", "dlat": 13.7220, "dlng": 100.5730, "cargo": "เซรามิก 1000 ชิ้น", "wt": 5000, "rev": 15000, "st": "completed"},
    {"on": {"name": "ตลาดสินค้าเกษตร เชียงใหม่", "address": "เชียงใหม่-เชียงราย", "lat": 18.8200, "lng": 99.0000}, "dn": "เชียงราย เมือง", "dlat": 19.9105, "dlng": 99.8406, "cargo": "ผลไม้ 100 ตะกร้า", "wt": 3000, "rev": 4000, "st": "started"},
    {"on": {"name": "ท่าเรือสุราษฎร์ธานี", "address": "สุราษฎร์ธานี", "lat": 9.1382, "lng": 99.3214}, "dn": "กรุงเทพ ท่าเรือ", "dlat": 13.7030, "dlng": 100.5117, "cargo": "ยางแผ่น 20 ตัน", "wt": 20000, "rev": 25000, "st": "completed"},
    {"on": {"name": "โรงงานอาหารทะเล สงขลา", "address": "หาดใหญ่", "lat": 7.0066, "lng": 100.4772}, "dn": "กรุงเทพ ตลาดไท", "dlat": 14.0700, "dlng": 100.6200, "cargo": "อาหารทะเลแช่แข็ง", "wt": 8000, "rev": 18000, "st": "completed"},
    {"on": {"name": "ตลาดกลาง ขอนแก่น", "address": "ถ.มิตรภาพ ขอนแก่น", "lat": 16.4419, "lng": 102.8360}, "dn": "กรุงเทพ ตลาดไท", "dlat": 14.0700, "dlng": 100.6200, "cargo": "มันสำปะหลัง 30 ตัน", "wt": 30000, "rev": 20000, "st": "completed"},
    {"on": {"name": "โรงงานแป้งมัน นครราชสีมา", "address": "อ.สูงเนิน", "lat": 14.9200, "lng": 101.7800}, "dn": "แหลมฉบัง ชลบุรี", "dlat": 13.0849, "dlng": 100.8792, "cargo": "แป้งมันสำปะหลัง", "wt": 25000, "rev": 18000, "st": "started"},
    {"on": {"name": "นิคมอุตสาหกรรม เวลโกรว์", "address": "ฉะเชิงเทรา", "lat": 13.6842, "lng": 101.0783}, "dn": "แหลมฉบัง ชลบุรี", "dlat": 13.0849, "dlng": 100.8792, "cargo": "ชิ้นส่วนรถยนต์", "wt": 8000, "rev": 5000, "st": "accepted"},
    {"on": {"name": "โรงงาน Amata City ระยอง", "address": "ระยอง", "lat": 12.9800, "lng": 101.1000}, "dn": "ท่าเรือมาบตาพุด", "dlat": 12.6600, "dlng": 101.1400, "cargo": "ปิโตรเคมี", "wt": 18000, "rev": 7000, "st": "accepted"},
    {"on": {"name": "ห้างโลตัส บางใหญ่", "address": "นนทบุรี", "lat": 13.8600, "lng": 100.4200}, "dn": "นครปฐม", "dlat": 13.8199, "dlng": 100.0625, "cargo": "สินค้าบริโภค", "wt": 4000, "rev": 2800, "st": "pending"},
    {"on": {"name": "โกดัง CP ลำลูกกา", "address": "ปทุมธานี", "lat": 13.9500, "lng": 100.6800}, "dn": "สระบุรี อยุธยา", "dlat": 14.5289, "dlng": 100.9105, "cargo": "อาหารสัตว์ 500 กระสอบ", "wt": 12500, "rev": 5500, "st": "pending"},
    {"on": {"name": "กรุงเทพ ดอนเมือง", "address": "ถ.วิภาวดีรังสิต", "lat": 13.9126, "lng": 100.6067}, "dn": "ขอนแก่น เมือง", "dlat": 16.4419, "dlng": 102.8360, "cargo": "วัสดุก่อสร้าง ซีแพค", "wt": 15000, "rev": 12000, "st": "accepted"},
    {"on": {"name": "โรงงาน Mitsubishi Motor", "address": "ปทุมธานี", "lat": 14.0208, "lng": 100.5250}, "dn": "ท่าเรือกรุงเทพ", "dlat": 13.7030, "dlng": 100.5117, "cargo": "รถยนต์ส่งออก 8 คัน", "wt": 16000, "rev": 25000, "st": "delivering"},
    {"on": {"name": "ท่าเรือกรุงเทพ2", "address": "กรุงเทพ", "lat": 13.7030, "lng": 100.5117}, "dn": "เชียงใหม่ นิมมาน", "dlat": 18.7934, "dlng": 98.9691, "cargo": "เครื่องใช้ไฟฟ้า", "wt": 6000, "rev": 22000, "st": "started"},
    {"on": {"name": "นิคมอุตสาหกรรมแหลมฉบัง", "address": "ชลบุรี", "lat": 13.0849, "lng": 100.8792}, "dn": "หาดใหญ่ สงขลา", "dlat": 7.0066, "dlng": 100.4772, "cargo": "รถยนต์ใหม่ 6 คัน", "wt": 12000, "rev": 45000, "st": "completed"},
    {"on": {"name": "สวนผลไม้ เพชรบุรี", "address": "ชะอำ", "lat": 12.7958, "lng": 99.9654}, "dn": "ตลาดสี่มุมเมือง", "dlat": 13.9700, "dlng": 100.6800, "cargo": "มะม่วง สับปะรด", "wt": 8000, "rev": 8000, "st": "completed"},
    {"on": {"name": "โรงสีข้าว สุพรรณบุรี", "address": "สุพรรณบุรี", "lat": 14.4744, "lng": 100.1177}, "dn": "กรุงเทพ ท่าเรือ", "dlat": 13.7030, "dlng": 100.5117, "cargo": "ข้าวสาร 100 ตัน", "wt": 100000, "rev": 80000, "st": "completed"},
    {"on": {"name": "ท่าเรือสงขลา", "address": "สงขลา", "lat": 7.2000, "lng": 100.5800}, "dn": "กรุงเทพ อมตะ", "dlat": 13.6200, "dlng": 100.7800, "cargo": "ปลาทูน่าแปรรูป", "wt": 10000, "rev": 28000, "st": "completed"},
    {"on": {"name": "คลังสินค้า SCG บางซื่อ", "address": "กรุงเทพ", "lat": 13.8100, "lng": 100.5300}, "dn": "นครปฐม ก่อสร้าง", "dlat": 13.8199, "dlng": 100.0625, "cargo": "ปูนซีเมนต์ 600 ถุง", "wt": 30000, "rev": 12000, "st": "completed"},
    {"on": {"name": "นิคมอุตสาหกรรม กบินทร์บุรี", "address": "ปราจีนบุรี", "lat": 13.9800, "lng": 101.7200}, "dn": "แหลมฉบัง", "dlat": 13.0849, "dlng": 100.8792, "cargo": "เฟอร์นิเจอร์ส่งออก", "wt": 7000, "rev": 10000, "st": "pending"},
    {"on": {"name": "โรงงาน Thai Union ระยอง", "address": "ระยอง", "lat": 12.9000, "lng": 101.2000}, "dn": "กรุงเทพ ท่าเรือ", "dlat": 13.7030, "dlng": 100.5117, "cargo": "อาหารทะเลกระป๋อง", "wt": 12000, "rev": 15000, "st": "accepted"},
    {"on": {"name": "ท่าอากาศยานสุวรรณภูมิ", "address": "สมุทรปราการ", "lat": 13.6900, "lng": 100.7501}, "dn": "กรุงเทพ คลองเตย", "dlat": 13.7220, "dlng": 100.5730, "cargo": "สินค้านำเข้า พัสดุ", "wt": 1000, "rev": 4000, "st": "accepted"},
    {"on": {"name": "โรงงาน Central Kitchen", "address": "ปทุมธานี", "lat": 14.0500, "lng": 100.5700}, "dn": "เชียงใหม่ เซ็นทรัล", "dlat": 18.7883, "dlng": 98.9853, "cargo": "วัตถุดิบอาหาร", "wt": 3000, "rev": 14000, "st": "started"},
    {"on": {"name": "ฟาร์มไก่ สระบุรี", "address": "สระบุรี", "lat": 14.5289, "lng": 100.9105}, "dn": "โรงงาน CP อยุธยา", "dlat": 14.3692, "dlng": 100.5878, "cargo": "ไก่เป็น 5000 ตัว", "wt": 8000, "rev": 9000, "st": "pending"},
    {"on": {"name": "ตลาดกลางยาง ระยอง", "address": "ระยอง", "lat": 12.6800, "lng": 101.2700}, "dn": "โรงงานยาง ชลบุรี", "dlat": 13.1000, "dlng": 100.9200, "cargo": "ยางแผ่นรมควัน", "wt": 15000, "rev": 7000, "st": "pending"},
    {"on": {"name": "ท่าเรือระนอง", "address": "ระนอง", "lat": 9.9587, "lng": 98.6253}, "dn": "กรุงเทพ", "dlat": 13.7563, "dlng": 100.5018, "cargo": "ปลาสดจากเมียนมา", "wt": 5000, "rev": 12000, "st": "started"},
    {"on": {"name": "สวนทุเรียน จันทบุรี", "address": "จันทบุรี", "lat": 12.6094, "lng": 102.1040}, "dn": "ตลาดไท ปทุมธานี", "dlat": 14.0700, "dlng": 100.6200, "cargo": "ทุเรียน 200 ผล", "wt": 3000, "rev": 8000, "st": "completed"},
    {"on": {"name": "โรงงาน PCB สมุทรปราการ", "address": "สมุทรปราการ", "lat": 13.5891, "lng": 100.6500}, "dn": "นิคมโรจนะ อยุธยา", "dlat": 14.3500, "dlng": 100.6900, "cargo": "แผงวงจรอิเล็กทรอนิกส์", "wt": 500, "rev": 5000, "st": "accepted"},
    {"on": {"name": "คลังน้ำมัน ปตท.", "address": "สมุทรปราการ", "lat": 13.5800, "lng": 100.5200}, "dn": "นครปฐม ปตท.", "dlat": 13.8100, "dlng": 100.0600, "cargo": "น้ำมันดีเซล 50000 ลิตร", "wt": 40000, "rev": 35000, "st": "started"},
    {"on": {"name": "ตลาด OTOP เชียงราย", "address": "เชียงราย", "lat": 19.9105, "lng": 99.8406}, "dn": "กรุงเทพ สยาม", "dlat": 13.7466, "dlng": 100.5337, "cargo": "ผลิตภัณฑ์ชุมชน", "wt": 800, "rev": 6000, "st": "completed"},
    {"on": {"name": "บริษัท 3BB", "address": "ถ.แจ้งวัฒนะ", "lat": 13.8900, "lng": 100.5600}, "dn": "ขอนแก่น เมือง", "dlat": 16.4419, "dlng": 102.8360, "cargo": "อุปกรณ์สื่อสาร", "wt": 2000, "rev": 8000, "st": "delivering"},
    {"on": {"name": "ฟาร์มโคเนื้อ อุดรธานี", "address": "อุดรธานี", "lat": 17.4100, "lng": 102.7600}, "dn": "ตลาดนัดโค นครราชสีมา", "dlat": 15.0000, "dlng": 102.0500, "cargo": "โคเนื้อ 20 ตัว", "wt": 12000, "rev": 12000, "st": "pending"},
    {"on": {"name": "ท่าเรือเชียงแสน", "address": "เชียงราย", "lat": 20.2667, "lng": 100.0833}, "dn": "กรุงเทพ", "dlat": 13.7563, "dlng": 100.5018, "cargo": "สินค้านำเข้า MDF", "wt": 22000, "rev": 30000, "st": "started"},
    {"on": {"name": "โรงงาน Thai Beverage", "address": "กรุงเทพ", "lat": 13.7500, "lng": 100.5300}, "dn": "เชียงใหม่", "dlat": 18.7883, "dlng": 98.9853, "cargo": "เครื่องดื่ม 10000 ลัง", "wt": 15000, "rev": 18000, "st": "completed"},
    {"on": {"name": "นิคมอุตสาหกรรม บ้านหว้า", "address": "อยุธยา", "lat": 14.4200, "lng": 100.7000}, "dn": "แหลมฉบัง", "dlat": 13.0849, "dlng": 100.8792, "cargo": "ชิ้นส่วน Honda", "wt": 6000, "rev": 7000, "st": "started"},
    {"on": {"name": "โรงงานยา อยุธยา", "address": "อยุธยา", "lat": 14.3700, "lng": 100.5900}, "dn": "กรุงเทพ รพ.", "dlat": 13.7600, "dlng": 100.5100, "cargo": "เวชภัณฑ์ ยา", "wt": 500, "rev": 7000, "st": "accepted"},
    {"on": {"name": "โรงงาน Coca-Cola", "address": "ปทุมธานี", "lat": 14.0300, "lng": 100.5800}, "dn": "เชียงใหม่", "dlat": 18.7883, "dlng": 98.9853, "cargo": "เครื่องดื่ม Coca-Cola", "wt": 8000, "rev": 15000, "st": "delivering"},
    {"on": {"name": "สวนยาง นราธิวาส", "address": "นราธิวาส", "lat": 6.4318, "lng": 101.8232}, "dn": "หาดใหญ่ โรงงาน", "dlat": 7.0066, "dlng": 100.4772, "cargo": "ยางดิบ 20 ตัน", "wt": 20000, "rev": 10000, "st": "started"},
    {"on": {"name": "ท่าอากาศยานภูเก็ต", "address": "ภูเก็ต", "lat": 8.1132, "lng": 98.3160}, "dn": "สุราษฎร์ธานี", "dlat": 9.1382, "dlng": 99.3214, "cargo": "สินค้าท่องเที่ยว", "wt": 2000, "rev": 5000, "st": "pending"},
    {"on": {"name": "โรงงานยาสีฟัน ลาดกระบัง", "address": "ลาดกระบัง", "lat": 13.7215, "lng": 100.7834}, "dn": "ต่างจังหวัด 10 จว.", "dlat": 14.5000, "dlng": 100.5000, "cargo": "สินค้า FMCG", "wt": 4000, "rev": 12000, "st": "completed"},
    {"on": {"name": "นิคม Map Ta Phut ระยอง", "address": "ระยอง", "lat": 12.6800, "lng": 101.1500}, "dn": "กรุงเทพ", "dlat": 13.7563, "dlng": 100.5018, "cargo": "ก๊าซ LPG", "wt": 20000, "rev": 22000, "st": "started"},
    {"on": {"name": "สหกรณ์การเกษตร ลำปาง", "address": "ลำปาง", "lat": 18.2889, "lng": 99.4932}, "dn": "เชียงใหม่", "dlat": 18.7883, "dlng": 98.9853, "cargo": "ข้าวสารท้องถิ่น", "wt": 5000, "rev": 4000, "st": "accepted"},
    {"on": {"name": "ท่าเรือแหลมฉบัง2", "address": "ชลบุรี", "lat": 13.0849, "lng": 100.8792}, "dn": "นิคมอุตสาหกรรม ปทุมธานี", "dlat": 14.0208, "dlng": 100.5250, "cargo": "ตู้คอนเทนเนอร์ นำเข้า", "wt": 20000, "rev": 15000, "st": "pending"},
]

print(f"Creating {len(trips_data)} trips...")
ok = 0
for i, t in enumerate(trips_data):
    payload = {
        "vehicle_id": vehicles[i % len(vehicles)],
        "driver_id": drivers[i % len(drivers)],
        "origin": t["on"],
        "destinations": [{"seq": 1, "name": t["dn"], "address": t["dn"], "lat": t["dlat"], "lng": t["dlng"]}],
        "cargo": {"description": t["cargo"], "weight_kg": t["wt"]},
        "planned_start": "2026-03-31T06:00:00Z",
        "planned_end": "2026-03-31T18:00:00Z",
        "revenue": t["rev"],
    }
    tid = post("/trips", payload)
    if tid:
        ok += 1
        if t["st"] != "pending":
            put(f"/trips/{tid}/status", {"status": t["st"]})
        print(f"  [{i+1:2d}] {t['on']['name'][:28]} -> {t['dn'][:22]} [{t['st']}]")
    else:
        print(f"  [FAIL] trip {i+1}")

print(f"\nDone! Trips created: {ok}/{len(trips_data)}")
