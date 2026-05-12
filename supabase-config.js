// supabase-config.js
// IMPORTANT: Replace with your actual Supabase project credentials

const SUPABASE_URL = 'https://jwtutwcwakgbgihjglqe.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_Nb1v4EUzFW5vm3BdmF_hQg_yKaPj0YV';

// Create a single global supabase client (no redeclaration)
if (typeof window._supabaseClient === 'undefined') {
    window._supabaseClient = supabaseJs.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
}

// Use a different variable name to avoid conflicts with the library's global
const supabase = window._supabaseClient;

// Helper functions (keep them simple)
async function getCurrentUser() {
    const { data: { user } } = await supabase.auth.getUser();
    return user;
}