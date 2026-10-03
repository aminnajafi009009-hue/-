-- ============================================================
-- migration.sql  —  Business VPN Bot — نسخه پچ ۳۰ آیتمی
-- اجرا: sqlite3 bot_database.db < migration.sql
-- ایمن (IF NOT EXISTS / IF NOT EXISTS column workaround)
-- ============================================================

PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;

-- -------------------------------------------------------
-- ۱. جدول settings (باید از قبل وجود داشته باشد)
--    مقادیر جدید با INSERT OR IGNORE اضافه می‌شوند
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS settings (
    key   TEXT PRIMARY KEY,
    value TEXT
);

-- مقادیر پیش‌فرض برای روش‌های پرداخت
INSERT OR IGNORE INTO settings (key, value) VALUES ('card_payment_enabled',   '1');
INSERT OR IGNORE INTO settings (key, value) VALUES ('wallet_payment_enabled', '1');
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_payment_enabled', '0');
INSERT OR IGNORE INTO settings (key, value) VALUES ('payg_enabled',           '0');

-- Crypto fallback (بند ۲۳)
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_backup_price_USDT',    NULL);
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_backup_enabled_USDT',  '0');
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_backup_price_BTC',     NULL);
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_backup_enabled_BTC',   '0');
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_backup_price_TON',     NULL);
INSERT OR IGNORE INTO settings (key, value) VALUES ('crypto_backup_enabled_TON',   '0');

-- PAYG قیمت‌گذاری (بند ۷)
INSERT OR IGNORE INTO settings (key, value) VALUES ('payg_price_per_gb',       '0');
INSERT OR IGNORE INTO settings (key, value) VALUES ('payg_pricing_mode',       'global');   -- global|category|plan

-- پنل‌های تست رایگان (بند ۱۴)
INSERT OR IGNORE INTO settings (key, value) VALUES ('free_test_panels', '[]');

-- Bot username (بند ۲۰)
INSERT OR IGNORE INTO settings (key, value) VALUES ('bot_username', '');

-- -------------------------------------------------------
-- ۲. جدول rich_text_templates  (بند ۱۳ — ذخیره Rich Text)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS rich_text_templates (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    label       TEXT    NOT NULL,          -- نام نمایشی قالب
    content     TEXT    NOT NULL,          -- متن با فرمت markdown/html
    emoji_pack  TEXT    DEFAULT NULL,      -- نام پک اموجی سفارشی
    created_at  TEXT    DEFAULT (datetime('now')),
    updated_at  TEXT    DEFAULT (datetime('now'))
);

-- -------------------------------------------------------
-- ۳. جدول vip_folders  (بند ۱۱ — پوشه/زیرپوشه VIP)
--    از Cherry VPN الگو گرفته شده
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS vip_folders (
    id          TEXT    PRIMARY KEY,       -- UUID
    name        TEXT    NOT NULL,
    parent_id   TEXT    DEFAULT NULL,      -- NULL = ریشه
    order_idx   INTEGER DEFAULT 0,
    enabled     INTEGER DEFAULT 1,
    created_at  TEXT    DEFAULT (datetime('now')),
    FOREIGN KEY (parent_id) REFERENCES vip_folders(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS vip_folder_items (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    folder_id   TEXT    NOT NULL,
    plan_key    TEXT    NOT NULL,
    order_idx   INTEGER DEFAULT 0,
    FOREIGN KEY (folder_id) REFERENCES vip_folders(id) ON DELETE CASCADE
);

-- -------------------------------------------------------
-- ۴. ایندکس‌ها
-- -------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_vip_folder_parent ON vip_folders(parent_id);
CREATE INDEX IF NOT EXISTS idx_vip_folder_items_folder ON vip_folder_items(folder_id);

-- -------------------------------------------------------
-- ۵. اطمینان از وجود ستون audience در جدول broadcasts
--    (SQLite از ALTER TABLE ADD COLUMN پشتیبانی می‌کند)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS broadcasts (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    message     TEXT,
    audience    TEXT    DEFAULT 'all',
    sent_count  INTEGER DEFAULT 0,
    fail_count  INTEGER DEFAULT 0,
    created_at  TEXT    DEFAULT (datetime('now'))
);

-- -------------------------------------------------------
-- ۶. اطمینان از وجود ستون audience در جدول gift_logs
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS gift_logs (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    amount      INTEGER NOT NULL,
    audience    TEXT    DEFAULT 'all',
    recipients  INTEGER DEFAULT 0,
    description TEXT,
    created_at  TEXT    DEFAULT (datetime('now'))
);

-- -------------------------------------------------------
PRAGMA integrity_check;
SELECT 'migration completed OK' AS status;
