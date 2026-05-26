-- w2f-garage manual install script
--
-- WARNING:
-- - Review this file before running it.
-- - Back up your database first.
-- - This resource does not run migrations automatically.
-- - This file intentionally does not alter, drop, or overwrite existing player vehicle tables.
-- - Confirm existing framework vehicle table names before wiring production ownership loading.

CREATE TABLE IF NOT EXISTS `w2f_garage_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `action` VARCHAR(64) NOT NULL,
    `player_identifier` VARCHAR(96) NULL,
    `player_name` VARCHAR(128) NULL,
    `plate` VARCHAR(16) NULL,
    `vehicle_model` VARCHAR(64) NULL,
    `garage_id` VARCHAR(64) NULL,
    `details` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_w2f_garage_logs_plate` (`plate`),
    KEY `idx_w2f_garage_logs_identifier` (`player_identifier`),
    KEY `idx_w2f_garage_logs_action` (`action`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_vehicle_history` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NULL,
    `from_state` VARCHAR(32) NULL,
    `to_state` VARCHAR(32) NULL,
    `garage_id` VARCHAR(64) NULL,
    `reason` VARCHAR(128) NULL,
    `metadata` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_w2f_history_plate` (`plate`),
    KEY `idx_w2f_history_owner` (`owner_identifier`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_impounds` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NULL,
    `garage_id` VARCHAR(64) NULL,
    `fee` INT UNSIGNED NOT NULL DEFAULT 0,
    `reason` VARCHAR(255) NULL,
    `status` VARCHAR(32) NOT NULL DEFAULT 'active',
    `impounded_by` VARCHAR(96) NULL,
    `released_by` VARCHAR(96) NULL,
    `released_at` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_w2f_impounds_plate` (`plate`),
    KEY `idx_w2f_impounds_owner` (`owner_identifier`),
    KEY `idx_w2f_impounds_status` (`status`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_state_overrides` (
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NULL,
    `garage_id` VARCHAR(64) NULL,
    `state` VARCHAR(32) NOT NULL DEFAULT 'unknown',
    `fuel` FLOAT NULL,
    `engine_health` FLOAT NULL,
    `body_health` FLOAT NULL,
    `dirt_level` FLOAT NULL,
    `vehicle_properties` JSON NULL,
    `last_location` JSON NULL,
    `last_garage` VARCHAR(64) NULL,
    `last_stored_at` TIMESTAMP NULL DEFAULT NULL,
    `last_spawned_at` TIMESTAMP NULL DEFAULT NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`),
    KEY `idx_w2f_state_owner` (`owner_identifier`),
    KEY `idx_w2f_state_garage` (`garage_id`),
    KEY `idx_w2f_state_state` (`state`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_transfers` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NULL,
    `from_garage` VARCHAR(64) NULL,
    `to_garage` VARCHAR(64) NULL,
    `status` VARCHAR(32) NOT NULL DEFAULT 'pending',
    `fee` INT UNSIGNED NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `completed_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_w2f_transfers_plate` (`plate`),
    KEY `idx_w2f_transfers_owner` (`owner_identifier`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_insurance` (
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NULL,
    `policy_number` VARCHAR(64) NULL,
    `status` VARCHAR(32) NOT NULL DEFAULT 'inactive',
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    `metadata` JSON NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`),
    KEY `idx_w2f_insurance_owner` (`owner_identifier`),
    KEY `idx_w2f_insurance_status` (`status`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_mileage` (
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NULL,
    `mileage` FLOAT NOT NULL DEFAULT 0,
    `last_location` JSON NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`),
    KEY `idx_w2f_mileage_owner` (`owner_identifier`)
);

CREATE TABLE IF NOT EXISTS `w2f_owned_garages` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `garage_id` VARCHAR(64) NOT NULL,
    `owner_identifier` VARCHAR(96) NOT NULL,
    `purchase_price` INT UNSIGNED NOT NULL DEFAULT 0,
    `purchase_timestamp` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `interior_template` VARCHAR(64) NULL,
    `property_class` VARCHAR(32) NULL,
    `active` TINYINT(1) NOT NULL DEFAULT 1,
    `used_slots` INT UNSIGNED NOT NULL DEFAULT 0,
    `current_floor` INT UNSIGNED NOT NULL DEFAULT 1,
    `metadata` JSON NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_w2f_owned_garage` (`garage_id`, `owner_identifier`),
    KEY `idx_w2f_owned_owner` (`owner_identifier`),
    KEY `idx_w2f_owned_garage` (`garage_id`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_slots` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `garage_id` VARCHAR(64) NOT NULL,
    `owner_identifier` VARCHAR(96) NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `model` VARCHAR(64) NULL,
    `slot_index` INT UNSIGNED NOT NULL,
    `floor_index` INT UNSIGNED NOT NULL DEFAULT 1,
    `slot_type` VARCHAR(16) NOT NULL DEFAULT 'vehicle',
    `vehicle_props` JSON NULL,
    `fuel` FLOAT NULL,
    `engine_health` FLOAT NULL,
    `body_health` FLOAT NULL,
    `dirt_level` FLOAT NULL,
    `locked` TINYINT(1) NOT NULL DEFAULT 1,
    `state` VARCHAR(32) NOT NULL DEFAULT 'stored',
    `last_stored_at` TIMESTAMP NULL DEFAULT NULL,
    `last_spawned_at` TIMESTAMP NULL DEFAULT NULL,
    `last_location` JSON NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_w2f_slot_plate` (`garage_id`, `plate`),
    UNIQUE KEY `uk_w2f_slot_position` (`garage_id`, `owner_identifier`, `slot_index`, `floor_index`, `slot_type`),
    KEY `idx_w2f_slots_owner` (`owner_identifier`),
    KEY `idx_w2f_slots_state` (`state`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_interiors` (
    `garage_id` VARCHAR(64) NOT NULL,
    `interior_template` VARCHAR(64) NOT NULL,
    `routing_bucket` INT UNSIGNED NULL,
    `metadata` JSON NULL,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`garage_id`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_vehicle_positions` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `garage_id` VARCHAR(64) NOT NULL,
    `interior_template` VARCHAR(64) NOT NULL,
    `slot_index` INT UNSIGNED NOT NULL,
    `floor_index` INT UNSIGNED NOT NULL DEFAULT 1,
    `slot_type` VARCHAR(16) NOT NULL DEFAULT 'vehicle',
    `coords` JSON NOT NULL,
    `heading` FLOAT NULL,
    `theme` VARCHAR(64) NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_w2f_position` (`garage_id`, `interior_template`, `slot_index`, `floor_index`, `slot_type`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_purchase_logs` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `garage_id` VARCHAR(64) NOT NULL,
    `owner_identifier` VARCHAR(96) NOT NULL,
    `price` INT UNSIGNED NOT NULL DEFAULT 0,
    `action` VARCHAR(32) NOT NULL DEFAULT 'purchase',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_w2f_purchase_owner` (`owner_identifier`),
    KEY `idx_w2f_purchase_garage` (`garage_id`)
);

CREATE TABLE IF NOT EXISTS `w2f_public_garage_vehicles` (
    `plate` VARCHAR(16) NOT NULL,
    `owner_identifier` VARCHAR(96) NOT NULL,
    `garage_id` VARCHAR(64) NOT NULL,
    `garage_type` VARCHAR(32) NOT NULL DEFAULT 'public',
    `model` VARCHAR(64) NULL,
    `vehicle_props` JSON NULL,
    `fuel` FLOAT NULL,
    `engine_health` FLOAT NULL,
    `body_health` FLOAT NULL,
    `dirt_level` FLOAT NULL,
    `state` VARCHAR(32) NOT NULL DEFAULT 'stored_public',
    `stored_at` BIGINT UNSIGNED NOT NULL,
    `last_fee_calculated_at` BIGINT UNSIGNED NOT NULL,
    `unpaid_fee` INT UNSIGNED NOT NULL DEFAULT 0,
    `daily_fee` INT UNSIGNED NOT NULL DEFAULT 700,
    `paid_until` BIGINT UNSIGNED NULL DEFAULT NULL,
    `current_bill_id` BIGINT UNSIGNED NULL DEFAULT NULL,
    `last_spawned_at` BIGINT UNSIGNED NULL DEFAULT NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`plate`),
    KEY `idx_w2f_public_owner` (`owner_identifier`),
    KEY `idx_w2f_public_garage` (`garage_id`),
    KEY `idx_w2f_public_state` (`state`)
);

CREATE TABLE IF NOT EXISTS `w2f_public_garage_bills` (
    `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    `owner_identifier` VARCHAR(96) NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `garage_id` VARCHAR(64) NOT NULL,
    `bill_type` VARCHAR(32) NOT NULL DEFAULT 'storage',
    `amount` INT UNSIGNED NOT NULL DEFAULT 0,
    `daily_fee` INT UNSIGNED NOT NULL DEFAULT 700,
    `billable_days` INT UNSIGNED NOT NULL DEFAULT 0,
    `billing_anchor` BIGINT UNSIGNED NOT NULL,
    `paid_until` BIGINT UNSIGNED NULL DEFAULT NULL,
    `status` VARCHAR(16) NOT NULL DEFAULT 'pending',
    `provider` VARCHAR(32) NOT NULL DEFAULT 'internal',
    `provider_bill_id` VARCHAR(96) NULL,
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `paid_at` TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_w2f_public_bills_owner` (`owner_identifier`),
    KEY `idx_w2f_public_bills_plate` (`plate`),
    KEY `idx_w2f_public_bills_status` (`status`)
);

CREATE TABLE IF NOT EXISTS `w2f_garage_favourites` (
    `owner_identifier` VARCHAR(96) NOT NULL,
    `plate` VARCHAR(16) NOT NULL,
    `favourite` TINYINT(1) NOT NULL DEFAULT 1,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`owner_identifier`, `plate`),
    KEY `idx_w2f_favourites_plate` (`plate`)
);
