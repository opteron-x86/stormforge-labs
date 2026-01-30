-- User Wallets
CREATE TABLE IF NOT EXISTS wallets (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    wallet_address VARCHAR(64) NOT NULL,
    wallet_type VARCHAR(20),
    created_at TIMESTAMP,
    kyc_verified BOOLEAN
);

-- Account Balances
CREATE TABLE IF NOT EXISTS balances (
    id SERIAL PRIMARY KEY,
    wallet_id INTEGER REFERENCES wallets(id),
    asset VARCHAR(10) NOT NULL,
    balance DECIMAL(20, 8),
    last_updated TIMESTAMP
);

-- API Keys
CREATE TABLE IF NOT EXISTS api_keys (
    id SERIAL PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    key_hash VARCHAR(64) NOT NULL,
    permissions VARCHAR(50),
    created_at TIMESTAMP,
    last_used TIMESTAMP
);

-- Transaction History
CREATE TABLE IF NOT EXISTS transactions (
    id SERIAL PRIMARY KEY,
    tx_hash VARCHAR(66) NOT NULL,
    from_wallet VARCHAR(64),
    to_wallet VARCHAR(64),
    asset VARCHAR(10),
    amount DECIMAL(20, 8),
    usd_value DECIMAL(15, 2),
    tx_type VARCHAR(20),
    timestamp TIMESTAMP
);

-- System Configuration
CREATE TABLE IF NOT EXISTS system_config (
    id SERIAL PRIMARY KEY,
    config_key VARCHAR(100) NOT NULL,
    config_value TEXT,
    is_sensitive BOOLEAN DEFAULT false
);

INSERT INTO wallets (user_id, wallet_address, wallet_type, created_at, kyc_verified) VALUES
('USR-001', '0x742d35Cc6634C0532925a3b844Bc9e7595f8bE21', 'ETH', '2024-01-15 09:23:41', true),
('USR-002', '0x8Ba1f109551bD432803012645Ac136ddd64DBA72', 'ETH', '2024-02-03 14:17:22', true),
('USR-003', 'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh', 'BTC', '2024-02-20 11:45:33', true),
('USR-004', '0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C', 'ETH', '2024-03-08 16:32:19', false),
('USR-005', '5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d', 'SOL', '2024-03-15 08:51:07', true);

INSERT INTO balances (wallet_id, asset, balance, last_updated) VALUES
(1, 'ETH', 142.58742000, '2024-12-01 12:00:00'),
(1, 'USDC', 847293.42000000, '2024-12-01 12:00:00'),
(2, 'ETH', 2847.12938400, '2024-12-01 12:00:00'),
(2, 'WBTC', 15.84729100, '2024-12-01 12:00:00'),
(3, 'BTC', 847.29481000, '2024-12-01 12:00:00'),
(4, 'ETH', 0.84729300, '2024-12-01 12:00:00'),
(5, 'SOL', 48291.84729000, '2024-12-01 12:00:00');

INSERT INTO api_keys (user_id, key_hash, permissions, created_at, last_used) VALUES
('USR-001', 'pk_live_8f2k9d7h3m5n1p4q6r8s0t2u4v6w8x0y', 'trade,withdraw', '2024-01-15 09:30:00', '2024-12-01 11:45:22'),
('USR-002', 'pk_live_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6', 'trade,read', '2024-02-03 14:20:00', '2024-12-01 10:33:17'),
('USR-003', 'pk_live_q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2', 'trade,withdraw,admin', '2024-02-20 11:50:00', '2024-12-01 09:15:44'),
('SVC-INT', 'pk_internal_MASTER_x8k2m5p9r3t7v1y4', 'full_access', '2024-01-01 00:00:00', '2024-12-01 12:00:01');

INSERT INTO transactions (tx_hash, from_wallet, to_wallet, asset, amount, usd_value, tx_type, timestamp) VALUES
('0x8f2a9e4c7b1d3f6a8e0c2b4d6f8a0c2e4f6a8b0c', '0x742d35Cc6634C0532925a3b844Bc9e7595f8bE21', '0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C', 'ETH', 50.00000000, 162500.00, 'transfer', '2024-11-28 14:23:41'),
('0xa1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0', '0x8Ba1f109551bD432803012645Ac136ddd64DBA72', NULL, 'USDC', 500000.00000000, 500000.00, 'withdrawal', '2024-11-29 09:15:33'),
('0xd4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3', NULL, '0x742d35Cc6634C0532925a3b844Bc9e7595f8bE21', 'ETH', 25.00000000, 81250.00, 'deposit', '2024-11-30 16:42:18');

INSERT INTO system_config (config_key, config_value, is_sensitive) VALUES
('aggregator_version', '3.2.1', false),
('max_oracle_deviation', '0.05', false),
('approved_oracles', 'chainlink.eth,pyth.network,band.protocol', false),
('hot_wallet_private_key', 'FLAG{ssrf_to_imds_secrets_manager_rds_exfiltration}', true),
('withdrawal_delay_seconds', '3600', false),
('emergency_shutdown', 'false', false);