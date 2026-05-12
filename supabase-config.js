// supabase-config.js
// Replace with your actual Supabase credentials
// Get them from: https://app.supabase.com/project/_/settings/api

const SUPABASE_URL = 'https://jwtutwcwakgbgihjglqe.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_Nb1v4EUzFW5vm3BdmF_hQg_yKaPj0YV';

// Initialize Supabase client (only once)
if (!window._supabaseClient) {
    window._supabaseClient = supabaseJs.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}
const supabase = window._supabaseClient;

// Simple helper to check if user is logged in
async function getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
}