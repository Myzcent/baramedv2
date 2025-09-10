let playerStats = null;
let difficulties = null;
let currentJob = null;
let isUIVisible = false;

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'openJobMenu':
            showUI();
            openJobMenu(data);
            break;
        case 'openRentMenu':
            showUI();
            openRentMenu(data);
            break;
        case 'hideUI':
            hideUI();
            break;
    }
});

// UI Visibility Functions
function showUI() {
    document.getElementById('app').style.display = 'flex';
    isUIVisible = true;
}

function hideUI() {
    document.getElementById('app').style.display = 'none';
    isUIVisible = false;
}

// Tab System
document.addEventListener('DOMContentLoaded', function() {
    // Tab switching
    document.querySelectorAll('.nav-tab').forEach(btn => {
        btn.addEventListener('click', function() {
            const tabName = this.dataset.tab;
            switchTab(tabName);
        });
    });
    
    // Initialize UI as hidden
    hideUI();
});

function switchTab(tabName) {
    // Update tab buttons
    document.querySelectorAll('.nav-tab').forEach(btn => {
        btn.classList.remove('active');
        if (btn.dataset.tab === tabName) {
            btn.classList.add('active');
        }
    });

    // Update tab content
    document.querySelectorAll('.content-panel').forEach(content => {
        content.classList.remove('active');
    });
    
    if (tabName === 'jobs') {
        document.getElementById('jobsContent').classList.add('active');
    } else if (tabName === 'rental') {
        document.getElementById('rentalContent').classList.add('active');
    }
}

// Open Job Menu
function openJobMenu(data) {
    playerStats = data.playerStats;
    difficulties = data.difficulties;
    currentJob = data.currentJob;

    // Switch to jobs tab by default
    switchTab('jobs');
    
    updatePlayerStats();
    populateJobList();
    updateActiveJobSection();
}

// Open Rental Menu
function openRentMenu(data) {
    difficulties = data.difficulties;
    
    // Switch to rental tab
    switchTab('rental');
    
    populateVehicleList();
}

// Update Player Stats
function updatePlayerStats() {
    if (!playerStats) return;

    // Basic info
    document.getElementById('playerName').textContent = playerStats.name || 'Driver';
    document.getElementById('playerLevel').textContent = playerStats.level || 1;
    document.getElementById('playerRep').textContent = playerStats.reputation || 0;
    document.getElementById('totalDeliveries').textContent = playerStats.total_deliveries || 0;
    document.getElementById('totalEarnings').textContent = `$${(playerStats.total_earnings || 0).toLocaleString()}`;

    // Experience bar
    const currentLevel = playerStats.level || 1;
    const currentExp = playerStats.experience || 0;
    const expForNextLevel = currentLevel * 100;
    const expProgress = Math.min(currentExp, expForNextLevel);
    const expPercentage = (expProgress / expForNextLevel) * 100;

    document.getElementById('expText').textContent = `EXP: ${expProgress} / ${expForNextLevel}`;
    document.getElementById('expFill').style.width = `${expPercentage}%`;

    // Tier badge
    updateTierBadge();
}

function updateTierBadge() {
    if (!playerStats) return;
    
    const rep = playerStats.reputation || 0;
    let tier = 'Rookie';
    let gradient = 'linear-gradient(135deg, #22c55e, #16a34a)';
    
    if (rep >= 3500) {
        tier = 'Elite';
        gradient = 'linear-gradient(135deg, #ef4444, #dc2626)';
    } else if (rep >= 1500) {
        tier = 'Pro';
        gradient = 'linear-gradient(135deg, #8b5cf6, #7c3aed)';
    } else if (rep >= 500) {
        tier = 'Skilled';
        gradient = 'linear-gradient(135deg, #3b82f6, #1d4ed8)';
    }
    
    const badge = document.getElementById('playerTier');
    badge.textContent = tier;
    badge.style.background = gradient;
}

// Populate Job List
function populateJobList() {
    const jobsList = document.getElementById('jobsList');
    jobsList.innerHTML = '';

    for (const [key, difficulty] of Object.entries(difficulties)) {
        const isUnlocked = playerStats.level >= difficulty.requiredLevel;
        const isActive = currentJob && currentJob.difficulty === key;

        const jobCard = document.createElement('div');
        jobCard.className = 'job-card';
        
        jobCard.innerHTML = `
            <div class="job-header">
                <div>
                    <div class="job-title">${difficulty.label}</div>
                    <div class="job-subtitle">
                        ${difficulty.type === 'trailer' ? '🚛 Trailer Delivery' : '📦 Box Delivery'}
                    </div>
                </div>
                <div class="level-badge">Level ${difficulty.requiredLevel}</div>
            </div>
            
            <div class="job-details">
                ${difficulty.type === 'box' 
                    ? `Deliver <strong>${difficulty.boxes} boxes</strong> using a ${difficulty.vehicle.toUpperCase()}` 
                    : `Transport heavy cargo with <strong>${difficulty.trailer}</strong> trailer`
                }
            </div>
            
            <div class="rewards-grid">
                <div class="reward-item">
                    <div class="reward-label">Payment</div>
                    <div class="reward-value">$${difficulty.rewards.money[0]}-${difficulty.rewards.money[1]}</div>
                </div>
                <div class="reward-item">
                    <div class="reward-label">Experience</div>
                    <div class="reward-value">${difficulty.rewards.exp} EXP</div>
                </div>
                <div class="reward-item">
                    <div class="reward-label">Vehicle</div>
                    <div class="reward-value">${difficulty.vehicle.toUpperCase()}</div>
                </div>
            </div>
            
            <button class="btn ${isActive ? 'btn-secondary' : isUnlocked ? 'btn-primary' : 'btn-secondary'}" 
                    onclick="${isActive ? '' : isUnlocked ? `startJob('${key}')` : ''}"
                    ${(!isUnlocked || isActive) ? 'disabled' : ''}>
                ${isActive ? '⏱️ Job Active' : isUnlocked ? '🚀 Start Job (FREE)' : '🔒 Level Required'}
            </button>
        `;

        jobsList.appendChild(jobCard);
    }
}

// Populate Vehicle List
function populateVehicleList() {
    const vehiclesList = document.getElementById('vehiclesList');
    vehiclesList.innerHTML = '';

    for (const [key, difficulty] of Object.entries(difficulties)) {
        const isUnlocked = playerStats && playerStats.level >= difficulty.requiredLevel;

        const vehicleCard = document.createElement('div');
        vehicleCard.className = 'vehicle-card';
        
        vehicleCard.innerHTML = `
            <div class="vehicle-header">
                <div>
                    <div class="vehicle-name">${difficulty.vehicle.toUpperCase()}</div>
                    <div class="vehicle-subtitle">
                        🚚 For ${difficulty.label}
                    </div>
                </div>
                <div class="price-badge">Dynamic Price</div>
            </div>
            
            <div class="vehicle-details">
                <strong>Vehicle Type:</strong> ${difficulty.type === 'trailer' ? 'Semi-Truck' : 'Box Truck'}<br>
                <strong>Required Level:</strong> ${difficulty.requiredLevel}<br>
                <strong>Purpose:</strong> ${difficulty.type === 'trailer' ? 'Heavy cargo transport' : 'Local deliveries'}
                ${difficulty.type === 'trailer' ? '<br><strong>Note:</strong> Trailer provided at pickup location' : ''}
            </div>
            
            <div class="rewards-grid">
                <div class="reward-item">
                    <div class="reward-label">Min Level</div>
                    <div class="reward-value">${difficulty.requiredLevel}</div>
                </div>
                <div class="reward-item">
                    <div class="reward-label">Job Type</div>
                    <div class="reward-value">${difficulty.type.toUpperCase()}</div>
                </div>
                <div class="reward-item">
                    <div class="reward-label">Capacity</div>
                    <div class="reward-value">${difficulty.type === 'box' ? difficulty.boxes + ' boxes' : 'Heavy'}</div>
                </div>
            </div>
            
            <button class="btn ${isUnlocked ? 'btn-rental' : 'btn-secondary'}" 
                    onclick="${isUnlocked ? `rentVehicle('${difficulty.vehicle}', '${key}')` : ''}"
                    ${!isUnlocked ? 'disabled' : ''}>
                ${isUnlocked ? '🔑 Rent Vehicle' : '🔒 Level Required'}
            </button>
        `;

        vehiclesList.appendChild(vehicleCard);
    }
}

// Update Active Job Section
function updateActiveJobSection() {
    const activeJobCard = document.getElementById('activeJobCard');
    const activeJobInfo = document.getElementById('activeJobInfo');

    if (currentJob && difficulties[currentJob.difficulty]) {
        const difficulty = difficulties[currentJob.difficulty];
        activeJobCard.style.display = 'block';
        
        activeJobInfo.innerHTML = `
            <div style="margin-bottom: 10px;">
                <strong>${difficulty.label}</strong>
            </div>
            <div style="font-size: 13px; color: #d1d5db; line-height: 1.4;">
                <div>🚛 Vehicle: ${currentJob.vehicle.toUpperCase()}</div>
                <div>📋 Type: ${difficulty.type === 'trailer' ? 'Trailer Delivery' : 'Box Delivery'}</div>
                ${currentJob.destination ? `<div>📍 Destination: ${currentJob.destination.name}</div>` : ''}
                <div style="margin-top: 8px; padding: 8px; background: rgba(245, 158, 11, 0.1); border-radius: 6px; border: 1px solid rgba(245, 158, 11, 0.3);">
                    <div style="color: #f59e0b; font-weight: 600;">🎯 Job In Progress</div>
                    <div style="font-size: 11px; color: #94a3b8;">Follow GPS to destination</div>
                </div>
            </div>
        `;
    } else {
        activeJobCard.style.display = 'none';
    }
}

// Job Actions
function startJob(difficulty) {
    if (!difficulty) return;
    
    fetch(`https://${GetParentResourceName()}/startJob`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ difficulty: difficulty })
    }).catch(() => {
        closeNUI();
    });
}

function cancelJob() {
    fetch(`https://${GetParentResourceName()}/cancelJob`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    }).catch(() => {
        closeNUI();
    });
}

function rentVehicle(vehicleType, difficulty) {
    if (!vehicleType || !difficulty) return;
    
    fetch(`https://${GetParentResourceName()}/rentVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ 
            vehicleType: vehicleType,
            difficulty: difficulty
        })
    }).catch(() => {
        closeNUI();
    });
}

// Close NUI
function closeNUI() {
    fetch(`https://${GetParentResourceName()}/closeNUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' }
    }).catch(() => {});
    hideUI();
}

// Keyboard Events
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && isUIVisible) {
        closeNUI();
        event.preventDefault();
        event.stopPropagation();
    }
});