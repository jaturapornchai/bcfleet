CREATE OR REPLACE VIEW fleet_dashboard_summary AS
SELECT
    shop_id,
    COUNT(*) FILTER (WHERE status = 'active') as active_vehicles,
    COUNT(*) FILTER (WHERE status = 'maintenance') as vehicles_in_maintenance,
    COUNT(*) FILTER (WHERE health_status = 'red') as critical_vehicles,
    COUNT(*) FILTER (WHERE health_status = 'yellow') as warning_vehicles
FROM fleet_vehicles
WHERE deleted_at IS NULL
GROUP BY shop_id;

CREATE OR REPLACE VIEW fleet_today_trips AS
SELECT
    shop_id,
    COUNT(*) as total_trips,
    COUNT(*) FILTER (WHERE status = 'completed') as completed,
    COUNT(*) FILTER (WHERE status IN ('started', 'delivering')) as in_progress,
    COUNT(*) FILTER (WHERE status = 'pending') as pending,
    COALESCE(SUM(revenue), 0) as total_revenue,
    COALESCE(SUM(total_cost), 0) as total_cost,
    COALESCE(SUM(profit), 0) as total_profit
FROM fleet_trips
WHERE DATE(planned_start) = CURRENT_DATE
GROUP BY shop_id;
