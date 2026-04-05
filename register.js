// register.js - Complete Registration & Authentication Handler
// This file handles all user registration, login, and session management

// Global variables
let currentUser = null;

// ============================================
// REGISTRATION FUNCTIONS
// ============================================

// Validate email format
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Validate phone number (Pakistan format)
function isValidPhone(phone) {
    const phoneRegex = /^03[0-9]{9}$/;
    return phoneRegex.test(phone);
}

// Show error message
function showError(elementId, message) {
    const errorDiv = document.getElementById(elementId);
    if (errorDiv) {
        errorDiv.innerHTML = message;
        errorDiv.style.display = 'block';
        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 5000);
    }
}

// Show success message
function showSuccess(elementId, message) {
    const successDiv = document.getElementById(elementId);
    if (successDiv) {
        successDiv.innerHTML = message;
        successDiv.style.display = 'block';
        setTimeout(() => {
            successDiv.style.display = 'none';
        }, 3000);
    }
}

// Register new user
async function registerUser(event) {
    if (event) event.preventDefault();
    
    // Get form values
    const fullName = document.getElementById('regFullName')?.value.trim();
    const phone = document.getElementById('regPhone')?.value.trim();
    const email = document.getElementById('regEmail')?.value.trim();
    const address = document.getElementById('regAddress')?.value.trim();
    const password = document.getElementById('regPassword')?.value;
    const confirmPassword = document.getElementById('regConfirmPassword')?.value;
    
    // Clear previous messages
    if (document.getElementById('registerError')) {
        document.getElementById('registerError').innerHTML = '';
    }
    if (document.getElementById('registerSuccess')) {
        document.getElementById('registerSuccess').innerHTML = '';
    }
    
    // Validation
    if (!fullName || !phone || !email || !address || !password) {
        showError('registerError', '❌ Please fill in all fields');
        return false;
    }
    
    if (!isValidEmail(email)) {
        showError('registerError', '❌ Please enter a valid email address');
        return false;
    }
    
    if (!isValidPhone(phone)) {
        showError('registerError', '❌ Please enter a valid phone number (03XXXXXXXXX)');
        return false;
    }
    
    if (password.length < 6) {
        showError('registerError', '❌ Password must be at least 6 characters long');
        return false;
    }
    
    if (password !== confirmPassword) {
        showError('registerError', '❌ Passwords do not match');
        return false;
    }
    
    // Show loading state
    const registerBtn = document.querySelector('#registerForm .btn-yellow');
    if (registerBtn) {
        registerBtn.disabled = true;
        registerBtn.textContent = 'Creating Account...';
    }
    
    try {
        // Register with Supabase
        const { data, error } = await supabase.auth.signUp({
            email: email,
            password: password,
            options: {
                data: {
                    full_name: fullName,
                    phone: phone,
                    address: address,
                    created_at: new Date().toISOString()
                }
            }
        });
        
        if (error) {
            showError('registerError', `❌ ${error.message}`);
            return false;
        }
        
        if (data.user) {
            showSuccess('registerSuccess', '✅ Account created successfully! Please login.');
            
            // Clear form
            if (document.getElementById('regFullName')) document.getElementById('regFullName').value = '';
            if (document.getElementById('regPhone')) document.getElementById('regPhone').value = '';
            if (document.getElementById('regEmail')) document.getElementById('regEmail').value = '';
            if (document.getElementById('regAddress')) document.getElementById('regAddress').value = '';
            if (document.getElementById('regPassword')) document.getElementById('regPassword').value = '';
            if (document.getElementById('regConfirmPassword')) document.getElementById('regConfirmPassword').value = '';
            
            // Switch to login tab after 2 seconds
            setTimeout(() => {
                if (typeof showLoginTab === 'function') {
                    showLoginTab();
                }
            }, 2000);
            
            return true;
        }
    } catch (error) {
        showError('registerError', '❌ Network error. Please check your connection and try again.');
        console.error('Registration error:', error);
        return false;
    } finally {
        if (registerBtn) {
            registerBtn.disabled = false;
            registerBtn.textContent = 'Create Account';
        }
    }
}

// ============================================
// LOGIN FUNCTIONS
// ============================================

// Login user
async function loginUser(event) {
    if (event) event.preventDefault();
    
    const email = document.getElementById('loginEmail')?.value.trim();
    const password = document.getElementById('loginPassword')?.value;
    
    // Clear previous messages
    if (document.getElementById('loginError')) {
        document.getElementById('loginError').innerHTML = '';
    }
    
    if (!email || !password) {
        showError('loginError', '❌ Please enter email and password');
        return false;
    }
    
    if (!isValidEmail(email)) {
        showError('loginError', '❌ Please enter a valid email address');
        return false;
    }
    
    // Show loading state
    const loginBtn = document.querySelector('#loginForm .btn-yellow');
    if (loginBtn) {
        loginBtn.disabled = true;
        loginBtn.textContent = 'Logging in...';
    }
    
    try {
        const { data, error } = await supabase.auth.signInWithPassword({
            email: email,
            password: password
        });
        
        if (error) {
            showError('loginError', `❌ ${error.message}`);
            return false;
        }
        
        if (data.user) {
            currentUser = data.user;
            showSuccess('loginError', '✅ Login successful! Redirecting...');
            
            // Load user dashboard
            await loadUserDashboard(currentUser);
            
            // Hide auth container, show dashboard
            if (document.getElementById('authContainer')) {
                document.getElementById('authContainer').style.display = 'none';
            }
            if (document.getElementById('dashboard')) {
                document.getElementById('dashboard').style.display = 'block';
            }
            
            return true;
        }
    } catch (error) {
        showError('loginError', '❌ Network error. Please try again.');
        console.error('Login error:', error);
        return false;
    } finally {
        if (loginBtn) {
            loginBtn.disabled = false;
            loginBtn.textContent = 'Login';
        }
    }
}

// ============================================
// USER DASHBOARD FUNCTIONS
// ============================================

// Load user points from database
async function loadUserPoints(email) {
    try {
        const { data, error } = await supabase
            .from('points_transactions')
            .select('points')
            .eq('user_email', email);
        
        if (error) {
            console.error('Error loading points:', error);
            return 0;
        }
        
        const total = data?.reduce((sum, t) => sum + (t.points || 0), 0) || 0;
        return total;
    } catch (error) {
        console.error('Points loading error:', error);
        return 0;
    }
}

// Load user orders
async function loadUserOrders(email) {
    try {
        const { data, error } = await supabase
            .from('orders')
            .select('*')
            .eq('customer_email', email)
            .order('created_at', { ascending: false })
            .limit(5);
        
        if (error) {
            console.error('Error loading orders:', error);
            return [];
        }
        
        return data || [];
    } catch (error) {
        console.error('Orders loading error:', error);
        return [];
    }
}

// Load user dashboard with all data
async function loadUserDashboard(user) {
    if (!user) return;
    
    const metadata = user.user_metadata || {};
    
    // Update profile info
    if (document.getElementById('userName')) {
        document.getElementById('userName').innerText = metadata.full_name || user.email;
    }
    if (document.getElementById('profileEmail')) {
        document.getElementById('profileEmail').innerText = user.email;
    }
    if (document.getElementById('profilePhone')) {
        document.getElementById('profilePhone').innerText = metadata.phone || 'Not provided';
    }
    if (document.getElementById('profileAddress')) {
        document.getElementById('profileAddress').innerText = metadata.address || 'Not provided';
    }
    
    // Load and display points
    const points = await loadUserPoints(user.email);
    if (document.getElementById('pointsTotal')) {
        document.getElementById('pointsTotal').innerText = points;
    }
    
    // Load and display orders
    const orders = await loadUserOrders(user.email);
    if (document.getElementById('ordersList')) {
        if (orders.length === 0) {
            document.getElementById('ordersList').innerHTML = '<p style="color:#aaa;">No orders yet. Visit our menu!</p>';
        } else {
            document.getElementById('ordersList').innerHTML = orders.map(order => `
                <div style="background: #1a1a1a; padding: 0.8rem; border-radius: 12px; margin-bottom: 0.8rem;">
                    <div style="display: flex; justify-content: space-between;">
                        <span>Order #${order.id.slice(0,8)}</span>
                        <span style="color:#FFD700;">PKR ${order.total_price}</span>
                    </div>
                    <div style="font-size: 0.8rem; color:#aaa;">${new Date(order.created_at).toLocaleDateString()}</div>
                    <div>Status: <span style="color:#FFD700;">${order.status || 'Pending'}</span></div>
                </div>
            `).join('');
        }
    }
}

// ============================================
// LOGOUT FUNCTION
// ============================================

async function logoutUser() {
    try {
        const { error } = await supabase.auth.signOut();
        if (error) {
            console.error('Logout error:', error);
            return false;
        }
        
        currentUser = null;
        
        // Show auth container, hide dashboard
        if (document.getElementById('authContainer')) {
            document.getElementById('authContainer').style.display = 'block';
        }
        if (document.getElementById('dashboard')) {
            document.getElementById('dashboard').style.display = 'none';
        }
        
        // Clear form fields
        if (document.getElementById('loginEmail')) {
            document.getElementById('loginEmail').value = '';
        }
        if (document.getElementById('loginPassword')) {
            document.getElementById('loginPassword').value = '';
        }
        
        return true;
    } catch (error) {
        console.error('Logout error:', error);
        return false;
    }
}

// ============================================
// SESSION CHECK
// ============================================

async function checkUserSession() {
    try {
        const { data: { user }, error } = await supabase.auth.getUser();
        
        if (error) {
            console.error('Session check error:', error);
            return null;
        }
        
        if (user) {
            currentUser = user;
            
            // Hide auth container, show dashboard
            if (document.getElementById('authContainer')) {
                document.getElementById('authContainer').style.display = 'none';
            }
            if (document.getElementById('dashboard')) {
                document.getElementById('dashboard').style.display = 'block';
            }
            
            await loadUserDashboard(user);
            return user;
        } else {
            // Show auth container, hide dashboard
            if (document.getElementById('authContainer')) {
                document.getElementById('authContainer').style.display = 'block';
            }
            if (document.getElementById('dashboard')) {
                document.getElementById('dashboard').style.display = 'none';
            }
            return null;
        }
    } catch (error) {
        console.error('Session check error:', error);
        return null;
    }
}

// ============================================
// UI TOGGLE FUNCTIONS
// ============================================

function showLoginTab() {
    const loginForm = document.getElementById('loginForm');
    const registerForm = document.getElementById('registerForm');
    const loginTab = document.getElementById('loginTab');
    const registerTab = document.getElementById('registerTab');
    
    if (loginForm) loginForm.style.display = 'block';
    if (registerForm) registerForm.style.display = 'none';
    if (loginTab) loginTab.classList.add('active');
    if (registerTab) registerTab.classList.remove('active');
}

function showRegisterTab() {
    const loginForm = document.getElementById('loginForm');
    const registerForm = document.getElementById('registerForm');
    const loginTab = document.getElementById('loginTab');
    const registerTab = document.getElementById('registerTab');
    
    if (loginForm) loginForm.style.display = 'none';
    if (registerForm) registerForm.style.display = 'block';
    if (registerTab) registerTab.classList.add('active');
    if (loginTab) loginTab.classList.remove('active');
}

// ============================================
// EXPORT FUNCTIONS FOR GLOBAL USE
// ============================================

// Make functions available globally
window.registerUser = registerUser;
window.loginUser = loginUser;
window.logoutUser = logoutUser;
window.checkUserSession = checkUserSession;
window.showLoginTab = showLoginTab;
window.showRegisterTab = showRegisterTab;
window.loadUserDashboard = loadUserDashboard;

// Auto-initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    checkUserSession();
});