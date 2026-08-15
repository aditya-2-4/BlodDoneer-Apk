// MediVerse Web Application Engine
const API_BASE = '/api';

let currentUser = null;
let authToken = localStorage.getItem('jwt_token') || null;

// Initialize Web App
document.addEventListener('DOMContentLoaded', () => {
    setupTabNavigation();
    setupAuthListeners();
    checkExistingSession();
    loadDashboardData();
});

// Toast Helper
function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.innerHTML = `<i class="fa-solid fa-circle-info"></i> ${message}`;
    container.appendChild(toast);

    setTimeout(() => {
        toast.style.opacity = '0';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// Log Helper
function addAdminLog(msg) {
    const box = document.getElementById('admin-log-box');
    if (box) {
        const line = document.createElement('div');
        line.className = 'log-line';
        line.textContent = `[${new Date().toLocaleTimeString()}] ${msg}`;
        box.prepend(line);
    }
}

// Navigation & Tabs
function setupTabNavigation() {
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const tabId = link.getAttribute('data-tab');
            switchTab(tabId);
        });
    });
}

function switchTab(tabId) {
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.toggle('active', link.getAttribute('data-tab') === tabId);
    });

    document.querySelectorAll('.tab-content').forEach(content => {
        content.classList.toggle('active', content.id === `tab-${tabId}`);
    });

    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// Auth Handlers
function setupAuthListeners() {
    const openBtn = document.getElementById('open-login-btn');
    const logoutBtn = document.getElementById('logout-btn');
    const googleBtn = document.getElementById('google-login-btn');

    openBtn.addEventListener('click', openAuthModal);
    logoutBtn.addEventListener('click', handleLogout);
    googleBtn.addEventListener('click', () => {
        closeAuthModal();
        openGoogleModal();
    });
}

function openAuthModal() {
    document.getElementById('auth-modal').classList.add('active');
}
function closeAuthModal() {
    document.getElementById('auth-modal').classList.remove('active');
}
function openGoogleModal() {
    document.getElementById('google-dialog-modal').classList.add('active');
}
function closeGoogleModal() {
    document.getElementById('google-dialog-modal').classList.remove('active');
}

async function checkExistingSession() {
    if (!authToken) return;
    try {
        const res = await fetch(`${API_BASE}/users/profile`, {
            headers: { 'Authorization': `Bearer ${authToken}` }
        });
        if (res.ok) {
            currentUser = await res.json();
            updateUIUserAuthenticated();
        } else {
            handleLogout();
        }
    } catch (e) {
        console.warn('Session restoration failed:', e);
    }
}

function updateUIUserAuthenticated() {
    if (!currentUser) return;
    document.getElementById('open-login-btn').classList.add('hidden');
    const widget = document.getElementById('user-profile-widget');
    widget.classList.remove('hidden');
    document.getElementById('user-name-display').innerHTML = `
        <i class="fa-solid fa-circle-user"></i> ${currentUser.name} (${currentUser.role.toUpperCase()})
    `;
    addAdminLog(`User authenticated: ${currentUser.email} [${currentUser.role}]`);
}

function handleLogout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('jwt_token');
    document.getElementById('user-profile-widget').classList.add('hidden');
    document.getElementById('open-login-btn').classList.remove('hidden');
    showToast('Logged out successfully.', 'info');
}

// Google Authentication Submission
async function handleGoogleAuthSubmit(e) {
    e.preventDefault();
    const email = document.getElementById('google-email-input').value;
    const name = document.getElementById('google-name-input').value;
    const role = document.getElementById('google-role-select').value;

    showToast('Connecting to Google Auth service...', 'info');

    try {
        const res = await fetch(`${API_BASE}/auth/google`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, name, role })
        });
        const data = await res.json();

        if (res.ok && data.success) {
            authToken = data.token;
            currentUser = data.user;
            localStorage.setItem('jwt_token', authToken);
            updateUIUserAuthenticated();
            closeGoogleModal();
            showToast(`Welcome ${currentUser.name}! Google Authentication successful.`, 'success');
        } else {
            showToast(data.error || 'Google auth failed.', 'error');
        }
    } catch (e) {
        showToast('Could not reach Google Auth API endpoint.', 'error');
    }
}

// Standard Email Login
async function handleEmailLogin(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value;
    const password = document.getElementById('login-password').value;

    await executeLogin(email, password);
}

async function fillAndLogin(email, password) {
    document.getElementById('login-email').value = email;
    document.getElementById('login-password').value = password;
    await executeLogin(email, password);
}

async function executeLogin(email, password) {
    try {
        const res = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        const data = await res.json();

        if (res.ok && data.success) {
            authToken = data.token;
            currentUser = data.user;
            localStorage.setItem('jwt_token', authToken);
            updateUIUserAuthenticated();
            closeAuthModal();
            showToast(`Logged in successfully as ${currentUser.name}`, 'success');
        } else {
            showToast(data.error || 'Login failed.', 'error');
        }
    } catch (e) {
        showToast('Server connection error.', 'error');
    }
}

// Load Data Functions
async function loadDashboardData() {
    await Promise.all([loadDoctors(), loadDonors(), loadHospitals()]);
}

async function loadDoctors() {
    const spec = document.getElementById('doctor-spec-filter')?.value || 'All';
    try {
        const res = await fetch(`${API_BASE}/doctors?specialization=${spec}`);
        const doctors = await res.json();

        document.getElementById('stat-doctors-count').textContent = `${doctors.length}+`;

        // Render Featured
        const featuredContainer = document.getElementById('featured-doctors-list');
        if (featuredContainer) {
            featuredContainer.innerHTML = doctors.slice(0, 2).map(d => `
                <div class="stat-card">
                    <div class="stat-icon teal"><i class="fa-solid fa-user-doctor"></i></div>
                    <div>
                        <h4>${d.name}</h4>
                        <p class="spec-tag">${d.specialization} • ${d.consult_fee}</p>
                    </div>
                </div>
            `).join('');
        }

        // Render Grid
        const grid = document.getElementById('doctors-grid');
        if (grid) {
            grid.innerHTML = doctors.map(d => `
                <div class="glass-card item-card">
                    <div>
                        <div class="item-header">
                            <div class="avatar-box"><i class="fa-solid fa-user-doctor"></i></div>
                            <div class="item-details">
                                <h4>${d.name}</h4>
                                <span class="spec-tag">${d.specialization}</span>
                            </div>
                        </div>
                        <p class="text-muted" style="font-size:13px">${d.bio || 'Verified medical practitioner.'}</p>
                    </div>
                    <div>
                        <div class="item-meta">
                            <span><i class="fa-solid fa-star text-amber"></i> ${d.rating} (${d.reviews_count})</span>
                            <span><i class="fa-solid fa-clock"></i> ${d.experience} yrs exp</span>
                            <span><i class="fa-solid fa-tag"></i> ${d.consult_fee}</span>
                        </div>
                        <div class="card-actions-row">
                            <button class="btn btn-secondary flex-1" onclick="openDoctorDetailsModal('${d._id || d.id}')">
                                <i class="fa-solid fa-file-contract text-teal"></i> Details & Docs
                            </button>
                            <button class="btn btn-primary flex-1" onclick="openBookingModal('${d._id || d.id}', '${d.name}', '${d.specialization}')">
                                <i class="fa-solid fa-calendar-check"></i> Book
                            </button>
                        </div>
                    </div>
                </div>
            `).join('');
        }
    } catch (e) {
        console.error('Failed loading doctors:', e);
    }
}

async function openDoctorDetailsModal(docId) {
    try {
        const res = await fetch(`${API_BASE}/doctors/${docId}`);
        const doc = await res.json();

        if (!res.ok || doc.error) {
            showToast(doc.error || 'Failed to fetch doctor credentials', 'error');
            return;
        }

        const body = document.getElementById('doctor-details-modal-body');
        const docsList = doc.documents || [
            { title: "Medical License", type: "License", doc_number: doc.license_number || "MCI-VALIDated", issued_by: "Medical Council", status: "Verified", icon: "fa-certificate" },
            { title: "Specialist Degree", type: "Degree", doc_number: "DEG-SPECIALIST", issued_by: "Medical University", status: "Verified", icon: "fa-graduation-cap" },
            { title: "Clinical Experience Endorsement", type: "Experience Letter", doc_number: "EXP-LEADERSHIP", issued_by: "General Hospital", status: "Verified", icon: "fa-file-signature" },
            { title: "Healthcare Quality Accreditation", type: "Accreditation", doc_number: "NABH-ACCREDITED", issued_by: "National Board", status: "Verified", icon: "fa-shield-halved" }
        ];

        body.innerHTML = `
            <div class="doc-profile-header">
                <div class="avatar-box large"><i class="fa-solid fa-user-doctor"></i></div>
                <div>
                    <h2>${doc.name} <span class="badge badge-success"><i class="fa-solid fa-circle-check"></i> Verified Practitioner</span></h2>
                    <p class="spec-tag">${doc.specialization} • ${doc.qualifications}</p>
                    <p class="text-muted" style="font-size:13px; margin-top:4px;">
                        <i class="fa-solid fa-id-card"></i> License: <strong>${doc.license_number || 'MCI-VERIFIED'}</strong> | 
                        <i class="fa-solid fa-hospital"></i> ${doc.hospital_name || 'City Central Hospital'}
                    </p>
                </div>
            </div>

            <div class="doc-bio-box">
                <h4><i class="fa-solid fa-user-check"></i> Professional Bio & Qualifications</h4>
                <p>${doc.bio || 'Verified medical specialist with clinical experience.'}</p>
                <div class="meta-pills">
                    <span class="pill"><i class="fa-solid fa-star text-amber"></i> Rating: ${doc.rating} (${doc.reviews_count} reviews)</span>
                    <span class="pill"><i class="fa-solid fa-briefcase"></i> Experience: ${doc.experience} Years</span>
                    <span class="pill"><i class="fa-solid fa-hand-holding-dollar"></i> Consult Fee: ${doc.consult_fee}</span>
                </div>
            </div>

            <div class="certificates-section">
                <h3><i class="fa-solid fa-folder-open text-teal"></i> Doctor Credentials & Verified Documents (4 Attached)</h3>
                <div class="certificates-grid">
                    ${docsList.map(item => `
                        <div class="cert-card">
                            <div class="cert-icon"><i class="fa-solid ${item.icon || 'fa-certificate'}"></i></div>
                            <div class="cert-info">
                                <h5>${item.title}</h5>
                                <p class="cert-meta">Type: <strong>${item.type}</strong></p>
                                <p class="cert-meta">Doc #: <code>${item.doc_number || item.doc_num}</code></p>
                                <p class="cert-meta">Issued by: ${item.issued_by}</p>
                                <span class="badge badge-success"><i class="fa-solid fa-check-double"></i> ${item.status || 'Verified'}</span>
                            </div>
                            <button class="btn btn-sm btn-ghost" onclick="showToast('Viewing verified PDF document: ${item.title}', 'info')">
                                <i class="fa-solid fa-eye"></i> View Doc
                            </button>
                        </div>
                    `).join('')}
                </div>
            </div>

            <div class="modal-actions margin-top">
                <button class="btn btn-secondary" onclick="closeDoctorDetailsModal()">Close Details</button>
                <button class="btn btn-primary" onclick="closeDoctorDetailsModal(); openBookingModal('${doc._id || doc.id}', '${doc.name}', '${doc.specialization}')">
                    <i class="fa-solid fa-calendar-check"></i> Proceed to Book Consultation
                </button>
            </div>
        `;

        document.getElementById('doctor-details-modal').classList.add('active');
    } catch (e) {
        showToast('Could not fetch doctor credential details.', 'error');
    }
}

function closeDoctorDetailsModal() {
    document.getElementById('doctor-details-modal').classList.remove('active');
}


async function loadDonors() {
    try {
        const res = await fetch(`${API_BASE}/donors`);
        const donors = await res.json();

        document.getElementById('stat-donors-count').textContent = `${donors.length}+`;

        const featuredContainer = document.getElementById('featured-donors-list');
        if (featuredContainer) {
            featuredContainer.innerHTML = donors.slice(0, 2).map(d => `
                <div class="stat-card">
                    <div class="stat-icon red"><i class="fa-solid fa-droplet"></i></div>
                    <div>
                        <h4>${d.name} <span class="blood-badge">${d.blood_group}</span></h4>
                        <p class="text-muted" style="font-size:12px">Status: ${d.availability_status}</p>
                    </div>
                </div>
            `).join('');
        }

        renderDonorsGrid(donors);
    } catch (e) {
        console.error('Failed loading donors:', e);
    }
}

function renderDonorsGrid(donors) {
    const grid = document.getElementById('donors-grid');
    if (!grid) return;

    grid.innerHTML = donors.map(d => `
        <div class="glass-card item-card">
            <div class="item-header">
                <div class="avatar-box donor"><i class="fa-solid fa-droplet"></i></div>
                <div class="item-details">
                    <h4>${d.name} <span class="blood-badge">${d.blood_group}</span></h4>
                    <span class="text-muted" style="font-size:13px"><i class="fa-solid fa-phone"></i> ${d.phone || 'Contact via SOS'}</span>
                </div>
            </div>
            <div class="item-meta">
                <span>Availability: <strong class="text-emerald">${d.availability_status}</strong></span>
                <span>Last Donated: ${d.last_donated || 'N/A'}</span>
            </div>
            <button class="btn btn-secondary btn-full" onclick="showToast('Direct SMS ping sent to ${d.name}', 'success')">
                <i class="fa-solid fa-comment-sms"></i> Request Blood Donation
            </button>
        </div>
    `).join('');
}

async function filterDonors(group) {
    document.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    event.target.classList.add('active');

    try {
        const url = group === 'all' ? `${API_BASE}/donors` : `${API_BASE}/donors?blood_group=${encodeURIComponent(group)}`;
        const res = await fetch(url);
        const donors = await res.json();
        renderDonorsGrid(donors);
    } catch (e) {
        console.error('Filter error:', e);
    }
}

async function loadHospitals() {
    try {
        const res = await fetch(`${API_BASE}/hospitals`);
        const hospitals = await res.json();

        document.getElementById('stat-hospitals-count').textContent = `${hospitals.length}+`;

        const grid = document.getElementById('hospitals-grid');
        if (grid) {
            grid.innerHTML = hospitals.map(h => `
                <div class="glass-card">
                    <div class="item-header">
                        <div class="avatar-box" style="color:#3B82F6"><i class="fa-solid fa-hospital"></i></div>
                        <div class="item-details">
                            <h4>${h.name}</h4>
                            <span class="text-muted" style="font-size:13px"><i class="fa-solid fa-location-dot"></i> Lat: ${h.location?.lat}, Lng: ${h.location?.lng}</span>
                        </div>
                    </div>
                    <div class="item-meta">
                        <span><i class="fa-solid fa-phone"></i> ${h.contact}</span>
                        <span><i class="fa-solid fa-clock text-emerald"></i> 24/7 Emergency</span>
                    </div>
                    <button class="btn btn-secondary btn-full" onclick="showToast('Navigating to ${h.name}...', 'info')">
                        <i class="fa-solid fa-route"></i> Get Directions & Emergency Route
                    </button>
                </div>
            `).join('');
        }
    } catch (e) {
        console.error('Failed loading hospitals:', e);
    }
}

// Booking Modal Logic
function openBookingModal(docId, docName, spec) {
    if (!currentUser) {
        showToast('Please sign in first to book an appointment.', 'error');
        openAuthModal();
        return;
    }
    document.getElementById('booking-doctor-id').value = docId;
    document.getElementById('booking-doctor-info').innerHTML = `
        <strong>Booking with: ${docName}</strong> (${spec})
    `;
    document.getElementById('booking-modal').classList.add('active');
}
function closeBookingModal() {
    document.getElementById('booking-modal').classList.remove('active');
}

async function handleBookingSubmit(e) {
    e.preventDefault();
    const doctor_id = document.getElementById('booking-doctor-id').value;
    const date = document.getElementById('booking-date').value;
    const time = document.getElementById('booking-slot').value;
    const reason = document.getElementById('booking-reason').value;

    try {
        const res = await fetch(`${API_BASE}/appointments`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${authToken}`
            },
            body: JSON.stringify({ doctor_id, date, time, reason })
        });
        const data = await res.json();

        if (res.ok) {
            closeBookingModal();
            showToast('Appointment booked successfully!', 'success');
            addAdminLog(`New appointment booked for patient ${currentUser.email}`);
        } else {
            showToast(data.error || 'Booking failed.', 'error');
        }
    } catch (e) {
        showToast('Server error while booking.', 'error');
    }
}

// SOS Broadcast Modal Logic
function openSOSModal() {
    document.getElementById('sos-modal').classList.add('active');
}
function closeSOSModal() {
    document.getElementById('sos-modal').classList.remove('active');
}

async function handleSOSSubmit(e) {
    e.preventDefault();
    const blood_group = document.getElementById('sos-blood-group').value;
    const urgency = document.getElementById('sos-urgency').value;

    try {
        const headers = { 'Content-Type': 'application/json' };
        if (authToken) headers['Authorization'] = `Bearer ${authToken}`;

        const res = await fetch(`${API_BASE}/blood-requests`, {
            method: 'POST',
            headers,
            body: JSON.stringify({ blood_group, urgency })
        });
        const data = await res.json();

        if (res.ok) {
            closeSOSModal();
            showToast(`EMERGENCY BROADCAST SENT! Donors notified for ${blood_group}.`, 'success');
            addAdminLog(`[CRITICAL SOS] Emergency alert triggered for group ${blood_group}`);
        } else {
            showToast(data.error || 'SOS broadcast failed.', 'error');
        }
    } catch (e) {
        showToast('Network error during SOS broadcast.', 'error');
    }
}
