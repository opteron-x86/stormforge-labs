-- Personnel Records
CREATE TABLE IF NOT EXISTS personnel (
    id SERIAL PRIMARY KEY,
    service_number VARCHAR(20) NOT NULL,
    name VARCHAR(100) NOT NULL,
    rank VARCHAR(50),
    unit VARCHAR(100),
    clearance_level VARCHAR(20),
    status VARCHAR(20)
);

-- Mission Briefings
CREATE TABLE IF NOT EXISTS mission_briefings (
    id SERIAL PRIMARY KEY,
    operation_name VARCHAR(100) NOT NULL,
    classification VARCHAR(20) NOT NULL,
    briefing_date DATE,
    summary TEXT
);

-- Asset Inventory
CREATE TABLE IF NOT EXISTS asset_inventory (
    id SERIAL PRIMARY KEY,
    asset_id VARCHAR(30) NOT NULL,
    asset_type VARCHAR(50),
    location VARCHAR(100),
    status VARCHAR(20)
);

-- System Configuration
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT,
    classification VARCHAR(20)
);

INSERT INTO personnel (service_number, name, rank, unit, clearance_level, status) VALUES
('USA-847261', 'Morrison, James T.', 'Colonel', '75th Ranger Regiment', 'TOP SECRET/SCI', 'Active'),
('USA-293847', 'Chen, Sarah L.', 'Major', 'Military Intelligence', 'TOP SECRET/SCI', 'Active'),
('USA-182736', 'Rodriguez, Michael A.', 'Captain', 'Special Forces ODA 7215', 'SECRET', 'Active'),
('USN-928374', 'Williams, David R.', 'Commander', 'SEAL Team 6', 'TOP SECRET/SCI', 'Active'),
('USAF-374829', 'Thompson, Jennifer K.', 'Lieutenant Colonel', '24th Intelligence Squadron', 'TOP SECRET/SCI', 'Active');

INSERT INTO mission_briefings (operation_name, classification, briefing_date, summary) VALUES
('NORTHERN SENTINEL', 'TOP SECRET', '2024-01-15', 'Arctic surveillance and early warning operations'),
('DESERT LANCE', 'SECRET', '2024-02-20', 'Force protection and area denial in CENTCOM AOR'),
('PACIFIC SHIELD', 'TOP SECRET/SCI', '2024-03-10', 'Maritime interdiction and surveillance operations');

INSERT INTO asset_inventory (asset_id, asset_type, location, status) VALUES
('UAV-SENTINEL-001', 'MQ-9 Reaper', 'Al Udeid Air Base', 'Operational'),
('HELO-NIGHTSTALKER-007', 'MH-60M Black Hawk', 'Fort Campbell', 'Operational'),
('SATCOM-ALPHA-003', 'Mobile SATCOM Terminal', 'Camp Lemonnier', 'Operational');

INSERT INTO system_config (config_key, config_value, classification) VALUES
('feed_aggregator_version', '2.4.1', 'UNCLASSIFIED'),
('max_concurrent_feeds', '50', 'UNCLASSIFIED'),
('allowed_feed_domains', 'threatfeeds.gov,intel.ic.gov,cisa.gov', 'CONFIDENTIAL'),
('master_encryption_key', 'FLAG{ssrf_to_imds_secrets_manager_rds_exfiltration}', 'TOP SECRET/SCI'),
('backup_schedule', '0 2 * * *', 'UNCLASSIFIED');
