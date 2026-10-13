/* ============================================
   WINDPAD WEBSITE - FEATURES PAGE JAVASCRIPT
   Tab switching and interactive demos
   ============================================ */

// Feature Tabs Management
class FeatureTabs {
    constructor() {
        this.tabButtons = document.querySelectorAll('.tab-btn');
        this.featurePanels = document.querySelectorAll('.feature-panel');
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.initDemos();
    }
    
    bindEvents() {
        this.tabButtons.forEach(button => {
            button.addEventListener('click', () => {
                const tabId = button.getAttribute('data-tab');
                this.switchTab(tabId);
            });
        });
    }
    
    switchTab(tabId) {
        // Update tab buttons
        this.tabButtons.forEach(btn => {
            if (btn.getAttribute('data-tab') === tabId) {
                btn.classList.add('active');
            } else {
                btn.classList.remove('active');
            }
        });
        
        // Update feature panels
        this.featurePanels.forEach(panel => {
            if (panel.id === tabId) {
                panel.classList.add('active');
            } else {
                panel.classList.remove('active');
            }
        });
        
        // Reinitialize demos for the active tab
        this.initDemos();
    }
    
    initDemos() {
        this.initTrackpadDemo();
        this.initKeyboardDemo();
        this.initMediaDemo();
    }
    
    initTrackpadDemo() {
        const trackpad = document.querySelector('.trackpad-surface');
        const cursor = document.getElementById('trackpadCursor');
        
        if (!trackpad || !cursor) return;
        
        let isAnimating = false;
        
        const animateCursor = () => {
            if (isAnimating) return;
            isAnimating = true;
            
            let x = 50;
            let y = 50;
            let dx = (Math.random() - 0.5) * 4;
            let dy = (Math.random() - 0.5) * 4;
            
            const move = () => {
                x += dx;
                y += dy;
                
                if (x > 90 || x < 10) dx = -dx;
                if (y > 90 || y < 10) dy = -dy;
                
                cursor.style.left = x + '%';
                cursor.style.top = y + '%';
                
                requestAnimationFrame(move);
            };
            
            move();
        };
        
        // Start animation when panel is visible
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    animateCursor();
                }
            });
        });
        
        observer.observe(trackpad);
        
        // Add click animation
        trackpad.addEventListener('click', (e) => {
            const rect = trackpad.getBoundingClientRect();
            const x = ((e.clientX - rect.left) / rect.width) * 100;
            const y = ((e.clientY - rect.top) / rect.height) * 100;
            
            cursor.style.left = x + '%';
            cursor.style.top = y + '%';
            cursor.style.transform = 'translate(-50%, -50%) scale(0.8)';
            
            setTimeout(() => {
                cursor.style.transform = 'translate(-50%, -50%) scale(1)';
            }, 100);
        });
    }
    
    initKeyboardDemo() {
        const keys = document.querySelectorAll('.key');
        
        keys.forEach(key => {
            key.addEventListener('click', () => {
                key.style.transform = 'translateY(2px)';
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
    
    initMediaDemo() {
        const playBtn = document.querySelector('.media-btn--play');
        const progressFill = document.querySelector('.media-progress-fill');
        
        if (!playBtn || !progressFill) return;
        
        let isPlaying = true;
        
        playBtn.addEventListener('click', () => {
            isPlaying = !isPlaying;
            
            if (isPlaying) {
                progressFill.style.animationPlayState = 'running';
                playBtn.innerHTML = `
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <polygon points="5 3 19 12 5 21 5 3"/>
                    </svg>
                `;
            } else {
                progressFill.style.animationPlayState = 'paused';
                playBtn.innerHTML = `
                    <svg viewBox="0 0 24 24" fill="currentColor">
                        <rect x="6" y="4" width="4" height="16"/>
                        <rect x="14" y="4" width="4" height="16"/>
                    </svg>
                `;
            }
        });
    }
}

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

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new FeatureTabs();
});
