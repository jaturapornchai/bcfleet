#!/usr/bin/env python3
"""SML Fleet Demo Data Seeder - Seeds via REST API so MongoDB->Kafka->PostgreSQL sync works"""
import json, urllib.request, urllib.error, sys, time, random

API_BASE = "http://172.23.0.5:8080/api/v1/fleet"

def post(endpoint, data):
    url = API_BASE + endpoint
    body = json.dumps(data).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            resp = json.loads(r.read())
            return resp.get("data", {}).get("id") or resp.get("data", {}).get("_id") or resp.get("id")
    except Exception as e:
        print(f"  ERROR {endpoint}: {e}", file=sys.stderr)
        return None

def put(endpoint, data):
    url = API_BASE + endpoint
    body = json.dumps(data).encode()
    req = urllib.request.Request(url, data=body, headers={"Content-Type": "application/json"}, method="PUT")
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return True
    except Exception as e:
        print(f"  ERROR PUT {endpoint}: {e}", file=sys.stderr)
        return False

print("=" * 50)
print("  SML Fleet Demo Data Seeder (Python)")
print(f"  API: {API_BASE}")
print("=" * 50)

# ============================================================
# 1. CREATE 100 VEHICLES
# ============================================================
print("\n--- Creating 100 vehicles ---")

vehicles_data = [
    # 4ล้อ (20 vehicles)
    {"plate":"กท-1001","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":25000},
    {"plate":"กท-1002","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":48000},
    {"plate":"กท-1003","brand":"HINO","model":"XZU","type":"4ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3500,"ownership":"own","mileage_km":12000},
    {"plate":"กท-1004","brand":"MITSUBISHI FUSO","model":"FE71","type":"4ล้อ","year":2021,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":67000},
    {"plate":"กท-1005","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":31000},
    {"plate":"2กร-1006","brand":"HINO","model":"XZU 720","type":"4ล้อ","year":2020,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":3500,"ownership":"own","mileage_km":95000},
    {"plate":"2กร-1007","brand":"ISUZU","model":"NMR 130","type":"4ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":8000},
    {"plate":"ชม-1008","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":55000},
    {"plate":"ชม-1009","brand":"MITSUBISHI FUSO","model":"FE73","type":"4ล้อ","year":2019,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3500,"ownership":"partner","mileage_km":120000},
    {"plate":"ชร-1010","brand":"HINO","model":"XZU 710","type":"4ล้อ","year":2023,"color":"เหลือง","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":22000},
    {"plate":"ชบ-1011","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2021,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":78000},
    {"plate":"นม-1012","brand":"ISUZU","model":"NMR 130","type":"4ล้อ","year":2025,"color":"ดำ","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":5000},
    {"plate":"ขก-1013","brand":"HINO","model":"XZU","type":"4ล้อ","year":2022,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3500,"ownership":"own","mileage_km":42000},
    {"plate":"สท-1014","brand":"MITSUBISHI FUSO","model":"FE71","type":"4ล้อ","year":2020,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"partner","mileage_km":110000},
    {"plate":"รย-1015","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":28000},
    {"plate":"สข-1016","brand":"ISUZU","model":"NMR 130","type":"4ล้อ","year":2024,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":9000},
    {"plate":"นบ-1017","brand":"HINO","model":"XZU 720","type":"4ล้อ","year":2021,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3500,"ownership":"own","mileage_km":72000},
    {"plate":"ปท-1018","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"partner","mileage_km":88000},
    {"plate":"สป-1019","brand":"MITSUBISHI FUSO","model":"FE71","type":"4ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":18000},
    {"plate":"อย-1020","brand":"ISUZU","model":"NLR 130","type":"4ล้อ","year":2020,"color":"เหลือง","fuel_type":"ดีเซล","max_weight_kg":3000,"ownership":"own","mileage_km":105000},
    # 6ล้อ (30 vehicles)
    {"plate":"กท-2001","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":45000},
    {"plate":"กท-2002","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":72000},
    {"plate":"กท-2003","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":15000},
    {"plate":"กท-2004","brand":"MITSUBISHI FUSO","model":"FK61","type":"6ล้อ","year":2021,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":98000},
    {"plate":"กท-2005","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2023,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":38000},
    {"plate":"2กร-2006","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2020,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"partner","mileage_km":135000},
    {"plate":"2กร-2007","brand":"UD TRUCKS","model":"MK6","type":"6ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":60000},
    {"plate":"ชม-2008","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":10000},
    {"plate":"ชม-2009","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2021,"color":"เหลือง","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":88000},
    {"plate":"ชม-2010","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":32000},
    {"plate":"ชร-2011","brand":"MITSUBISHI FUSO","model":"FK61","type":"6ล้อ","year":2022,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":55000},
    {"plate":"ชบ-2012","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2020,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"partner","mileage_km":142000},
    {"plate":"ชบ-2013","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2025,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":6000},
    {"plate":"นม-2014","brand":"UD TRUCKS","model":"MK6","type":"6ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":29000},
    {"plate":"นม-2015","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2021,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":82000},
    {"plate":"ขก-2016","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":11000},
    {"plate":"ขก-2017","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2022,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":64000},
    {"plate":"สท-2018","brand":"MITSUBISHI FUSO","model":"FK61","type":"6ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":27000},
    {"plate":"รย-2019","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":48000},
    {"plate":"รย-2020","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":14000},
    {"plate":"สข-2021","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2023,"color":"เหลือง","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":35000},
    {"plate":"สข-2022","brand":"UD TRUCKS","model":"MK6","type":"6ล้อ","year":2021,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"partner","mileage_km":96000},
    {"plate":"นบ-2023","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2022,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":58000},
    {"plate":"ปท-2024","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2025,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":4000},
    {"plate":"สป-2025","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2023,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":22000},
    {"plate":"อย-2026","brand":"MITSUBISHI FUSO","model":"FK61","type":"6ล้อ","year":2020,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":118000},
    {"plate":"กจ-2027","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2024,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":8000},
    {"plate":"กพ-2028","brand":"HINO","model":"FC9J","type":"6ล้อ","year":2022,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":6500,"ownership":"own","mileage_km":52000},
    {"plate":"กส-2029","brand":"ISUZU","model":"FRR 210","type":"6ล้อ","year":2023,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"rental","mileage_km":19000},
    {"plate":"กา-2030","brand":"UD TRUCKS","model":"MK6","type":"6ล้อ","year":2021,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":6000,"ownership":"own","mileage_km":77000},
    # 10ล้อ (25 vehicles)
    {"plate":"กท-3001","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":55000},
    {"plate":"กท-3002","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":88000},
    {"plate":"กท-3003","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":22000},
    {"plate":"กท-3004","brand":"UD TRUCKS","model":"GKE 250","type":"10ล้อ","year":2021,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":110000},
    {"plate":"กท-3005","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2023,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":42000},
    {"plate":"2กร-3006","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2020,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"partner","mileage_km":155000},
    {"plate":"ชม-3007","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":68000},
    {"plate":"ชม-3008","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":18000},
    {"plate":"ชบ-3009","brand":"UD TRUCKS","model":"GKE 250","type":"10ล้อ","year":2021,"color":"เหลือง","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":98000},
    {"plate":"ชบ-3010","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":48000},
    {"plate":"นม-3011","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2022,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":72000},
    {"plate":"ขก-3012","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":12000},
    {"plate":"ขก-3013","brand":"UD TRUCKS","model":"GKE 250","type":"10ล้อ","year":2023,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":35000},
    {"plate":"สท-3014","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2020,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"partner","mileage_km":132000},
    {"plate":"รย-3015","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2023,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":28000},
    {"plate":"สข-3016","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2022,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":65000},
    {"plate":"นบ-3017","brand":"UD TRUCKS","model":"GKE 250","type":"10ล้อ","year":2024,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":9000},
    {"plate":"ปท-3018","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2021,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":88000},
    {"plate":"สป-3019","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2023,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":32000},
    {"plate":"อย-3020","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2022,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":75000},
    {"plate":"กจ-3021","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2024,"color":"เหลือง","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":15000},
    {"plate":"กพ-3022","brand":"UD TRUCKS","model":"GKE 250","type":"10ล้อ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":44000},
    {"plate":"กส-3023","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2021,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"partner","mileage_km":102000},
    {"plate":"กา-3024","brand":"ISUZU","model":"FVM 1200","type":"10ล้อ","year":2025,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":12000,"ownership":"own","mileage_km":5000},
    {"plate":"จบ-3025","brand":"HINO","model":"GH8J","type":"10ล้อ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":13000,"ownership":"own","mileage_km":58000},
    # หัวลาก (15 vehicles)
    {"plate":"กท-4001","brand":"ISUZU","model":"GIGA FYH","type":"หัวลาก","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":85000},
    {"plate":"กท-4002","brand":"HINO","model":"700 SS","type":"หัวลาก","year":2022,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":120000},
    {"plate":"กท-4003","brand":"VOLVO","model":"FH 460","type":"หัวลาก","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":25000},
    {"plate":"2กร-4004","brand":"SCANIA","model":"R450","type":"หัวลาก","year":2021,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":145000},
    {"plate":"ชม-4005","brand":"ISUZU","model":"GIGA FYH","type":"หัวลาก","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":65000},
    {"plate":"ชบ-4006","brand":"HINO","model":"700 SS","type":"หัวลาก","year":2020,"color":"เขียว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"partner","mileage_km":198000},
    {"plate":"นม-4007","brand":"VOLVO","model":"FH 460","type":"หัวลาก","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":18000},
    {"plate":"ขก-4008","brand":"ISUZU","model":"GIGA FYH","type":"หัวลาก","year":2022,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":92000},
    {"plate":"สท-4009","brand":"SCANIA","model":"R450","type":"หัวลาก","year":2023,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":52000},
    {"plate":"รย-4010","brand":"HINO","model":"700 SS","type":"หัวลาก","year":2021,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":138000},
    {"plate":"สข-4011","brand":"ISUZU","model":"GIGA FYH","type":"หัวลาก","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":12000},
    {"plate":"นบ-4012","brand":"VOLVO","model":"FH 460","type":"หัวลาก","year":2022,"color":"เทา","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":78000},
    {"plate":"ปท-4013","brand":"SCANIA","model":"R450","type":"หัวลาก","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"partner","mileage_km":68000},
    {"plate":"สป-4014","brand":"HINO","model":"700 SS","type":"หัวลาก","year":2020,"color":"แดง","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":175000},
    {"plate":"อย-4015","brand":"ISUZU","model":"GIGA FYH","type":"หัวลาก","year":2024,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":25000,"ownership":"own","mileage_km":8000},
    # กระบะ (10 vehicles)
    {"plate":"กท-5001","brand":"TOYOTA","model":"Hilux Revo","type":"กระบะ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":35000},
    {"plate":"กท-5002","brand":"NISSAN","model":"Navara","type":"กระบะ","year":2022,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":58000},
    {"plate":"กท-5003","brand":"FORD","model":"Ranger","type":"กระบะ","year":2024,"color":"ดำ","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":12000},
    {"plate":"ชม-5004","brand":"TOYOTA","model":"Hilux Revo","type":"กระบะ","year":2023,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":28000},
    {"plate":"ชบ-5005","brand":"ISUZU","model":"D-MAX","type":"กระบะ","year":2021,"color":"เทา","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":72000},
    {"plate":"นม-5006","brand":"TOYOTA","model":"Hilux Revo","type":"กระบะ","year":2024,"color":"แดง","fuel_type":"เบนซิน","max_weight_kg":1000,"ownership":"own","mileage_km":8000},
    {"plate":"ขก-5007","brand":"NISSAN","model":"Navara","type":"กระบะ","year":2022,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":48000},
    {"plate":"สท-5008","brand":"FORD","model":"Ranger","type":"กระบะ","year":2023,"color":"น้ำเงิน","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":22000},
    {"plate":"รย-5009","brand":"ISUZU","model":"D-MAX","type":"กระบะ","year":2024,"color":"ขาว","fuel_type":"ดีเซล","max_weight_kg":1000,"ownership":"own","mileage_km":5000},
    {"plate":"สข-5010","brand":"TOYOTA","model":"Hilux Revo","type":"กระบะ","year":2021,"color":"เทา","fuel_type":"เบนซิน","max_weight_kg":1000,"ownership":"own","mileage_km":85000},
]

vehicle_ids = []
for i, v in enumerate(vehicles_data):
    vid = post("/vehicles", v)
    if vid:
        vehicle_ids.append(vid)
        print(f"  [{i+1:3d}] {v['plate']} {v['type']} -> {vid}")
    else:
        print(f"  [FAIL] {v['plate']}")

print(f"\nVehicles created: {len(vehicle_ids)}/100")

# ============================================================
# 2. SET GPS LOCATIONS FOR ALL VEHICLES
# ============================================================
print("\n--- Setting GPS locations ---")

gps_zones = [
    # Bangkok area (40 vehicles)
    *[(13.5+random.uniform(0,0.5), 100.3+random.uniform(0,0.5)) for _ in range(40)],
    # Chiang Mai (15 vehicles)
    *[(18.6+random.uniform(0,0.3), 98.9+random.uniform(0,0.2)) for _ in range(15)],
    # Chonburi/EEC (10 vehicles)
    *[(13.1+random.uniform(0,0.4), 100.8+random.uniform(0,0.4)) for _ in range(10)],
    # Korat (10 vehicles)
    *[(14.8+random.uniform(0,0.3), 102.0+random.uniform(0,0.3)) for _ in range(10)],
    # Khon Kaen (5 vehicles)
    *[(16.3+random.uniform(0,0.2), 102.7+random.uniform(0,0.3)) for _ in range(5)],
    # Surat Thani (5 vehicles)
    *[(9.0+random.uniform(0,0.2), 99.0+random.uniform(0,0.3)) for _ in range(5)],
    # Hat Yai (5 vehicles)
    *[(7.0+random.uniform(0,0.1), 100.4+random.uniform(0,0.1)) for _ in range(5)],
    # Others scattered (10 vehicles)
    (16.5, 103.0), (15.2, 104.9), (11.5, 102.1), (8.5, 99.9), (7.9, 98.3),
    (17.4, 104.8), (14.0, 101.5), (13.7, 100.6), (18.3, 99.5), (12.7, 101.1),
]

for i, vid in enumerate(vehicle_ids):
    if i < len(gps_zones):
        lat, lng = gps_zones[i]
    else:
        lat, lng = 13.7563 + random.uniform(-1,1), 100.5018 + random.uniform(-1,1)
    post("/gps/location", {"vehicle_id": vid, "lat": round(lat, 4), "lng": round(lng, 4), "speed": 0, "heading": 0})
    if (i+1) % 10 == 0:
        print(f"  GPS set for {i+1} vehicles...")

print(f"GPS locations set for {len(vehicle_ids)} vehicles")

# ============================================================
# 3. CREATE 30 DRIVERS
# ============================================================
print("\n--- Creating 30 drivers ---")

drivers_data = [
    {"employee_id":"EMP-001","name":"สมชาย ใจดี","nickname":"ชาย","phone":"081-234-5678","employment_type":"permanent","salary":15000,"daily_allowance":300,"trip_bonus":200,"zones":["เชียงใหม่","ลำพูน","ลำปาง"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-002","name":"วิชัย ขับเก่ง","nickname":"วิ","phone":"082-345-6789","employment_type":"permanent","salary":18000,"daily_allowance":350,"trip_bonus":250,"zones":["กรุงเทพ","นนทบุรี","ปทุมธานี"],"vehicle_types":["10ล้อ","หัวลาก"]},
    {"employee_id":"EMP-003","name":"สมศักดิ์ มั่นคง","nickname":"ศักดิ์","phone":"083-456-7890","employment_type":"permanent","salary":16000,"daily_allowance":300,"trip_bonus":200,"zones":["ชลบุรี","ระยอง","จันทบุรี"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-004","name":"ประสิทธิ์ ดีเยี่ยม","nickname":"ปิด","phone":"084-567-8901","employment_type":"permanent","salary":20000,"daily_allowance":400,"trip_bonus":300,"zones":["นครราชสีมา","ขอนแก่น","อุดรธานี"],"vehicle_types":["หัวลาก"]},
    {"employee_id":"EMP-005","name":"อนันต์ สุขสม","nickname":"แนน","phone":"085-678-9012","employment_type":"permanent","salary":15500,"daily_allowance":300,"trip_bonus":200,"zones":["เชียงใหม่","เชียงราย"],"vehicle_types":["4ล้อ","6ล้อ"]},
    {"employee_id":"EMP-006","name":"บุญมา ทองดี","nickname":"บุญ","phone":"086-789-0123","employment_type":"permanent","salary":17000,"daily_allowance":320,"trip_bonus":220,"zones":["กรุงเทพ","สมุทรปราการ","สมุทรสาคร"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-007","name":"สุรชัย เร็วดี","nickname":"ชัย","phone":"087-890-1234","employment_type":"permanent","salary":16500,"daily_allowance":300,"trip_bonus":200,"zones":["กรุงเทพ","นนทบุรี"],"vehicle_types":["4ล้อ","กระบะ"]},
    {"employee_id":"EMP-008","name":"ธนาคม ปลอดภัย","nickname":"คม","phone":"088-901-2345","employment_type":"permanent","salary":19000,"daily_allowance":380,"trip_bonus":280,"zones":["กรุงเทพ","ชลบุรี","นครราชสีมา"],"vehicle_types":["หัวลาก","10ล้อ"]},
    {"employee_id":"EMP-009","name":"นิคม สว่างใจ","nickname":"นิ","phone":"089-012-3456","employment_type":"permanent","salary":15000,"daily_allowance":300,"trip_bonus":200,"zones":["สุราษฎร์ธานี","นครศรีธรรมราช"],"vehicle_types":["6ล้อ"]},
    {"employee_id":"EMP-010","name":"ชูชาติ ขยันดี","nickname":"ชาติ","phone":"080-123-4567","employment_type":"permanent","salary":15500,"daily_allowance":300,"trip_bonus":200,"zones":["หาดใหญ่","สงขลา","ปัตตานี"],"vehicle_types":["6ล้อ","4ล้อ"]},
    {"employee_id":"EMP-011","name":"ไพโรจน์ กล้าหาญ","nickname":"โรจน์","phone":"081-234-5679","employment_type":"permanent","salary":17500,"daily_allowance":350,"trip_bonus":250,"zones":["กรุงเทพ","ปริมณฑล"],"vehicle_types":["10ล้อ"]},
    {"employee_id":"EMP-012","name":"สงกรานต์ ทำงานดี","nickname":"ต้น","phone":"082-345-6780","employment_type":"permanent","salary":16000,"daily_allowance":300,"trip_bonus":200,"zones":["เชียงใหม่","ลำพูน"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-013","name":"ณรงค์ศักดิ์ เก่งกว่า","nickname":"รงค์","phone":"083-456-7891","employment_type":"permanent","salary":18500,"daily_allowance":370,"trip_bonus":270,"zones":["กรุงเทพ","ชลบุรี"],"vehicle_types":["หัวลาก"]},
    {"employee_id":"EMP-014","name":"กิตติศักดิ์ สำเร็จ","nickname":"กิต","phone":"084-567-8902","employment_type":"permanent","salary":15000,"daily_allowance":300,"trip_bonus":200,"zones":["ขอนแก่น","มหาสารคาม","ร้อยเอ็ด"],"vehicle_types":["6ล้อ","4ล้อ"]},
    {"employee_id":"EMP-015","name":"พงษ์ศักดิ์ ดีใจ","nickname":"พงษ์","phone":"085-678-9013","employment_type":"permanent","salary":16000,"daily_allowance":310,"trip_bonus":210,"zones":["อุดรธานี","หนองคาย","นครพนม"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-016","name":"สุพจน์ ซื่อตรง","nickname":"พจน์","phone":"086-789-0124","employment_type":"permanent","salary":15500,"daily_allowance":300,"trip_bonus":200,"zones":["เชียงราย","พะเยา","น่าน"],"vehicle_types":["6ล้อ"]},
    {"employee_id":"EMP-017","name":"ทวีศักดิ์ ขับเรียบ","nickname":"ทวี","phone":"087-890-1235","employment_type":"permanent","salary":19500,"daily_allowance":390,"trip_bonus":290,"zones":["กรุงเทพ","ทั่วประเทศ"],"vehicle_types":["หัวลาก"]},
    {"employee_id":"EMP-018","name":"สมบูรณ์ แข็งแรง","nickname":"บูรณ์","phone":"088-901-2346","employment_type":"permanent","salary":15000,"daily_allowance":300,"trip_bonus":200,"zones":["นครปฐม","สุพรรณบุรี","กาญจนบุรี"],"vehicle_types":["4ล้อ","กระบะ"]},
    {"employee_id":"EMP-019","name":"จรัญ ตั้งใจ","nickname":"จ๋า","phone":"089-012-3457","employment_type":"permanent","salary":16500,"daily_allowance":310,"trip_bonus":210,"zones":["ระยอง","จันทบุรี","ตราด"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-020","name":"ยงยุทธ ทำได้","nickname":"ยง","phone":"080-123-4568","employment_type":"permanent","salary":17000,"daily_allowance":340,"trip_bonus":240,"zones":["กรุงเทพ","นนทบุรี","ปทุมธานี"],"vehicle_types":["6ล้อ"]},
    {"employee_id":"EMP-021","name":"ปิยะ เส้นทางดี","nickname":"ปิ","phone":"081-234-5670","employment_type":"contract","salary":14000,"daily_allowance":250,"trip_bonus":150,"zones":["เชียงใหม่","ลำปาง"],"vehicle_types":["4ล้อ","6ล้อ"]},
    {"employee_id":"EMP-022","name":"สุรศักดิ์ พอแล้ว","nickname":"สุร","phone":"082-345-6781","employment_type":"contract","salary":13500,"daily_allowance":250,"trip_bonus":150,"zones":["กรุงเทพ","สมุทรปราการ"],"vehicle_types":["4ล้อ","กระบะ"]},
    {"employee_id":"EMP-023","name":"วิทยา ใฝ่ดี","nickname":"วิท","phone":"083-456-7892","employment_type":"contract","salary":15000,"daily_allowance":280,"trip_bonus":180,"zones":["ชลบุรี","ระยอง"],"vehicle_types":["6ล้อ"]},
    {"employee_id":"EMP-024","name":"ชาตรี ขับได้","nickname":"ตรี","phone":"084-567-8903","employment_type":"contract","salary":14500,"daily_allowance":260,"trip_bonus":160,"zones":["นครราชสีมา","ชัยภูมิ"],"vehicle_types":["6ล้อ","4ล้อ"]},
    {"employee_id":"EMP-025","name":"สุนทร รักงาน","nickname":"ทร","phone":"085-678-9014","employment_type":"contract","salary":13000,"daily_allowance":250,"trip_bonus":150,"zones":["สุราษฎร์ธานี","ชุมพร"],"vehicle_types":["4ล้อ"]},
    {"employee_id":"EMP-026","name":"มานพ วันต่อวัน","nickname":"นพ","phone":"086-789-0125","employment_type":"daily","salary":12000,"daily_allowance":500,"trip_bonus":100,"zones":["กรุงเทพ"],"vehicle_types":["4ล้อ","กระบะ"]},
    {"employee_id":"EMP-027","name":"สมพร รับงาน","nickname":"พร","phone":"087-890-1236","employment_type":"daily","salary":12000,"daily_allowance":500,"trip_bonus":100,"zones":["กรุงเทพ","ปริมณฑล"],"vehicle_types":["กระบะ"]},
    {"employee_id":"EMP-028","name":"ทองสุข มีงาน","nickname":"สุข","phone":"088-901-2347","employment_type":"daily","salary":12000,"daily_allowance":450,"trip_bonus":100,"zones":["เชียงใหม่"],"vehicle_types":["4ล้อ"]},
    {"employee_id":"EMP-029","name":"ศิริชัย รถนอก","nickname":"ศิริ","phone":"089-012-3458","employment_type":"partner","salary":0,"daily_allowance":0,"trip_bonus":500,"zones":["เชียงใหม่","ลำพูน","ลำปาง","เชียงราย"],"vehicle_types":["6ล้อ","10ล้อ"]},
    {"employee_id":"EMP-030","name":"พิทักษ์ รถร่วม","nickname":"ทักษ์","phone":"080-123-4569","employment_type":"partner","salary":0,"daily_allowance":0,"trip_bonus":600,"zones":["กรุงเทพ","ชลบุรี","ระยอง"],"vehicle_types":["หัวลาก","10ล้อ"]},
]

driver_ids = []
for i, d in enumerate(drivers_data):
    did = post("/drivers", d)
    if did:
        driver_ids.append(did)
        print(f"  [{i+1:2d}] {d['name']} -> {did}")
    else:
        print(f"  [FAIL] {d['name']}")

print(f"\nDrivers created: {len(driver_ids)}/30")

# ============================================================
# 4. CREATE 50 TRIPS
# ============================================================
print("\n--- Creating 50 trips ---")

trip_routes = [
    # Bangkok area
    {"origin":{"name":"คลังสินค้า ABC","address":"ถ.พระราม 2 กรุงเทพ","lat":13.6815,"lng":100.4744},"dest_name":"โรงงาน XYZ สมุทรปราการ","dest_lat":13.5991,"dest_lng":100.6039,"cargo":"ปูนซีเมนต์ 200 ถุง","weight":10000,"revenue":3500},
    {"origin":{"name":"โกดังสินค้า บจก.ไทยบริการ","address":"ถ.บางนา กรุงเทพ","lat":13.6764,"lng":100.6000},"dest_name":"ท่าเรือแหลมฉบัง ชลบุรี","dest_lat":13.0849,"dest_lng":100.8792,"cargo":"เครื่องจักร 3 ชุด","weight":15000,"revenue":6500},
    {"origin":{"name":"นิคมอุตสาหกรรม บางชัน","address":"ถ.รามคำแหง กรุงเทพ","lat":13.7700,"lng":100.7200},"dest_name":"ลาดกระบัง กรุงเทพ","dest_lat":13.7215,"lng":100.7834,"cargo":"ชิ้นส่วนอิเล็กทรอนิกส์","weight":3000,"revenue":2000},
    {"origin":{"name":"ห้างสรรพสินค้า บิ๊กซี ลาดพร้าว","address":"ถ.ลาดพร้าว กรุงเทพ","lat":13.8200,"lng":100.5700},"dest_name":"พระนครศรีอยุธยา","dest_lat":14.3692,"dest_lng":100.5878,"cargo":"สินค้าอุปโภคบริโภค","weight":5000,"revenue":3000},
    {"origin":{"name":"โรงงานน้ำตาลไทย","address":"ถ.สุขุมวิท สมุทรปราการ","lat":13.5950,"lng":100.5430},"dest_name":"นครราชสีมา","dest_lat":14.9799,"dest_lng":102.0978,"cargo":"น้ำตาลทราย 500 กระสอบ","weight":25000,"revenue":12000},
    {"origin":{"name":"ท่าเรือกรุงเทพ","address":"ถ.เจริญกรุง กรุงเทพ","lat":13.7030,"lng":100.5117},"dest_name":"ชลบุรี เมือง","dest_lat":13.3611,"dest_lng":100.9847,"cargo":"ตู้คอนเทนเนอร์สินค้า","weight":20000,"revenue":9000},
    {"origin":{"name":"ศูนย์กระจายสินค้า DC1","address":"ถ.บางนา-ตราด กม.19","lat":13.6200,"lng":100.7800},"dest_name":"พัทยา ชลบุรี","dest_lat":12.9236,"dest_lng":100.8825,"cargo":"เฟอร์นิเจอร์ ชุดห้องนอน","weight":2000,"revenue":4500},
    {"origin":{"name":"คลังสินค้า บริษัท A","address":"ถ.พหลโยธิน กรุงเทพ","lat":13.8400,"lng":100.5600},"dest_name":"สระบุรี","dest_lat":14.5289,"dest_lng":100.9105,"cargo":"วัสดุก่อสร้าง","weight":18000,"revenue":7000},
    # Chiang Mai area
    {"origin":{"name":"ตลาดวโรรส เชียงใหม่","address":"ถ.วิชยานนท์ เชียงใหม่","lat":18.7883,"lng":98.9853},"dest_name":"ลำพูน เมือง","dest_lat":18.5741,"dest_lng":99.0093,"cargo":"ผลิตภัณฑ์หัตถกรรม","weight":1500,"revenue":2500},
    {"origin":{"name":"โรงงานเซรามิก เชียงใหม่","address":"ถ.เชียงใหม่-ลำปาง","lat":18.7600,"lng":98.9900},"dest_name":"กรุงเทพ คลองเตย","dest_lat":13.7220,"dest_lng":100.5730,"cargo":"เซรามิก 1000 ชิ้น","weight":5000,"revenue":15000},
    {"origin":{"name":"ตลาดสินค้าเกษตร เชียงใหม่","address":"ถ.เชียงใหม่-เชียงราย","lat":18.8200,"lng":99.0000},"dest_name":"เชียงราย เมือง","dest_lat":19.9105,"dest_lng":99.8406,"cargo":"ผลไม้ 100 ตะกร้า","weight":3000,"revenue":4000},
    {"origin":{"name":"สวนส้มเชียงใหม่","address":"อ.ฝาง เชียงใหม่","lat":19.9200,"lng":99.2000},"dest_name":"ลำปาง เมือง","dest_lat":18.2889,"dest_lng":99.4932,"cargo":"ส้มสดบรรจุลัง 300 ลัง","weight":6000,"revenue":5500},
    # South Thailand
    {"origin":{"name":"ท่าเรือสุราษฎร์ธานี","address":"ถ.ชนเกษม สุราษฎร์ธานี","lat":9.1382,"lng":99.3214},"dest_name":"กรุงเทพ ท่าเรือคลองเตย","dest_lat":13.7030,"dest_lng":100.5117,"cargo":"ยางแผ่น 20 ตัน","weight":20000,"revenue":25000},
    {"origin":{"name":"สวนยางนครศรีธรรมราช","address":"อ.ฉวาง นครศรีธรรมราช","lat":8.4590,"lng":99.9840},"dest_name":"สุราษฎร์ธานี","dest_lat":9.1382,"dest_lng":99.3214,"cargo":"ยางดิบ 15 ตัน","weight":15000,"revenue":8000},
    {"origin":{"name":"โรงงานอาหารทะเล สงขลา","address":"ถ.ราษฎร์ยินดี หาดใหญ่","lat":7.0066,"lng":100.4772},"dest_name":"กรุงเทพ ตลาดไท","dest_lat":14.0700,"dest_lng":100.6200,"cargo":"อาหารทะเลแช่แข็ง","weight":8000,"revenue":18000},
    {"origin":{"name":"สวนปาล์ม กระบี่","address":"อ.เมือง กระบี่","lat":8.0863,"lng":98.9063},"dest_name":"สุราษฎร์ธานี โรงงาน","dest_lat":9.0800,"dest_lng":99.3500,"cargo":"ทะลายปาล์มสด","weight":20000,"revenue":5000},
    # Northeast (Isan)
    {"origin":{"name":"ตลาดกลางสินค้าเกษตร ขอนแก่น","address":"ถ.มิตรภาพ ขอนแก่น","lat":16.4419,"lng":102.8360},"dest_name":"กรุงเทพ ตลาดไท","dest_lat":14.0700,"dest_lng":100.6200,"cargo":"มันสำปะหลัง 30 ตัน","weight":30000,"revenue":20000},
    {"origin":{"name":"โรงงานแป้งมัน นครราชสีมา","address":"อ.สูงเนิน นครราชสีมา","lat":14.9200,"lng":101.7800},"dest_name":"แหลมฉบัง ชลบุรี","dest_lat":13.0849,"dest_lng":100.8792,"cargo":"แป้งมันสำปะหลัง","weight":25000,"revenue":18000},
    {"origin":{"name":"ฟาร์มโคเนื้อ อุดรธานี","address":"อ.หนองวัวซอ อุดรธานี","lat":17.4100,"lng":102.7600},"dest_name":"ตลาดนัดโค-กระบือ นครราชสีมา","dest_lat":15.0000,"dest_lng":102.0500,"cargo":"โคเนื้อ 20 ตัว","weight":12000,"revenue":12000},
    {"origin":{"name":"ท่าเรือเชียงแสน","address":"อ.เชียงแสน เชียงราย","lat":20.2667,"lng":100.0833},"dest_name":"กรุงเทพ","dest_lat":13.7563,"dest_lng":100.5018,"cargo":"สินค้านำเข้า MDF","weight":22000,"revenue":30000},
    # More Bangkok routes
    {"origin":{"name":"นิคมอุตสาหกรรม เวลโกรว์","address":"ฉะเชิงเทรา","lat":13.6842,"lng":101.0783},"dest_name":"แหลมฉบัง ชลบุรี","dest_lat":13.0849,"dest_lng":100.8792,"cargo":"ชิ้นส่วนรถยนต์","weight":8000,"revenue":5000},
    {"origin":{"name":"โรงงาน Amata City ระยอง","address":"อ.ปลวกแดง ระยอง","lat":12.9800,"lng":101.1000},"dest_name":"ท่าเรือมาบตาพุด ระยอง","dest_lat":12.6600,"dest_lng":101.1400,"cargo":"ปิโตรเคมี ถัง IBC","weight":18000,"revenue":7000},
    {"origin":{"name":"ห้างโลตัส บางใหญ่","address":"ถ.กาญจนาภิเษก นนทบุรี","lat":13.8600,"lng":100.4200},"dest_name":"นครปฐม","dest_lat":13.8199,"dest_lng":100.0625,"cargo":"สินค้าบริโภค","weight":4000,"revenue":2800},
    {"origin":{"name":"ศูนย์กระจายสินค้า Lazada","address":"ถ.สุวรรณภูมิ สมุทรปราการ","lat":13.7000,"lng":100.8000},"dest_name":"ปทุมธานี","dest_lat":14.0208,"dest_lng":100.5250,"cargo":"สินค้า E-commerce","weight":2000,"revenue":2500},
    {"origin":{"name":"โกดัง บริษัท CP","address":"ถ.พหลโยธิน ลำลูกกา ปทุมธานี","lat":13.9500,"lng":100.6800},"dest_name":"สระบุรี อยุธยา","dest_lat":14.5289,"dest_lng":100.9105,"cargo":"อาหารสัตว์ 500 กระสอบ","weight":12500,"revenue":5500},
    {"origin":{"name":"คลังน้ำมัน ปตท. ท่าเรือ","address":"ถ.สุขุมวิท สมุทรปราการ","lat":13.5800,"lng":100.5200},"dest_name":"นครปฐม ปตท.สาขา","dest_lat":13.8100,"dest_lng":100.0600,"cargo":"น้ำมันดีเซล 50,000 ลิตร","weight":40000,"revenue":35000},
    # Long distance
    {"origin":{"name":"ท่าเรือกรุงเทพ","address":"ถ.เจริญกรุง","lat":13.7030,"lng":100.5117},"dest_name":"เชียงใหม่ นิมมานเหมินท์","dest_lat":18.7934,"dest_lng":98.9691,"cargo":"เครื่องใช้ไฟฟ้า","weight":6000,"revenue":22000},
    {"origin":{"name":"นิคมอุตสาหกรรมแหลมฉบัง","address":"แหลมฉบัง ชลบุรี","lat":13.0849,"lng":100.8792},"dest_name":"หาดใหญ่ สงขลา","dest_lat":7.0066,"dest_lng":100.4772,"cargo":"รถยนต์ใหม่ 6 คัน","weight":12000,"revenue":45000},
    {"origin":{"name":"กรุงเทพ ดอนเมือง","address":"ถ.วิภาวดีรังสิต","lat":13.9126,"lng":100.6067},"dest_name":"ขอนแก่น เมือง","dest_lat":16.4419,"dest_lng":102.8360,"cargo":"วัสดุก่อสร้าง ซีแพค","weight":15000,"revenue":12000},
    {"origin":{"name":"โรงงาน อมตะ ระยอง","address":"อ.ปลวกแดง ระยอง","lat":12.9800,"lng":101.1000},"dest_name":"นครราชสีมา","dest_lat":14.9799,"dest_lng":102.0978,"cargo":"ชิ้นส่วนอิเล็กทรอนิกส์","weight":4000,"revenue":9000},
    {"origin":{"name":"สวนผลไม้ เพชรบุรี","address":"อ.ชะอำ เพชรบุรี","lat":12.7958,"lng":99.9654},"dest_name":"ตลาดสี่มุมเมือง กรุงเทพ","dest_lat":13.9700,"dest_lng":100.6800,"cargo":"ผลไม้สด มะม่วง สับปะรด","weight":8000,"revenue":8000},
    {"origin":{"name":"โรงสีข้าว สุพรรณบุรี","address":"อ.เมือง สุพรรณบุรี","lat":14.4744,"lng":100.1177},"dest_name":"กรุงเทพ ท่าเรือ","dest_lat":13.7030,"dest_lng":100.5117,"cargo":"ข้าวสาร บรรจุถุง 100 ตัน","weight":100000,"revenue":80000},
    {"origin":{"name":"ท่าอากาศยานดอนเมือง","address":"กรุงเทพ","lat":13.9126,"lng":100.6067},"dest_name":"นครราชสีมา โคราช","dest_lat":14.9799,"dest_lng":102.0978,"cargo":"สินค้าด่วน พัสดุ","weight":500,"revenue":3500},
    {"origin":{"name":"โรงงาน Mitsubishi Motor","address":"ปทุมธานี","lat":14.0208,"lng":100.5250},"dest_name":"ท่าเรือกรุงเทพ","dest_lat":13.7030,"dest_lng":100.5117,"cargo":"รถยนต์ส่งออก 8 คัน","weight":16000,"revenue":25000},
    {"origin":{"name":"ตลาดยิ่งเจริญ กรุงเทพ","address":"ถ.เอกชัย กรุงเทพ","lat":13.6900,"lng":100.4300},"dest_name":"สมุทรสาคร เมือง","dest_lat":13.5471,"dest_lng":100.2740,"cargo":"ผัก ผลไม้ สด","weight":5000,"revenue":2500},
    {"origin":{"name":"ท่าเรือสงขลา","address":"อ.เมือง สงขลา","lat":7.2000,"lng":100.5800},"dest_name":"กรุงเทพ อมตะ","dest_lat":13.6200,"dest_lng":100.7800,"cargo":"ปลาทูน่าแปรรูป","weight":10000,"revenue":28000},
    {"origin":{"name":"นิคมอุตสาหกรรม กบินทร์บุรี","address":"ปราจีนบุรี","lat":13.9800,"lng":101.7200},"dest_name":"แหลมฉบัง","dest_lat":13.0849,"dest_lng":100.8792,"cargo":"เฟอร์นิเจอร์ส่งออก","weight":7000,"revenue":10000},
    {"origin":{"name":"โรงงาน Thai Union ระยอง","address":"อ.นิคมพัฒนา ระยอง","lat":12.9000,"lng":101.2000},"dest_name":"กรุงเทพ ท่าเรือ","dest_lat":13.7030,"dest_lng":100.5117,"cargo":"อาหารทะเลกระป๋อง","weight":12000,"revenue":15000},
    {"origin":{"name":"ท่าอากาศยานสุวรรณภูมิ","address":"สมุทรปราการ","lat":13.6900,"lng":100.7501},"dest_name":"กรุงเทพ คลองเตย","dest_lat":13.7220,"dest_lng":100.5730,"cargo":"สินค้านำเข้า พัสดุด่วน","weight":1000,"revenue":4000},
    {"origin":{"name":"โรงงาน Central Kitchen","address":"ปทุมธานี","lat":14.0500,"lng":100.5700},"dest_name":"เชียงใหม่ เซ็นทรัล","dest_lat":18.7883,"dest_lng":98.9853,"cargo":"วัตถุดิบอาหาร","weight":3000,"revenue":14000},
    {"origin":{"name":"คลังสินค้า SCG บางซื่อ","address":"กรุงเทพ","lat":13.8100,"lng":100.5300},"dest_name":"นครปฐม ก่อสร้าง","dest_lat":13.8199,"dest_lng":100.0625,"cargo":"ปูนซีเมนต์ 600 ถุง","weight":30000,"revenue":12000},
    {"origin":{"name":"ตลาด OTOP เชียงราย","address":"เชียงราย","lat":19.9105,"lng":99.8406},"dest_name":"กรุงเทพ สยามพารากอน","dest_lat":13.7466,"dest_lng":100.5337,"cargo":"ผลิตภัณฑ์ชุมชน OTOP","weight":800,"revenue":6000},
    {"origin":{"name":"ฟาร์มไก่ สระบุรี","address":"สระบุรี","lat":14.5289,"lng":100.9105},"dest_name":"โรงงาน CP อยุธยา","dest_lat":14.3692,"dest_lng":100.5878,"cargo":"ไก่เป็น 5,000 ตัว","weight":8000,"revenue":9000},
    {"origin":{"name":"ตลาดกลางยาง ระยอง","address":"ระยอง","lat":12.6800,"lng":101.2700},"dest_name":"โรงงานยาง ชลบุรี","dest_lat":13.1000,"dest_lng":100.9200,"cargo":"ยางแผ่นรมควัน","weight":15000,"revenue":7000},
    {"origin":{"name":"ท่าเรือระนอง","address":"ระนอง","lat":9.9587,"lng":98.6253},"dest_name":"กรุงเทพ","dest_lat":13.7563,"dest_lng":100.5018,"cargo":"ปลาสดจากเมียนมา","weight":5000,"revenue":12000},
    {"origin":{"name":"สวนทุเรียน จันทบุรี","address":"จันทบุรี","lat":12.6094,"lng":102.1040},"dest_name":"ตลาดไท ปทุมธานี","dest_lat":14.0700,"dest_lng":100.6200,"cargo":"ทุเรียน 200 ผล","weight":3000,"revenue":8000},
    {"origin":{"name":"โรงงาน PCB สมุทรปราการ","address":"สมุทรปราการ","lat":13.5891,"lng":100.6500},"dest_name":"นิคมโรจนะ อยุธยา","dest_lat":14.3500,"dest_lng":100.6900,"cargo":"แผงวงจรอิเล็กทรอนิกส์","weight":500,"revenue":5000},
    {"origin":{"name":"ท่าเรือมาบตาพุด ระยอง","address":"มาบตาพุด ระยอง","lat":12.6600,"lng":101.1400},"dest_name":"นิคมอุตสาหกรรมบางปู","dest_lat":13.4900,"dest_lng":100.6400,"cargo":"สารเคมีอุตสาหกรรม ถัง IBC","weight":20000,"revenue":18000},
    {"origin":{"name":"โรงพยาบาล พระมงกุฎ","address":"กรุงเทพ","lat":13.7600,"lng":100.5100},"dest_name":"โรงพยาบาล นครราชสีมา","dest_lat":14.9799,"dest_lng":102.0978,"cargo":"เวชภัณฑ์ ยา","weight":500,"revenue":7000},
    {"origin":{"name":"บริษัท 3BB","address":"ถ.แจ้งวัฒนะ กรุงเทพ","lat":13.8900,"lng":100.5600},"dest_name":"ขอนแก่น เมือง","dest_lat":16.4419,"dest_lng":102.8360,"cargo":"อุปกรณ์สื่อสาร โมเด็ม","weight":2000,"revenue":8000},
]

trip_ids = []
statuses_to_set = (
    ["started"] * 12 +
    ["delivering"] * 5 +
    ["completed"] * 15 +
    ["accepted"] * 8 +
    ["pending"] * 10
)

for i, t in enumerate(trip_routes):
    vi = i % len(vehicle_ids)
    di = i % len(driver_ids)
    payload = {
        "vehicle_id": vehicle_ids[vi] if vehicle_ids else "",
        "driver_id": driver_ids[di] if driver_ids else "",
        "origin": t["origin"],
        "destinations": [{
            "seq": 1,
            "name": t["dest_name"],
            "address": t["dest_name"],
            "lat": t["dest_lat"],
            "lng": t["dest_lng"],
        }],
        "cargo": {"description": t["cargo"], "weight_kg": t["weight"]},
        "planned_start": "2026-03-31T06:00:00Z",
        "planned_end": "2026-03-31T18:00:00Z",
        "revenue": t["revenue"],
    }
    tid = post("/trips", payload)
    if tid:
        trip_ids.append(tid)
        target_status = statuses_to_set[i] if i < len(statuses_to_set) else "pending"
        if target_status != "pending":
            put(f"/trips/{tid}/status", {"status": target_status})
        print(f"  [{i+1:2d}] {t['origin']['name'][:30]} -> {t['dest_name'][:20]} [{target_status}]")
    else:
        print(f"  [FAIL] Trip {i+1}")

print(f"\nTrips created: {len(trip_ids)}/50")

# ============================================================
# SUMMARY
# ============================================================
print("\n" + "=" * 50)
print("  SEED COMPLETE!")
print(f"  Vehicles: {len(vehicle_ids)}/100")
print(f"  GPS set:  {len(vehicle_ids)} locations")
print(f"  Drivers:  {len(driver_ids)}/30")
print(f"  Trips:    {len(trip_ids)}/50")
print("=" * 50)
