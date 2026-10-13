/* ============================================
   WINDPAD WEBSITE - DOWNLOAD PAGE JAVASCRIPT
   Installation journey and troubleshooting
   ============================================ */

// Troubleshooting Accordion
class TroubleshootingAccordion {
    constructor() {
        this.items = document.querySelectorAll('.troubleshoot-item');
        this.init();
    }
    
    init() {
        this.items.forEach(item => {
            const toggle = item.querySelector('.troubleshoot-toggle');
            if (toggle) {
                toggle.addEventListener('click', () => {
                    this.toggleItem(item);
                });
            }
        });
    }
    
    toggleItem(item) {
        const isActive = item.classList.contains('active');
        
        // Close all items
        this.items.forEach(i => i.classList.remove('active'));
        
        // Open clicked item if it wasn't active
        if (!isActive) {
            item.classList.add('active');
        }
    }
}

// Installation Steps Animation
class InstallationStepsAnimation {
    constructor() {
        this.steps = document.querySelectorAll('.journey-step');
        this.init();
    }
    
    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateStep(entry.target);
                }
            });
        }, {
            threshold: 0.3,
            rootMargin: '0px 0px -50px 0px'
        });
        
        this.steps.forEach(step => {
            step.classList.add('scroll-reveal');
            observer.observe(step);
        });
    }
    
    animateStep(step) {
        const stepNumber = step.querySelector('.step-number');
        const stepContent = step.querySelector('.step-content');
        
        if (stepNumber) {
            stepNumber.style.transform = 'scale(0)';
            stepNumber.style.opacity = '0';
            
            setTimeout(() => {
                stepNumber.style.transition = 'all 0.5s ease';
                stepNumber.style.transform = 'scale(1)';
                stepNumber.style.opacity = '1';
            }, 100);
        }
        
        if (stepContent) {
            stepContent.style.transform = 'translateX(20px)';
            stepContent.style.opacity = '0';
            
            setTimeout(() => {
                stepContent.style.transition = 'all 0.5s ease';
                stepContent.style.transform = 'translateX(0)';
                stepContent.style.opacity = '1';
            }, 200);
        }
    }
}

// Requirements Cards Animation
class RequirementsAnimation {
    constructor() {
        this.cards = document.querySelectorAll('.requirement-card');
        this.init();
    }
    
    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateCard(entry.target);
                }
            });
        }, {
            threshold: 0.3
        });
        
        this.cards.forEach((card, index) => {
            card.classList.add('scroll-reveal');
            card.style.transitionDelay = `${index * 100}ms`;
            observer.observe(card);
        });
    }
    
    animateCard(card) {
        card.style.transform = 'translateY(30px)';
        card.style.opacity = '0';
        
        setTimeout(() => {
            card.style.transition = 'all 0.5s ease';
            card.style.transform = 'translateY(0)';
            card.style.opacity = '1';
        }, 50);
    }
}

// Download Button Animation
class DownloadButtonAnimation {
    constructor() {
        this.downloadBtns = document.querySelectorAll('.btn[href*="WindPad.apk"]');
        this.init();
    }
    
    init() {
        this.downloadBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.animateDownload(btn);
            });
        });
    }
    
    animateDownload(btn) {
        const originalContent = btn.innerHTML;
        
        // Show loading state
        btn.innerHTML = `
            <svg class="download-spinner" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/>
                <path d="M12 6v6M12 18h.01"/>
            </svg>
            <span>Starting download...</span>
        `;
        
        btn.style.pointerEvents = 'none';
        
        // Reset after 2 seconds
        setTimeout(() => {
            btn.innerHTML = originalContent;
            btn.style.pointerEvents = '';
        }, 2000);
    }
}

// Progress Tracker
class ProgressTracker {
    constructor() {
        this.steps = document.querySelectorAll('.journey-step');
        this.init();
    }
    
    init() {
        this.trackProgress();
        window.addEventListener('scroll', () => this.trackProgress());
    }
    
    trackProgress() {
        const scrollPercent = window.scrollY / (document.body.scrollHeight - window.innerHeight);
        
        this.steps.forEach((step, index) => {
            const stepNumber = step.querySelector('.step-number');
            const stepProgress = (index + 1) / this.steps.length;
            
            if (scrollPercent >= stepProgress * 0.8) {
                stepNumber.style.background = 'var(--success)';
            } else if (scrollPercent >= stepProgress * 0.5) {
                stepNumber.style.background = 'var(--accent-primary)';
            } else {
                stepNumber.style.background = 'var(--accent-primary)';
            }
        });
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new TroubleshootingAccordion();
    new InstallationStepsAnimation();
    new RequirementsAnimation();
    new DownloadButtonAnimation();
    new ProgressTracker();
});

// Keyboard navigation for troubleshooting
document.addEventListener('keydown', (e) => {
    const items = document.querySelectorAll('.troubleshoot-item');
    const activeItem = document.querySelector('.troubleshoot-item.active');
    
    if (e.key === 'Escape' && activeItem) {
        activeItem.classList.remove('active');
    }
    
    if (e.key === 'Enter' || e.key === ' ') {
        const focusedElement = document.activeElement;
        if (focusedElement && focusedElement.classList.contains('troubleshoot-toggle')) {
            e.preventDefault();
            focusedElement.click();
        }
    }
});
