/* ============================================
   WINDPAD WEBSITE - MAIN JAVASCRIPT
   Interactive elements and animations
   ============================================ */

// Theme Management
class ThemeManager {
    constructor() {
        this.currentTheme = localStorage.getItem('theme') || 'dark';
        this.init();
    }
    
    init() {
        this.applyTheme(this.currentTheme);
        this.bindEvents();
        this.initSystemTheme();
    }
    
    applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
        this.currentTheme = theme;
        
        // Dispatch custom event for other components
        document.dispatchEvent(new CustomEvent('themeChanged', { detail: { theme } }));
    }
    
    toggleTheme() {
        const newTheme = this.currentTheme === 'dark' ? 'light' : 'dark';
        this.applyTheme(newTheme);
    }
    
    initSystemTheme() {
        // Check system preference on first visit
        if (!localStorage.getItem('theme')) {
            const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
            this.applyTheme(prefersDark ? 'dark' : 'light');
        }
        
        // Listen for system theme changes
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
            if (!localStorage.getItem('theme')) {
                this.applyTheme(e.matches ? 'dark' : 'light');
            }
        });
    }
    
    bindEvents() {
        const themeToggle = document.getElementById('themeToggle');
        if (themeToggle) {
            themeToggle.addEventListener('click', () => this.toggleTheme());
        }
    }
}

// Navigation Management
class Navigation {
    constructor() {
        this.nav = document.getElementById('nav');
        this.navToggle = document.getElementById('navToggle');
        this.navMenu = document.getElementById('navMenu');
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.updateActiveLink();
        this.handleScroll();
        this.initPageTransitions();
    }
    
    bindEvents() {
        if (this.navToggle) {
            this.navToggle.addEventListener('click', () => this.toggleMenu());
        }
        
        // Close menu when clicking a link
        const navLinks = document.querySelectorAll('.nav-link');
        navLinks.forEach(link => {
            link.addEventListener('click', () => this.closeMenu());
        });
        
        // Handle scroll
        window.addEventListener('scroll', () => this.handleScroll());
        
        // Handle page visibility changes
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                this.closeMenu();
            }
        });
    }
    
    toggleMenu() {
        this.navMenu.classList.toggle('active');
        this.navToggle.classList.toggle('active');
        
        // Prevent body scroll when menu is open
        if (this.navMenu.classList.contains('active')) {
            document.body.style.overflow = 'hidden';
        } else {
            document.body.style.overflow = '';
        }
    }
    
    closeMenu() {
        this.navMenu.classList.remove('active');
        this.navToggle.classList.remove('active');
        document.body.style.overflow = '';
    }
    
    updateActiveLink() {
        const currentPage = window.location.pathname.split('/').pop() || 'index.html';
        const navLinks = document.querySelectorAll('.nav-link');
        
        navLinks.forEach(link => {
            const linkPage = link.getAttribute('href');
            if (linkPage === currentPage) {
                link.classList.add('active');
            } else {
                link.classList.remove('active');
            }
        });
    }
    
    handleScroll() {
        if (window.scrollY > 50) {
            this.nav.classList.add('scrolled');
        } else {
            this.nav.classList.remove('scrolled');
        }
    }
    
    initPageTransitions() {
        // Add page transition animation
        document.body.classList.add('page-transition');
        
        // Handle navigation for SPA-like behavior
        const allLinks = document.querySelectorAll('a[href$=".html"]');
        allLinks.forEach(link => {
            link.addEventListener('click', (e) => {
                const href = link.getAttribute('href');
                
                // Only handle internal links
                if (href && !href.startsWith('http') && !href.startsWith('#')) {
                    e.preventDefault();
                    this.transitionToPage(href);
                }
            });
        });
    }
    
    transitionToPage(href) {
        // Fade out current page
        document.body.style.opacity = '0';
        document.body.style.transition = 'opacity 0.3s ease';
        
        setTimeout(() => {
            window.location.href = href;
        }, 300);
    }
}

// Scroll Animations
class ScrollAnimations {
    constructor() {
        this.elements = document.querySelectorAll('.scroll-reveal');
        this.init();
    }
    
    init() {
        this.bindEvents();
        this.checkElements();
    }
    
    bindEvents() {
        window.addEventListener('scroll', () => this.checkElements());
        window.addEventListener('resize', () => this.checkElements());
    }
    
    checkElements() {
        this.elements.forEach(element => {
            const elementTop = element.getBoundingClientRect().top;
            const windowHeight = window.innerHeight;
            
            if (elementTop < windowHeight * 0.85) {
                element.classList.add('visible');
            }
        });
    }
}

// Hero Animations
class HeroAnimations {
    constructor() {
        this.init();
    }
    
    init() {
        this.animateConnection();
        this.animatePhoneScreen();
        this.animatePcScreen();
    }
    
    animateConnection() {
        const connection = document.querySelector('.hero-connection');
        if (connection) {
            connection.style.opacity = '0';
            connection.style.transform = 'translate(-50%, -50%) scale(0.8)';
            
            setTimeout(() => {
                connection.style.transition = 'all 1s ease';
                connection.style.opacity = '1';
                connection.style.transform = 'translate(-50%, -50%) scale(1)';
            }, 500);
        }
    }
    
    animatePhoneScreen() {
        const phoneScreen = document.querySelector('.phone-screen-content');
        if (phoneScreen) {
            this.createPhoneUI(phoneScreen);
        }
    }
    
    animatePcScreen() {
        const pcScreen = document.querySelector('.pc-screen-content');
        if (pcScreen) {
            this.createPcUI(pcScreen);
        }
    }
    
    createPhoneUI(container) {
        container.innerHTML = `
            <div class="phone-ui">
                <div class="phone-header">
                    <div class="phone-status">
                        <span>WindPad</span>
                        <span class="phone-indicator"></span>
                    </div>
                </div>
                <div class="phone-trackpad">
                    <div class="trackpad-surface"></div>
                </div>
                <div class="phone-controls">
                    <div class="control-btn">🖱️</div>
                    <div class="control-btn">⌨️</div>
                    <div class="control-btn">🎵</div>
                </div>
            </div>
        `;
    }
    
    createPcUI(container) {
        container.innerHTML = `
            <div class="pc-ui">
                <div class="pc-desktop">
                    <div class="pc-window">
                        <div class="window-header">
                            <div class="window-controls">
                                <span></span>
                                <span></span>
                                <span></span>
                            </div>
                            <span>WindPad Connected</span>
                        </div>
                        <div class="window-content">
                            <div class="cursor" id="cursor"></div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        this.animateCursor();
    }
    
    animateCursor() {
        const cursor = document.getElementById('cursor');
        if (cursor) {
            let x = 50;
            let y = 50;
            let dx = 2;
            let dy = 1.5;
            
            const animate = () => {
                x += dx;
                y += dy;
                
                if (x > 80 || x < 20) dx = -dx;
                if (y > 80 || y < 20) dy = -dy;
                
                cursor.style.left = x + '%';
                cursor.style.top = y + '%';
                
                requestAnimationFrame(animate);
            };
            
            setTimeout(animate, 1000);
        }
    }
}

// Page Transition
class PageTransition {
    constructor() {
        this.init();
    }
    
    init() {
        document.body.classList.add('page-transition');
    }
}

// Counter Animation
class CounterAnimation {
    constructor() {
        this.counters = document.querySelectorAll('.stat-value');
        this.init();
    }
    
    init() {
        this.counters.forEach(counter => this.animateCounter(counter));
    }
    
    animateCounter(counter) {
        const target = counter.textContent;
        const duration = 2000;
        const steps = 60;
        const stepDuration = duration / steps;
        
        let current = 0;
        const increment = this.parseValue(target) / steps;
        
        const update = () => {
            current += increment;
            if (current >= this.parseValue(target)) {
                counter.textContent = target;
            } else {
                counter.textContent = this.formatValue(current, target);
                setTimeout(update, stepDuration);
            }
        };
        
        // Start animation when element is visible
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    update();
                    observer.unobserve(entry.target);
                }
            });
        });
        
        observer.observe(counter);
    }
    
    parseValue(value) {
        if (value.includes('ms')) return 0;
        if (value.includes('%')) return 100;
        if (value === '∞') return 999;
        return parseFloat(value);
    }
    
    formatValue(current, target) {
        if (target.includes('ms')) return '0ms';
        if (target.includes('%')) return Math.round(current) + '%';
        if (target === '∞') return '∞';
        return Math.round(current);
    }
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new ThemeManager();
    new Navigation();
    new ScrollAnimations();
    new HeroAnimations();
    new PageTransition();
    new CounterAnimation();
    
    // Add scroll-reveal class to elements that should animate
    const animateElements = document.querySelectorAll('.preview-card, .compatibility-item, .intro-content, .cta-content');
    animateElements.forEach(el => el.classList.add('scroll-reveal'));
    
    // Add hover effects to cards
    const cards = document.querySelectorAll('.preview-card, .detail-card, .requirement-card, .contribute-card, .principle-card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', () => {
            card.style.transform = 'translateY(-4px)';
        });
        
        card.addEventListener('mouseleave', () => {
            card.style.transform = 'translateY(0)';
        });
    });
    
    // Add ripple effect to buttons
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            const rect = this.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            
            const ripple = document.createElement('span');
            ripple.style.cssText = `
                position: absolute;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                transform: scale(0);
                animation: ripple 0.6s linear;
                left: ${x}px;
                top: ${y}px;
                width: 100px;
                height: 100px;
                margin-left: -50px;
                margin-top: -50px;
            `;
            
            this.appendChild(ripple);
            
            setTimeout(() => ripple.remove(), 600);
        });
    });
    
    // Add CSS for ripple animation
    const style = document.createElement('style');
    style.textContent = `
        @keyframes ripple {
            to {
                transform: scale(4);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);
});

// Smooth scroll for anchor links
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Keyboard navigation
document.addEventListener('keydown', (e) => {
    // Escape key closes mobile menu
    if (e.key === 'Escape') {
        const navMenu = document.getElementById('navMenu');
        if (navMenu && navMenu.classList.contains('active')) {
            navMenu.classList.remove('active');
        }
    }
});

// Preload critical images
const preloadImages = () => {
    const images = [
        'assets/windpad.png',
        'assets/windpad-icon.png'
    ];
    
    images.forEach(src => {
        const img = new Image();
        img.src = src;
    });
};

preloadImages();
