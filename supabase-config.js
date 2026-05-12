// supabase-config.js
// IMPORTANT: Replace these with your actual Supabase project credentials
// Get them from: https://app.supabase.com/project/_/settings/api
https
const SUPABASE_URL = 'https://jwtutwcwakgbgihjglqe.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_Nb1v4EUzFW5vm3BdmF_hQg_yKaPj0YV';

// Initialize Supabase client
const { createClient } = window.supabase;
window.supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Helper function to check if user is logged in
async function getCurrentUser() {
    const { data: { user } } = await window.supabase.auth.getUser();
    return user;
}

// Helper function to get user points from transactions
async function getUserPoints(email) {
    if (!email) return 0;
    const { data, error } = await window.supabase
        .from('points_transactions')
        .select('points')
        .eq('user_email', email);
    if (error) return 0;
    return data.reduce((sum, t) => sum + t.points, 0);
}

// Helper to add points transaction
async function addPointsTransaction(email, points, reason) {
    const { error } = await window.supabase
        .from('points_transactions')
        .insert([{ user_email: email, points: points, reason: reason }]);
    if (error) console.error('Points transaction error:', error);
}