-- ============================================
-- COMPLETE DATABASE SETUP - CLEAN VERSION
-- Run this once in Supabase SQL Editor
-- ============================================

-- 1. Create tables (if not exist)
CREATE TABLE IF NOT EXISTS menu_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    price integer NOT NULL,
    category text DEFAULT 'Other',
    image_url text,
    points_reward integer DEFAULT 10,
    is_available boolean DEFAULT true,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_name text,
    customer_phone text,
    customer_email text,
    customer_address text,
    items_ordered jsonb,
    total_price integer,
    original_price integer DEFAULT 0,
    discount_amount integer DEFAULT 0,
    points_used integer DEFAULT 0,
    status text DEFAULT 'Pending',
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS game_scores (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    player_name text NOT NULL,
    user_email text,
    phone text,
    score integer DEFAULT 0,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS daily_missions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    title text,
    description text,
    reward_points integer DEFAULT 50,
    reward_text text,
    active_date date UNIQUE,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS receipt_codes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    code text UNIQUE NOT NULL,
    points_value integer DEFAULT 20,
    is_used boolean DEFAULT false,
    used_by_email text,
    used_at timestamptz,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS points_transactions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_email text,
    points integer,
    reason text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS discount_config (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    points_to_pkr integer DEFAULT 1,
    max_discount_percent integer DEFAULT 50,
    min_points_to_redeem integer DEFAULT 10,
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS treasure_codes (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    code text UNIQUE NOT NULL,
    title text DEFAULT 'Treasure Found',
    points_value integer DEFAULT 50,
    reward_description text,
    is_used boolean DEFAULT false,
    used_by text,
    used_by_name text,
    used_at timestamptz,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS treasure_redemptions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    code text NOT NULL,
    user_email text NOT NULL,
    user_name text,
    points_earned integer,
    redeemed_date date,
    redeemed_at timestamptz DEFAULT now()
);

-- 2. Add missing columns to orders (safety check)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='original_price') THEN
        ALTER TABLE orders ADD COLUMN original_price integer DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='discount_amount') THEN
        ALTER TABLE orders ADD COLUMN discount_amount integer DEFAULT 0;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='points_used') THEN
        ALTER TABLE orders ADD COLUMN points_used integer DEFAULT 0;
    END IF;
END $$;

-- 3. Insert sample data (only if tables are empty)
INSERT INTO menu_items (name, description, price, category, points_reward, is_available)
SELECT * FROM (VALUES
    ('Chicken Zinger Burger', 'Crispy fried chicken with spicy mayo', 450, 'Burgers', 15, true),
    ('Beef Burger', 'Juicy beef patty with cheese', 500, 'Burgers', 15, true),
    ('Chicken Fajita Pizza', 'Spicy chicken fajita pizza', 1200, 'Pizza', 30, true),
    ('Pepperoni Pizza', 'Classic pepperoni', 1100, 'Pizza', 30, true),
    ('Gulab Jamun (2 pcs)', 'Soft sweet dessert', 120, 'Desserts', 5, true),
    ('Regular Fries', 'Crispy fries', 150, 'Fries', 5, true),
    ('Soft Drink', 'Coke / Sprite / Fanta', 100, 'Drinks', 3, true)
) AS v(name, description, price, category, points_reward, is_available)
WHERE NOT EXISTS (SELECT 1 FROM menu_items LIMIT 1);

INSERT INTO discount_config (points_to_pkr, max_discount_percent, min_points_to_redeem)
SELECT 1, 50, 10
WHERE NOT EXISTS (SELECT 1 FROM discount_config LIMIT 1);

INSERT INTO daily_missions (title, description, reward_points, reward_text, active_date)
SELECT 'Food Catcher Challenge', 'Catch 30 falling foods', 50, 'Free Gulab Jamun', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM daily_missions WHERE active_date = CURRENT_DATE);

INSERT INTO receipt_codes (code, points_value, is_used)
SELECT * FROM (VALUES ('WELCOME50', 50, false), ('FIGHT100', 100, false)) AS v(code, points_value, is_used)
WHERE NOT EXISTS (SELECT 1 FROM receipt_codes LIMIT 1);

-- 4. Disable RLS for development (optional)
ALTER TABLE menu_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE game_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE daily_missions DISABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE discount_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE treasure_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE treasure_redemptions DISABLE ROW LEVEL SECURITY;

-- First, back up existing orders if any, then recreate table with correct columns
CREATE TABLE IF NOT EXISTS orders_backup AS SELECT * FROM orders;

DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_name text,
    customer_phone text,
    customer_email text,
    customer_address text,
    items_ordered jsonb,
    total_price integer,
    original_price integer DEFAULT 0,
    discount_amount integer DEFAULT 0,
    points_used integer DEFAULT 0,
    status text DEFAULT 'Pending',
    created_at timestamptz DEFAULT now()
);

-- Re-insert any existing orders from backup
INSERT INTO orders (id, customer_name, customer_phone, customer_email, customer_address, items_ordered, total_price, status, created_at)
SELECT id, customer_name, customer_phone, customer_email, customer_address, items_ordered, total_price, status, created_at
FROM orders_backup
ON CONFLICT DO NOTHING;

-- Ensure discount_config exists and has correct values
CREATE TABLE IF NOT EXISTS discount_config (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    points_to_pkr integer DEFAULT 1,
    max_discount_percent integer DEFAULT 50,
    min_points_to_redeem integer DEFAULT 10
);
INSERT INTO discount_config (points_to_pkr, max_discount_percent, min_points_to_redeem)
VALUES (1, 50, 10)
ON CONFLICT (id) DO NOTHING;