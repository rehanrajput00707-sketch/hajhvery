-- ============================================
-- FIX ALL PERMISSIONS FOR HAJIARI RESTAURANT
-- Run this entire script in Supabase SQL Editor
-- ============================================

-- 1. Disable RLS temporarily on all tables (for development)
ALTER TABLE menu_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE game_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE daily_missions DISABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions DISABLE ROW LEVEL SECURITY;

-- 2. Create tables if they don't exist
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

-- 3. Insert sample menu items (including Pizza and Gulab Jamun)
INSERT INTO menu_items (name, description, price, category, points_reward, is_available) VALUES
('Chicken Zinger Burger', 'Crispy fried chicken with spicy mayo, lettuce, and cheese', 450, 'Burgers', 15, true),
('Beef Burger', 'Juicy beef patty with caramelized onions, cheese, and special sauce', 500, 'Burgers', 15, true),
('Chicken Fajita Pizza', 'Spicy chicken fajita, bell peppers, onions, and mozzarella', 1200, 'Pizza', 30, true),
('Pepperoni Pizza', 'Classic pepperoni, mozzarella, and tomato sauce', 1100, 'Pizza', 30, true),
('Gulab Jamun (2 pcs)', 'Soft, golden brown milk solids soaked in sugar syrup', 120, 'Desserts', 5, true),
('Gulab Jamun (4 pcs)', 'Soft, golden brown milk solids soaked in sugar syrup', 220, 'Desserts', 10, true),
('Family Deal', '2 Burgers + 2 Fries + 2 Drinks', 1200, 'Deals', 40, true),
('Regular Fries', 'Crispy golden fries with secret seasoning', 150, 'Fries', 5, true),
('Soft Drink', 'Coke, Sprite, or Fanta', 100, 'Drinks', 3, true)
ON CONFLICT DO NOTHING;

-- 4. Insert sample daily mission
INSERT INTO daily_missions (title, description, reward_points, reward_text, active_date) 
VALUES ('Food Catcher Challenge', 'Catch 30 falling food items in the game', 50, 'Free Gulab Jamun', CURRENT_DATE)
ON CONFLICT (active_date) DO UPDATE SET 
    title = EXCLUDED.title,
    description = EXCLUDED.description,
    reward_points = EXCLUDED.reward_points,
    reward_text = EXCLUDED.reward_text;

-- 5. Insert sample receipt codes
INSERT INTO receipt_codes (code, points_value, is_used) VALUES
('HJWELCOME', 50, false),
('HAJIARI10', 100, false),
('FIRSTORDER', 75, false)
ON CONFLICT (code) DO NOTHING;

-- Discount configuration table for admin control
CREATE TABLE IF NOT EXISTS discount_config (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    points_to_pkr integer DEFAULT 1,
    max_discount_percent integer DEFAULT 50,
    min_points_to_redeem integer DEFAULT 10,
    updated_at timestamptz DEFAULT now()
);

-- Insert default configuration
INSERT INTO discount_config (points_to_pkr, max_discount_percent, min_points_to_redeem)
VALUES (1, 50, 10)
ON CONFLICT DO NOTHING;

-- Discount configuration table
CREATE TABLE IF NOT EXISTS discount_config (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    points_to_pkr integer DEFAULT 1,
    max_discount_percent integer DEFAULT 50,
    min_points_to_redeem integer DEFAULT 10,
    updated_at timestamptz DEFAULT now()
);

-- Insert default config
INSERT INTO discount_config (points_to_pkr, max_discount_percent, min_points_to_redeem)
VALUES (1, 50, 10)
ON CONFLICT DO NOTHING;

-- Update orders table to store discount info
ALTER TABLE orders ADD COLUMN IF NOT EXISTS original_price integer;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount integer DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS points_used integer DEFAULT 0;

-- Treasure codes table (physical codes hidden in restaurant)
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

-- Track who redeemed codes (winners)
CREATE TABLE IF NOT EXISTS treasure_redemptions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    code text NOT NULL,
    user_email text NOT NULL,
    user_name text,
    points_earned integer,
    redeemed_date date,
    redeemed_at timestamptz DEFAULT now()
);

-- Also ensure receipt_codes table has these columns
ALTER TABLE receipt_codes ADD COLUMN IF NOT EXISTS used_by_email text;

-- Generate random treasure codes
INSERT INTO treasure_codes (code, title, points_value, reward_description)
VALUES 
('RANDOM' || floor(random()*10000), 'Weekend Special', 80, 'Free Upgrade'),
('HUNT' || floor(random()*9999), 'Late Night Deal', 120, '20% Off Next Order');

ALTER TABLE orders ADD COLUMN IF NOT EXISTS original_price integer;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_amount integer DEFAULT 0;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS points_used integer DEFAULT 0;

-- Make sure orders table has all required columns
CREATE TABLE IF NOT EXISTS orders (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    customer_name text,
    customer_phone text,
    customer_email text,
    customer_address text,
    items_ordered jsonb,
    total_price integer,
    original_price integer,
    discount_amount integer DEFAULT 0,
    points_used integer DEFAULT 0,
    status text DEFAULT 'Pending',
    created_at timestamptz DEFAULT now()
);