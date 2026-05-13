const SUPABASE_URL = 'https://jwtutwcwakgbgihjglqe.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';

const client = supabase.createClient(
    SUPABASE_URL,
    SUPABASE_ANON_KEY
);

async function getCurrentUser() {
    const { data: { user } } = await client.auth.getUser();
    return user;
}