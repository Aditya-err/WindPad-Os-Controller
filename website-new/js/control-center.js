/* ============================================
   WINDPAD WEBSITE - CONTROL CENTER PAGE JAVASCRIPT
   Interactive phone interface functionality
   ============================================ */

// Control Center Interface
class ControlCenter {
    constructor() {
        this.tabButtons = document.querySelectorAll('.tab-btn');
        this.tabPanels = document.querySelectorAll('.tab-panel');
        this.touchpadSurface = document.getElementById('touchpadSurface');
        this.touchpadCursor = document.getElementById('touchpadCursor');
        this.demoCursor = document.getElementById('demoCursor');
        this.demoFeedback = document.getElementById('demoFeedback');
        this.keyboardDisplay = document.getElementById('keyboardDisplay');
        this.playBtn = document.getElementById('playBtn');
        this.mediaProgress = document.getElementById('mediaProgress');
        this.volumeSlider = document.getElementById('volumeSlider');
        
        this.currentText = '';
        this.isPlaying = true;
        this.currentVolume = 70;
        
        this.init();
    }
    
    init() {
        this.initTabs();
        this.initTouchpad();
        this.initKeyboard();
        this.initShortcuts();
        this.initMedia();
        this.initSystem();
        this.initCustom();
    }
    
    initTabs() {
        this.tabButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                const tabId = btn.getAttribute('data-tab');
                this.switchTab(tabId);
            });
        });
    }
    
    switchTab(tabId) {
        this.tabButtons.forEach(btn => {
            if (btn.getAttribute('data-tab') === tabId) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });
        
        this.tabPanels.forEach(panel => {
            if (panel.id === tabId) {
                panel.classList.add('active');
            } else {
                panel.classList.remove('active');
            }
        });
    }
    
    initTouchpad() {
        if (!this.touchpadSurface || !this.touchpadCursor) return;
        
        let isDragging = false;
        let startX, startY;
        
        this.touchpadSurface.addEventListener('mousedown', (e) => {
            isDragging = true;
            startX = e.clientX;
            startY = e.clientY;
        });
        
        this.touchpadSurface.addEventListener('mousemove', (e) => {
            if (!isDragging) return;
            
            const rect = this.touchpadSurface.getBoundingClientRect();
            const x = ((e.clientX - rect.left) / rect.width) * 100;
            const y = ((e.clientY - rect.top) / rect.height) * 100;
            
            this.touchpadCursor.style.left = x + '%';
            this.touchpadCursor.style.top = y + '%';
            
            // Sync with demo cursor
            if (this.demoCursor) {
                this.demoCursor.style.left = x + '%';
                this.demoCursor.style.top = y + '%';
            }
        });
        
        this.touchpadSurface.addEventListener('mouseup', () => {
            isDragging = false;
        });
        
        this.touchpadSurface.addEventListener('mouseleave', () => {
            isDragging = false;
        });
        
        // Touch support
        this.touchpadSurface.addEventListener('touchstart', (e) => {
            isDragging = true;
            startX = e.touches[0].clientX;
            startY = e.touches[0].clientY;
        });
        
        this.touchpadSurface.addEventListener('touchmove', (e) => {
            if (!isDragging) return;
            e.preventDefault();
            
            const rect = this.touchpadSurface.getBoundingClientRect();
            const x = ((e.touches[0].clientX - rect.left) / rect.width) * 100;
            const y = ((e.touches[0].clientY - rect.top) / rect.height) * 100;
            
            this.touchpadCursor.style.left = x + '%';
            this.touchpadCursor.style.top = y + '%';
            
            if (this.demoCursor) {
                this.demoCursor.style.left = x + '%';
                this.demoCursor.style.top = y + '%';
            }
        });
        
        this.touchpadSurface.addEventListener('touchend', () => {
            isDragging = false;
        });
        
        // Click buttons
        const leftClick = document.getElementById('leftClick');
        const rightClick = document.getElementById('rightClick');
        
        if (leftClick) {
            leftClick.addEventListener('click', () => {
                this.showFeedback('Left Click');
            });
        }
        
        if (rightClick) {
            rightClick.addEventListener('click', () => {
                this.showFeedback('Right Click');
            });
        }
    }
    
    initKeyboard() {
        const keys = document.querySelectorAll('.key');
        
        keys.forEach(key => {
            key.addEventListener('click', () => {
                const keyValue = key.getAttribute('data-key');
                
                if (keyValue === 'shift') {
                    this.showFeedback('Shift');
                } else if (keyValue === ' ') {
                    this.currentText += ' ';
                } else {
                    this.currentText += keyValue;
                }
                
                this.updateKeyboardDisplay();
                this.showFeedback('Key: ' + keyValue.toUpperCase());
                
                // Visual feedback
                key.style.transform = 'scale(0.95)';
                key.style.background = 'var(--accent-primary)';
                key.style.color = 'white';
                
                setTimeout(() => {
                    key.style.transform = '';
                    key.style.background = '';
                    key.style.color = '';
                }, 100);
            });
        });
    }
    
    updateKeyboardDisplay() {
        if (!this.keyboardDisplay) return;
        
        if (this.currentText) {
            this.keyboardDisplay.textContent = this.currentText;
            this.keyboardDisplay.style.color = 'var(--text-primary)';
        } else {
            this.keyboardDisplay.innerHTML = '<span class="placeholder-text">Start typing...</span>';
        }
    }
    
    initShortcuts() {
        const shortcutBtns = document.querySelectorAll('.shortcut-btn');
        
        shortcutBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.getAttribute('data-action');
                const actionName = btn.querySelector('.shortcut-name').textContent;
                this.showFeedback(actionName);
            });
        });
    }
    
    initMedia() {
        if (!this.playBtn || !this.mediaProgress) return;
        
        this.playBtn.addEventListener('click', () => {
            this.isPlaying = !this.isPlaying;
            
            if (this.isPlaying) {
                this.mediaProgress.style.animationPlayState = 'running';
                this.playBtn.innerHTML = `
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="5 3 19 12 5 21 5 3"/>
                    </svg>
                `;
                this.showFeedback('Play');
            } else {
                this.mediaProgress.style.animationPlayState = 'paused';
                this.playBtn.innerHTML = `
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <rect x="6" y="4" width="4" height="16"/>
                        <rect x="14" y="4" width="4" height="16"/>
                    </svg>
                `;
                this.showFeedback('Pause');
            }
        });
        
        // Volume slider
        if (this.volumeSlider) {
            this.volumeSlider.addEventListener('input', (e) => {
                this.currentVolume = e.target.value;
                this.showFeedback('Volume: ' + this.currentVolume + '%');
            });
        }
        
        // Other media buttons
        const mediaBtns = document.querySelectorAll('.media-btn[data-action]');
        mediaBtns.forEach(btn => {
            if (btn !== this.playBtn) {
                btn.addEventListener('click', () => {
                    const action = btn.getAttribute('data-action');
                    this.showFeedback(action.charAt(0).toUpperCase() + action.slice(1));
                });
            }
        });
    }
    
    initSystem() {
        const systemBtns = document.querySelectorAll('.system-btn');
        
        systemBtns.forEach(btn => {
            btn.addEventListener('click', () => {
                const action = btn.getAttribute('data-action');
                const actionName = btn.querySelector('span').textContent;
                this.showFeedback(actionName);
            });
        });
    }
    
    initCustom() {
        const customActions = document.querySelectorAll('.custom-action');
        const customAdd = document.querySelector('.custom-add');
        
        customActions.forEach(btn => {
            btn.addEventListener('click', () => {
                const customItem = btn.closest('.custom-item');
                const actionName = customItem.querySelector('.custom-name').textContent;
                this.showFeedback('Executing: ' + actionName);
            });
        });
        
        if (customAdd) {
            customAdd.addEventListener('click', () => {
                this.showFeedback('Add Custom Action');
            });
        }
    }
    
    showFeedback(message) {
        if (!this.demoFeedback) return;
        
        this.demoFeedback.textContent = message;
        this.demoFeedback.classList.add('visible');
        
        setTimeout(() => {
            this.demoFeedback.classList.remove('visible');
        }, 1500);
    }
}

// Auto-animate demo cursor when idle
class DemoCursorAnimation {
    constructor() {
        this.demoCursor = document.getElementById('demoCursor');
        this.isAnimating = false;
        this.init();
    }
    
    init() {
        if (!this.demoCursor) return;
        
        // Start animation after 3 seconds of inactivity
        let inactivityTimer;
        
        const resetTimer = () => {
            clearTimeout(inactivityTimer);
            this.isAnimating = false;
            inactivityTimer = setTimeout(() => {
                this.startAnimation();
            }, 3000);
        };
        
        // Detect user activity
        document.addEventListener('mousemove', resetTimer);
        document.addEventListener('click', resetTimer);
        document.addEventListener('touchstart', resetTimer);
        
        resetTimer();
    }
    
    startAnimation() {
        if (this.isAnimating) return;
        this.isAnimating = true;
        
        let x = 50;
        let y = 50;
        let dx = (Math.random() - 0.5) * 3;
        let dy = (Math.random() - 0.5) * 3;
        
        const animate = () => {
            if (!this.isAnimating) return;
            
            x += dx;
            y += dy;
            
            if (x > 90 || x < 10) dx = -dx;
            if (y > 90 || y < 10) dy = -dy;
            
            this.demoCursor.style.left = x + '%';
            this.demoCursor.style.top = y + '%';
            
            requestAnimationFrame(animate);
        };
        
        animate();
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new ControlCenter();
    new DemoCursorAnimation();
});

// Keyboard navigation for tabs
document.addEventListener('keydown', (e) => {
    const tabs = document.querySelectorAll('.tab-btn');
    const activeTab = document.querySelector('.tab-btn.active');
    
    if (!activeTab) return;
    
    const currentIndex = Array.from(tabs).indexOf(activeTab);
    
    if (e.key === 'ArrowRight' || e.key === 'ArrowDown') {
        e.preventDefault();
        const nextIndex = (currentIndex + 1) % tabs.length;
        tabs[nextIndex].click();
    } else if (e.key === 'ArrowLeft' || e.key === 'ArrowUp') {
        e.preventDefault();
        const prevIndex = (currentIndex - 1 + tabs.length) % tabs.length;
        tabs[prevIndex].click();
    }
});
