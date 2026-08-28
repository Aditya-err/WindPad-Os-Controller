/**
 * WindPad — Global Core JavaScript
 * Theme Management, Mobile Navigation, FAQ Accordions, Support Modal & Motion
 */

document.addEventListener('DOMContentLoaded', () => {
    initTheme();
    initMobileNav();
    initFAQ();
    initSupportModal();
    initDynamicImages();
    initCopyright();
});

/* ==========================================================================
   1. THEME ENGINE (Dark / Light Mode with LocalStorage & OS Preference)
   ========================================================================== */
function initTheme() {
    const themeToggleBtn = document.getElementById('themeToggleBtn');
    const themeToggleMobileBtn = document.getElementById('themeToggleMobileBtn');
    const themeValMobile = document.querySelector('.theme-val');
    
    // Check saved preference or OS preference
    const savedTheme = localStorage.getItem('windpad_theme');
    const systemPrefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    
    let currentTheme = savedTheme || (systemPrefersDark ? 'dark' : 'light');
    applyTheme(currentTheme);

    function applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('windpad_theme', theme);
        
        if (themeToggleBtn) {
            themeToggleBtn.setAttribute('aria-label', theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
            themeToggleBtn.setAttribute('title', theme === 'dark' ? 'Switch to light mode' : 'Switch to dark mode');
        }

        if (themeValMobile) {
            themeValMobile.textContent = theme === 'dark' ? '🌙 Dark' : '☀️ Light';
        }

        // Update any dynamic theme images
        updateThemeImages(theme);
    }

    function toggleTheme() {
        const active = document.documentElement.getAttribute('data-theme') || 'dark';
        const next = active === 'dark' ? 'light' : 'dark';
        applyTheme(next);
    }

    if (themeToggleBtn) {
        themeToggleBtn.addEventListener('click', toggleTheme);
    }

    if (themeToggleMobileBtn) {
        themeToggleMobileBtn.addEventListener('click', toggleTheme);
    }

    // Listen to OS scheme changes if user hasn't manually set one
    window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
        if (!localStorage.getItem('windpad_theme')) {
            applyTheme(e.matches ? 'dark' : 'light');
        }
    });
}

/* ==========================================================================
   2. DYNAMIC THEME IMAGES (Auto swap between Dark & Light assets)
   ========================================================================== */
function updateThemeImages(theme) {
    const themeImages = document.querySelectorAll('.theme-dynamic-img');
    themeImages.forEach(img => {
        const darkSrc = img.getAttribute('data-dark-src');
        const lightSrc = img.getAttribute('data-light-src');
        
        if (theme === 'dark' && darkSrc) {
            img.src = darkSrc;
        } else if (theme === 'light' && lightSrc) {
            img.src = lightSrc;
        }
    });
}

function initDynamicImages() {
    const theme = document.documentElement.getAttribute('data-theme') || 'dark';
    updateThemeImages(theme);
}

/* ==========================================================================
   3. MOBILE NAVIGATION (Accessible Hamburger Menu)
   ========================================================================== */
function initMobileNav() {
    const hamburgerBtn = document.getElementById('hamburgerBtn');
    const mobileMenu = document.getElementById('mobileMenu');

    if (!hamburgerBtn || !mobileMenu) return;

    hamburgerBtn.addEventListener('click', () => {
        const isExpanded = hamburgerBtn.getAttribute('aria-expanded') === 'true';
        hamburgerBtn.setAttribute('aria-expanded', !isExpanded);
        mobileMenu.setAttribute('aria-hidden', isExpanded);
        mobileMenu.classList.toggle('open');
    });

    // Close menu when clicking a link inside
    const mobileLinks = mobileMenu.querySelectorAll('a, .btn-link');
    mobileLinks.forEach(link => {
        link.addEventListener('click', () => {
            hamburgerBtn.setAttribute('aria-expanded', 'false');
            mobileMenu.setAttribute('aria-hidden', 'true');
            mobileMenu.classList.remove('open');
        });
    });
}

/* ==========================================================================
   4. FAQ ACCORDION
   ========================================================================== */
function initFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');

    faqItems.forEach(item => {
        const questionBtn = item.querySelector('.faq-question');
        const answer = item.querySelector('.faq-answer');

        if (!questionBtn || !answer) return;

        questionBtn.addEventListener('click', () => {
            const isActive = item.classList.contains('active');

            // Close other items
            faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.classList.remove('active');
                    const otherBtn = otherItem.querySelector('.faq-question');
                    const otherAns = otherItem.querySelector('.faq-answer');
                    if (otherBtn) otherBtn.setAttribute('aria-expanded', 'false');
                    if (otherAns) otherAns.style.maxHeight = null;
                }
            });

            // Toggle current
            if (isActive) {
                item.classList.remove('active');
                questionBtn.setAttribute('aria-expanded', 'false');
                answer.style.maxHeight = null;
            } else {
                item.classList.add('active');
                questionBtn.setAttribute('aria-expanded', 'true');
                answer.style.maxHeight = answer.scrollHeight + 'px';
            }
        });
    });
}

/* ==========================================================================
   5. SUPPORT MODAL (With secure mailto fallback)
   ========================================================================== */
function initSupportModal() {
    const modal = document.getElementById('supportModal');
    const closeBtn = document.getElementById('closeSupportModalBtn');
    const openBtns = [
        document.getElementById('openSupportBtnNav'),
        document.getElementById('openSupportBtnMobile'),
        document.getElementById('openSupportBtnContact'),
        document.getElementById('openSupportBtnFooter'),
        document.getElementById('openSupportBtnPage')
    ].filter(Boolean);

    const supportForm = document.getElementById('supportForm');

    function openModal() {
        if (!modal) return;
        modal.classList.add('open');
        modal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';
    }

    function closeModal() {
        if (!modal) return;
        modal.classList.remove('open');
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    }

    openBtns.forEach(btn => {
        btn.addEventListener('click', openModal);
    });

    if (closeBtn) {
        closeBtn.addEventListener('click', closeModal);
    }

    if (modal) {
        modal.addEventListener('click', (e) => {
            if (e.target === modal) {
                closeModal();
            }
        });
    }

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal && modal.classList.contains('open')) {
            closeModal();
        }
    });

    if (supportForm) {
        supportForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const type = document.getElementById('supportType').value;
            const message = document.getElementById('supportMessage').value;

            const recipient = 'gadityaprasadachary@gmail.com';
            const subject = encodeURIComponent('WindPad User Update');
            const body = encodeURIComponent(`Request Type: ${type}\n\nMessage:\n${message}\n\nSent via WindPad Web Client`);

            window.location.href = `mailto:${recipient}?subject=${subject}&body=${body}`;
            closeModal();
            supportForm.reset();
        });
    }
}

/* ==========================================================================
   6. COPYRIGHT YEAR
   ========================================================================== */
function initCopyright() {
    const copyrightYear = document.getElementById('copyrightYear');
    if (copyrightYear) {
        copyrightYear.textContent = new Date().getFullYear();
    }
}
