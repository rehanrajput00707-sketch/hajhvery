-- ============================================
-- COMPLETE DATABASE SETUP - CLEAN VERSION
-- FOR CLOTH SHOP (UNSTITCHED FABRICS)
-- Run this once in Supabase SQL Editor
-- ============================================

-- 1. Create tables (if not exist)
CREATE TABLE IF NOT EXISTS menu_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text NOT NULL,
    description text,
    price integer NOT NULL,
    category text DEFAULT 'Lawn',
    image_url text,
    is_available boolean DEFAULT true,
    on_sale boolean DEFAULT false,
    gsm text,
    created_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    order_number text UNIQUE,
    customer_name text NOT NULL,
    customer_phone text NOT NULL,
    customer_email text,
    customer_address text NOT NULL,
    customer_city text DEFAULT 'Arifwala',
    customer_zipcode text,
    items_ordered jsonb NOT NULL,
    total_price integer NOT NULL,
    original_price integer DEFAULT 0,
    discount_amount integer DEFAULT 0,
    delivery_charges integer DEFAULT 0,
    payment_method text DEFAULT 'Cash on Delivery',
    order_type text DEFAULT 'unstitched_fabric',
    status text DEFAULT 'Pending',
    notes text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
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

-- 2. Add missing columns to menu_items if not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='menu_items' AND column_name='on_sale') THEN
        ALTER TABLE menu_items ADD COLUMN on_sale boolean DEFAULT false;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='menu_items' AND column_name='gsm') THEN
        ALTER TABLE menu_items ADD COLUMN gsm text;
    END IF;
END $$;

-- 3. Create order_status_log table to track order history
CREATE TABLE IF NOT EXISTS order_status_log (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id uuid REFERENCES orders(id) ON DELETE CASCADE,
    old_status text,
    new_status text,
    changed_by text,
    notes text,
    created_at timestamptz DEFAULT now()
);

-- 4. Create function to update order number automatically
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TRIGGER AS $$
DECLARE
    next_number INTEGER;
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM '-([0-9]+)$') AS INTEGER)), 0) + 1
    INTO next_number
    FROM orders
    WHERE order_number LIKE 'CLOTH-%';
    
    NEW.order_number := 'CLOTH-' || TO_CHAR(NEXT_NUMBER, 'FM00000');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Create trigger for order number generation
DROP TRIGGER IF EXISTS trigger_generate_order_number ON orders;
CREATE TRIGGER trigger_generate_order_number
    BEFORE INSERT ON orders
    FOR EACH ROW
    WHEN (NEW.order_number IS NULL)
    EXECUTE FUNCTION generate_order_number();

-- 6. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Create trigger for updated_at
DROP TRIGGER IF EXISTS trigger_update_orders_updated_at ON orders;
CREATE TRIGGER trigger_update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 8. Insert sample fabric data (only if tables are empty)
INSERT INTO menu_items (name, description, price, category, image_url, is_available, on_sale, gsm)
SELECT * FROM (VALUES
    ('Premium Lawn Fabric', 'Pure Egyptian cotton lawn, breathable & soft, unstitched by meter.', 850, 'Lawn', 'https://placehold.co/600x400/1a2a1a/FFD700?text=LAWN+FABRIC', true, true, '120gsm'),
    ('Raw Silk Charmeuse', 'Luxurious raw silk with natural sheen, unstitched drape fabric.', 2450, 'Silk', 'https://placehold.co/600x400/2a1a1a/FFD700?text=SILK+FABRIC', true, false, '90gsm'),
    ('Soft Cotton Voile', 'Lightweight, airy cotton voile, ideal for daily wear kurtis.', 590, 'Cotton', 'https://placehold.co/600x400/1a2a2a/FFD700?text=COTTON+VOILE', true, true, '110gsm'),
    ('Linen Blend Earth Tone', 'Breathable linen-cotton blend, textured finish, unstitched fabric by meter.', 1290, 'Linen', 'https://placehold.co/600x400/2a2a1a/FFD700?text=LINEN+BLEND', true, false, '140gsm'),
    ('Digital Printed Chiffon', 'Flowing chiffon with floral digital print, perfect for dupattas.', 990, 'Chiffon', 'https://placehold.co/600x400/1a1a2a/FFD700?text=CHIFFON', true, false, '70gsm'),
    ('Velvet Crimson', 'Soft crushed velvet, luxurious drape, evening wear fabric.', 2190, 'Velvet', 'https://placehold.co/600x400/2a1a2a/FFD700?text=VELVET', true, true, '200gsm'),
    ('Organic Cotton Jersey', 'Stretchable organic cotton jersey, unstitched, ideal for casual tops.', 750, 'Cotton', 'https://placehold.co/600x400/1a2a2a/FFD700?text=JERSEY+COTTON', true, false, '150gsm'),
    ('Embroidered Lawn Festive', 'Delicate embroidery on premium lawn, unstitched 2.5m width.', 1850, 'Lawn', 'https://placehold.co/600x400/2a2a1a/FFD700?text=EMBROIDERED+LAWN', true, true, '125gsm')
) AS v(name, description, price, category, image_url, is_available, on_sale, gsm)
WHERE NOT EXISTS (SELECT 1 FROM menu_items LIMIT 1);

-- 9. Insert sample order (for testing)
INSERT INTO orders (customer_name, customer_phone, customer_email, customer_address, customer_city, items_ordered, total_price, status, order_type)
SELECT 'Test Customer', '03001234567', 'test@example.com', 'Main Bazar, Near Ghanta Ghar', 'Arifwala', 
       '[{"id":"fab_1","name":"Premium Lawn Fabric (Unstitched)","price_per_meter":850,"meters":3,"total_base":2550,"category":"Lawn","fabric_type":"unstitched"}]'::jsonb,
       2550, 'Pending', 'unstitched_fabric'
WHERE NOT EXISTS (SELECT 1 FROM orders LIMIT 1);

-- 10. Insert discount config
INSERT INTO discount_config (points_to_pkr, max_discount_percent, min_points_to_redeem)
SELECT 1, 50, 10
WHERE NOT EXISTS (SELECT 1 FROM discount_config LIMIT 1);

-- 11. Insert daily mission
INSERT INTO daily_missions (title, description, reward_points, reward_text, active_date)
SELECT 'Fabric Hunter', 'Explore our fabric collection', 50, 'Free Fabric Sample', CURRENT_DATE
WHERE NOT EXISTS (SELECT 1 FROM daily_missions WHERE active_date = CURRENT_DATE);

-- 12. Insert sample receipt codes
INSERT INTO receipt_codes (code, points_value, is_used)
SELECT * FROM (VALUES ('WELCOME50', 50, false), ('FABRIC100', 100, false)) AS v(code, points_value, is_used)
WHERE NOT EXISTS (SELECT 1 FROM receipt_codes LIMIT 1);

-- 13. Disable RLS for development (optional)
ALTER TABLE menu_items DISABLE ROW LEVEL SECURITY;
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE game_scores DISABLE ROW LEVEL SECURITY;
ALTER TABLE daily_missions DISABLE ROW LEVEL SECURITY;
ALTER TABLE receipt_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE discount_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_log DISABLE ROW LEVEL SECURITY;

-- 14. Create useful views for reporting

-- View for daily sales summary
CREATE OR REPLACE VIEW daily_sales_summary AS
SELECT 
    DATE(created_at) as sale_date,
    COUNT(*) as total_orders,
    SUM(total_price) as total_revenue,
    AVG(total_price) as average_order_value,
    SUM(delivery_charges) as total_delivery_charges
FROM orders
GROUP BY DATE(created_at)
ORDER BY sale_date DESC;

-- View for top selling fabrics
CREATE OR REPLACE VIEW top_selling_fabrics AS
SELECT 
    items_ordered->0->>'name' as fabric_name,
    items_ordered->0->>'category' as category,
    COUNT(*) as times_ordered,
    SUM((items_ordered->0->>'meters')::int) as total_meters_sold,
    SUM((items_ordered->0->>'total_base')::int) as total_revenue
FROM orders
WHERE items_ordered IS NOT NULL
GROUP BY fabric_name, category
ORDER BY total_meters_sold DESC
LIMIT 10;

-- View for order status count
CREATE OR REPLACE VIEW order_status_counts AS
SELECT 
    status,
    COUNT(*) as count,
    SUM(total_price) as total_amount
FROM orders
GROUP BY status
ORDER BY 
    CASE status 
        WHEN 'Pending' THEN 1
        WHEN 'Confirmed' THEN 2
        WHEN 'Shipped' THEN 3
        WHEN 'Delivered' THEN 4
        WHEN 'Cancelled' THEN 5
    END;

-- 15. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders(customer_phone);
CREATE INDEX IF NOT EXISTS idx_orders_customer_email ON orders(customer_email);
CREATE INDEX IF NOT EXISTS idx_menu_items_category ON menu_items(category);
CREATE INDEX IF NOT EXISTS idx_menu_items_on_sale ON menu_items(on_sale);

-- 16. Create function to get order details with items
CREATE OR REPLACE FUNCTION get_order_details(p_order_id uuid)
RETURNS TABLE(
    order_id uuid,
    order_number text,
    customer_name text,
    customer_phone text,
    customer_address text,
    customer_city text,
    total_price integer,
    status text,
    items jsonb,
    created_at timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id,
        o.order_number,
        o.customer_name,
        o.customer_phone,
        o.customer_address,
        o.customer_city,
        o.total_price,
        o.status,
        o.items_ordered,
        o.created_at
    FROM orders o
    WHERE o.id = p_order_id;
END;
$$ LANGUAGE plpgsql;

-- 17. Create function to update order status with log
CREATE OR REPLACE FUNCTION update_order_status(
    p_order_id uuid,
    p_new_status text,
    p_changed_by text DEFAULT 'admin'
)
RETURNS void AS $$
DECLARE
    v_old_status text;
BEGIN
    SELECT status INTO v_old_status FROM orders WHERE id = p_order_id;
    
    IF v_old_status IS DISTINCT FROM p_new_status THEN
        UPDATE orders SET status = p_new_status WHERE id = p_order_id;
        
        INSERT INTO order_status_log (order_id, old_status, new_status, changed_by)
        VALUES (p_order_id, v_old_status, p_new_status, p_changed_by);
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 18. Display success message
DO $$
BEGIN
    RAISE NOTICE '✅ Database setup completed successfully!';
    RAISE NOTICE '📊 Tables created: menu_items, orders, game_scores, daily_missions, receipt_codes, points_transactions, discount_config, order_status_log';
    RAISE NOTICE '🧵 Sample fabrics inserted: 8 items';
    RAISE NOTICE '📦 Sample order created for testing';
    RAISE NOTICE '🔧 Views created: daily_sales_summary, top_selling_fabrics, order_status_counts';
    RAISE NOTICE '⚡ Indexes added for performance optimization';
END $$;