// ============================================
// SUPABASE CONFIGURATION - CLOTH SHOP
// ============================================

// TODO: Replace with your actual Supabase project credentials
// You can find these in: Supabase Dashboard > Project Settings > API
const SUPABASE_URL = 'https://bvqkqrqjpxugsbjonpua.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_gT7WdtUeBfF9IzUClVmHUg_NTK80KGD';

// Initialize Supabase client (MUST be before using it)
const supabaseClient = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY,
    {
        auth: {
            autoRefreshToken: true,
            persistSession: true,
            detectSessionInUrl: true
        }
    }
);

// Make supabase available globally
window.supabase = supabaseClient;

// ============================================
// AUTHENTICATION FUNCTIONS
// ============================================

// Get current authenticated user
async function getCurrentUser() {
    try {
        const { data: { user }, error } = await window.supabase.auth.getUser();
        if (error) throw error;
        return user;
    } catch (err) {
        console.error('Error getting user:', err.message);
        return null;
    }
}

// Get current session
async function getCurrentSession() {
    try {
        const { data: { session }, error } = await window.supabase.auth.getSession();
        if (error) throw error;
        return session;
    } catch (err) {
        console.error('Error getting session:', err.message);
        return null;
    }
}

// Check if user is logged in
async function isUserLoggedIn() {
    const user = await getCurrentUser();
    return user !== null;
}

// Sign up new user
async function signUp(email, password, fullName, phone, address) {
    try {
        const { data, error } = await window.supabase.auth.signUp({
            email: email,
            password: password,
            options: {
                data: {
                    full_name: fullName,
                    phone: phone,
                    address: address
                }
            }
        });
        if (error) throw error;
        return { success: true, user: data.user };
    } catch (error) {
        console.error('Sign up error:', error.message);
        return { success: false, error: error.message };
    }
}

// Sign in user
async function signIn(email, password) {
    try {
        const { data, error } = await window.supabase.auth.signInWithPassword({
            email: email,
            password: password
        });
        if (error) throw error;
        return { success: true, user: data.user };
    } catch (error) {
        console.error('Sign in error:', error.message);
        return { success: false, error: error.message };
    }
}

// Sign out user
async function signOut() {
    try {
        const { error } = await window.supabase.auth.signOut();
        if (error) throw error;
        return { success: true };
    } catch (error) {
        console.error('Sign out error:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// FABRIC (MENU ITEMS) FUNCTIONS
// ============================================

// Get all fabrics
async function getAllFabrics() {
    try {
        const { data, error } = await window.supabase
            .from('menu_items')
            .select('*')
            .eq('is_available', true)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return { success: true, data: data };
    } catch (error) {
        console.error('Error fetching fabrics:', error.message);
        return { success: false, error: error.message, data: [] };
    }
}

// Get fabrics by category
async function getFabricsByCategory(category) {
    try {
        const { data, error } = await window.supabase
            .from('menu_items')
            .select('*')
            .eq('category', category)
            .eq('is_available', true);
        
        if (error) throw error;
        return { success: true, data: data };
    } catch (error) {
        console.error('Error fetching fabrics by category:', error.message);
        return { success: false, error: error.message, data: [] };
    }
}

// Get fabrics on sale
async function getFabricsOnSale() {
    try {
        const { data, error } = await window.supabase
            .from('menu_items')
            .select('*')
            .eq('on_sale', true)
            .eq('is_available', true);
        
        if (error) throw error;
        return { success: true, data: data };
    } catch (error) {
        console.error('Error fetching sale fabrics:', error.message);
        return { success: false, error: error.message, data: [] };
    }
}

// Get single fabric by ID
async function getFabricById(id) {
    try {
        const { data, error } = await window.supabase
            .from('menu_items')
            .select('*')
            .eq('id', id)
            .single();
        
        if (error) throw error;
        return { success: true, data: data };
    } catch (error) {
        console.error('Error fetching fabric:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// ORDER FUNCTIONS
// ============================================

// Place a new order
async function placeOrder(orderData) {
    try {
        const { data, error } = await window.supabase
            .from('orders')
            .insert([orderData])
            .select();
        
        if (error) throw error;
        return { success: true, data: data[0] };
    } catch (error) {
        console.error('Error placing order:', error.message);
        return { success: false, error: error.message };
    }
}

// Get user orders
async function getUserOrders(email) {
    try {
        const { data, error } = await window.supabase
            .from('orders')
            .select('*')
            .eq('customer_email', email)
            .order('created_at', { ascending: false });
        
        if (error) throw error;
        return { success: true, data: data };
    } catch (error) {
        console.error('Error fetching user orders:', error.message);
        return { success: false, error: error.message, data: [] };
    }
}

// Get order by ID
async function getOrderById(orderId) {
    try {
        const { data, error } = await window.supabase
            .from('orders')
            .select('*')
            .eq('id', orderId)
            .single();
        
        if (error) throw error;
        return { success: true, data: data };
    } catch (error) {
        console.error('Error fetching order:', error.message);
        return { success: false, error: error.message };
    }
}

// Update order status (admin)
async function updateOrderStatus(orderId, status) {
    try {
        const { data, error } = await window.supabase
            .from('orders')
            .update({ status: status, updated_at: new Date() })
            .eq('id', orderId)
            .select();
        
        if (error) throw error;
        return { success: true, data: data[0] };
    } catch (error) {
        console.error('Error updating order:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// DISCOUNT CONFIGURATION FUNCTIONS
// ============================================

// Get discount configuration
async function getDiscountConfig() {
    try {
        const { data, error } = await window.supabase
            .from('discount_config')
            .select('*')
            .single();
        
        if (error && error.code !== 'PGRST116') throw error;
        return { success: true, data: data || { points_to_pkr: 1, max_discount_percent: 50, min_points_to_redeem: 10 } };
    } catch (error) {
        console.error('Error fetching discount config:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// RECEIPT CODES FUNCTIONS
// ============================================

// Redeem receipt code
async function redeemReceiptCode(code, userEmail) {
    try {
        // First check if code exists and is not used
        const { data: codeData, error: codeError } = await window.supabase
            .from('receipt_codes')
            .select('*')
            .eq('code', code.toUpperCase())
            .eq('is_used', false)
            .single();
        
        if (codeError || !codeData) {
            return { success: false, error: 'Invalid or already used code' };
        }
        
        // Mark code as used
        const { error: updateError } = await window.supabase
            .from('receipt_codes')
            .update({ 
                is_used: true, 
                used_by_email: userEmail,
                used_at: new Date()
            })
            .eq('id', codeData.id);
        
        if (updateError) throw updateError;
        
        // Add points to user
        const { error: pointsError } = await window.supabase
            .from('points_transactions')
            .insert([{
                user_email: userEmail,
                points: codeData.points_value,
                reason: `Redeemed code: ${code}`
            }]);
        
        if (pointsError) throw pointsError;
        
        return { success: true, points: codeData.points_value };
    } catch (error) {
        console.error('Error redeeming code:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// POINTS FUNCTIONS
// ============================================

// Get user points
async function getUserPoints(email) {
    try {
        const { data, error } = await window.supabase
            .from('points_transactions')
            .select('points')
            .eq('user_email', email);
        
        if (error) throw error;
        
        const totalPoints = data?.reduce((sum, t) => sum + (t.points || 0), 0) || 0;
        return { success: true, points: totalPoints };
    } catch (error) {
        console.error('Error fetching user points:', error.message);
        return { success: false, error: error.message, points: 0 };
    }
}

// Add points to user
async function addUserPoints(email, points, reason) {
    try {
        const { error } = await window.supabase
            .from('points_transactions')
            .insert([{
                user_email: email,
                points: points,
                reason: reason
            }]);
        
        if (error) throw error;
        return { success: true };
    } catch (error) {
        console.error('Error adding points:', error.message);
        return { success: false, error: error.message };
    }
}

// ============================================
// EXPORT FUNCTIONS (make available globally)
// ============================================

// Make all functions available globally
window.getCurrentUser = getCurrentUser;
window.getCurrentSession = getCurrentSession;
window.isUserLoggedIn = isUserLoggedIn;
window.signUp = signUp;
window.signIn = signIn;
window.signOut = signOut;
window.getAllFabrics = getAllFabrics;
window.getFabricsByCategory = getFabricsByCategory;
window.getFabricsOnSale = getFabricsOnSale;
window.getFabricById = getFabricById;
window.placeOrder = placeOrder;
window.getUserOrders = getUserOrders;
window.getOrderById = getOrderById;
window.updateOrderStatus = updateOrderStatus;
window.getDiscountConfig = getDiscountConfig;
window.redeemReceiptCode = redeemReceiptCode;
window.getUserPoints = getUserPoints;
window.addUserPoints = addUserPoints;

console.log('✅ Supabase client initialized successfully');
console.log('🔗 Connected to:', SUPABASE_URL);