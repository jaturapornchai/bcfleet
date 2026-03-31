// Sync trips + alerts from MongoDB to PostgreSQL-compatible SQL
var trips = db.fleet_trips.find({}).toArray();
trips.forEach(function(t) {
  var id = t._id.toString();
  var costs = t.costs || {};
  var cargo = t.cargo || {};
  var origin = t.origin || {};
  var originName = (origin.name || "").replace(/\$/g, "");
  var cargoDesc = (cargo.description || "").replace(/\$/g, "");
  print("INSERT INTO fleet_trips (id, shop_id, trip_no, status, vehicle_id, driver_id, origin_name, destination_count, cargo_description, cargo_weight_kg, revenue, total_cost, profit, created_at, updated_at) VALUES ('" + id + "', '" + (t.shop_id||"") + "', '" + (t.trip_no||"") + "', '" + (t.status||"") + "', '" + (t.vehicle_id||"") + "', '" + (t.driver_id||"") + "', '" + originName + "', 1, '" + cargoDesc + "', " + (cargo.weight_kg||0) + ", " + (costs.revenue||0) + ", " + (costs.total||0) + ", " + (costs.profit||0) + ", NOW(), NOW()) ON CONFLICT (id) DO UPDATE SET status=EXCLUDED.status;");
});

var alerts = db.fleet_alerts.find({}).toArray();
alerts.forEach(function(a) {
  var id = a._id.toString();
  var msg = (a.message || "").replace(/'/g, "");
  print("INSERT INTO fleet_alerts (id, shop_id, type, entity, entity_id, title, message, severity, days_remaining, status, created_at) VALUES ('" + id + "', '" + (a.shop_id||"") + "', '" + (a.type||"") + "', '" + (a.entity||"") + "', '" + (a.entity_id||"") + "', '" + (a.title||"") + "', '" + msg + "', '" + (a.severity||"info") + "', " + (a.days_remaining||0) + ", '" + (a.status||"active") + "', NOW()) ON CONFLICT (id) DO NOTHING;");
});

print("-- Sync done");
