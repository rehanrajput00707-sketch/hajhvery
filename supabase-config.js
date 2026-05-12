// supabase-config.js
// IMPORTANT: Replace with your actual Supabase project credentials

const SUPABASE_URL = 'https://jwtutwcwakgbgihjglqe.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_Nb1v4EUzFW5vm3BdmF_hQg_yKaPj0YV';

// Initialize Supabase client
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Make it available globally
window.supabase = supabase;

// Helper function to check if user is logged in
async function getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
}

// Helper function to get user points from transactions
async function getUserPoints(email) {
    if (!email) return 0;
    const { data, error } = await supabase
        .from('points_transactions')
        .select('points')
        .eq('user_email', email);
    if (error) return 0;
    return data.reduce((sum, t) => sum + t.points, 0);
}

// Helper to add points transaction
async function addPointsTransaction(email, points, reason) {
    const { error } = await supabase
        .from('points_transactions')
        .insert([{ user_email: email, points: points, reason: reason }]);
    if (error) console.error('Points transaction error:', error);
}