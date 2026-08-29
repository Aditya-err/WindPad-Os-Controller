/**
 * WindPad — Global Core JavaScript Engine
 * Interactive Canvas Dotted Matrix, Hero Trackpad Simulator,
 * Card Spotlight Physics, Scroll Reveals, Mobile Nav & Support Modal.
 */

document.addEventListener('DOMContentLoaded', () => {
    initDynamicImages();
    initMobileNav();
    initFAQ();
    initSupportModal();
    initHeroInteractiveTrackpad();
    initCardSpotlight();
    initScrollReveal();
    initDottedWindpadCanvas();
    initCopyright();
});

/* ==========================================================================
   1. DYNAMIC THEME IMAGES (Default Dark High-Res Assets)
   ========================================================================== */
function initDynamicImages() {
    const themeImages = document.querySelectorAll('.theme-dynamic-img');
    themeImages.forEach(img => {
        const darkSrc = img.getAttribute('data-dark-src');
        if (darkSrc) {
            img.src = darkSrc;
        }
    });
}

/* ==========================================================================
   3. HERO INTERACTIVE TRACKPAD SIMULATOR
   ========================================================================== */
function initHeroInteractiveTrackpad() {
    const trackpad = document.getElementById('heroTrackpadInteractive');
    const cursor = document.getElementById('heroTrackpadCursor');
    const coordsDisplay = document.getElementById('heroTrackpadCoords');
    const statusPill = document.getElementById('heroTrackpadStatus');
    const modifierKeys = document.querySelectorAll('.hero-mod-key');
    const leftClickBtn = document.getElementById('heroLeftClickBtn');
    const rightClickBtn = document.getElementById('heroRightClickBtn');

    if (!trackpad || !cursor) return;

    let isHovering = false;

    function handleMove(e) {
        const rect = trackpad.getBoundingClientRect();
        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
        const clientY = e.touches ? e.touches[0].clientY : e.clientY;

        const x = Math.max(10, Math.min(rect.width - 10, clientX - rect.left));
        const y = Math.max(10, Math.min(rect.height - 10, clientY - rect.top));

        cursor.style.transform = `translate(${x}px, ${y}px)`;
        
        if (coordsDisplay) {
            const normX = Math.round((x / rect.width) * 1920);
            const normY = Math.round((y / rect.height) * 1080);
            coordsDisplay.textContent = `X: ${normX} Y: ${normY}`;
        }
    }

    function createRipple(x, y) {
        const ripple = document.createElement('span');
        ripple.className = 'trackpad-touch-ripple';
        ripple.style.left = `${x}px`;
        ripple.style.top = `${y}px`;
        trackpad.appendChild(ripple);

        setTimeout(() => {
            ripple.remove();
        }, 600);
    }

    trackpad.addEventListener('mousemove', (e) => {
        isHovering = true;
        handleMove(e);
    });

    trackpad.addEventListener('touchmove', (e) => {
        handleMove(e);
    }, { passive: true });

    trackpad.addEventListener('click', (e) => {
        const rect = trackpad.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        createRipple(x, y);

        if (statusPill) {
            statusPill.textContent = '● Tap Click';
            statusPill.classList.add('active-tap');
            setTimeout(() => {
                statusPill.textContent = '● Live HID';
                statusPill.classList.remove('active-tap');
            }, 500);
        }
    });

    // Modifier buttons toggle
    modifierKeys.forEach(key => {
        key.addEventListener('click', () => {
            key.classList.toggle('active-key');
        });
    });

    if (leftClickBtn) {
        leftClickBtn.addEventListener('click', () => {
            leftClickBtn.classList.add('clicking');
            if (statusPill) statusPill.textContent = '● Left Click';
            setTimeout(() => {
                leftClickBtn.classList.remove('clicking');
                if (statusPill) statusPill.textContent = '● Live HID';
            }, 300);
        });
    }

    if (rightClickBtn) {
        rightClickBtn.addEventListener('click', () => {
            rightClickBtn.classList.add('clicking');
            if (statusPill) statusPill.textContent = '● Right Click';
            setTimeout(() => {
                rightClickBtn.classList.remove('clicking');
                if (statusPill) statusPill.textContent = '● Live HID';
            }, 300);
        });
    }
}

/* ==========================================================================
   4. CARD SPOTLIGHT HOVER EFFECT (Mouse-tracking glow)
   ========================================================================== */
function initCardSpotlight() {
    const cards = document.querySelectorAll('.bento-card, .showcase-h-card, .comparison-card, .platform-card, .usecase-card, .helper-banner, .contact-box');

    cards.forEach(card => {
        card.addEventListener('mousemove', (e) => {
            const rect = card.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;
            card.style.setProperty('--mouse-x', `${x}px`);
            card.style.setProperty('--mouse-y', `${y}px`);
        });
    });
}

/* ==========================================================================
   5. SCROLL-TRIGGERED REVEALS (Intersection Observer)
   ========================================================================== */
function initScrollReveal() {
    const revealElements = document.querySelectorAll('.reveal-on-scroll');

    if (!('IntersectionObserver' in window)) {
        revealElements.forEach(el => el.classList.add('is-visible'));
        return;
    }

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('is-visible');
                observer.unobserve(entry.target);
            }
        });
    }, {
        rootMargin: '0px 0px -50px 0px',
        threshold: 0.1
    });

    revealElements.forEach(el => observer.observe(el));
}

/* ==========================================================================
   6. GRAND INTERACTIVE DOTTED "WINDPAD" CANVAS (Footer Showcase)
   ========================================================================== */
function initDottedWindpadCanvas() {
    const canvas = document.getElementById('dottedWindpadCanvas');
    const container = document.getElementById('dottedCanvasContainer');
    if (!canvas || !container) return;

    const ctx = canvas.getContext('2d');
    let width, height;
    let dots = [];
    let animationFrameId;
    let mouse = { x: -1000, y: -1000, radius: 90 };

    const DOT_SPACING = 6.5;
    const DOT_RADIUS = 2.0;

    function resize() {
        const dpr = Math.min(window.devicePixelRatio || 1, 2);
        width = container.clientWidth;
        height = Math.max(160, Math.min(240, window.innerHeight * 0.25));

        canvas.width = width * dpr;
        canvas.height = height * dpr;
        canvas.style.width = `${width}px`;
        canvas.style.height = `${height}px`;

        ctx.scale(dpr, dpr);
        
        if (document.fonts) {
            document.fonts.load('120px Slackey').then(() => {
                initDots();
            }).catch(() => {
                initDots();
            });
        } else {
            initDots();
        }
    }

    function initDots() {
        dots = [];

        // Offscreen canvas for Slackey font text rendering mask
        const offCanvas = document.createElement('canvas');
        offCanvas.width = width;
        offCanvas.height = height;
        const offCtx = offCanvas.getContext('2d');

        offCtx.fillStyle = '#000000';
        offCtx.fillRect(0, 0, width, height);

        // Responsive font calculation for Slackey
        const fontSize = Math.min(width * 0.175, height * 0.78);
        offCtx.font = `400 ${fontSize}px "Slackey", cursive, sans-serif`;
        offCtx.textAlign = 'center';
        offCtx.textBaseline = 'middle';
        offCtx.fillStyle = '#FFFFFF';
        offCtx.letterSpacing = '0.02em';
        offCtx.fillText('WindPad', width / 2, height / 2);

        const imgData = offCtx.getImageData(0, 0, width, height).data;

        for (let y = 0; y < height; y += DOT_SPACING) {
            for (let x = 0; x < width; x += DOT_SPACING) {
                const index = (Math.floor(y) * width + Math.floor(x)) * 4;
                const brightness = imgData[index]; // White text = 255

                if (brightness > 90) {
                    dots.push({
                        originX: x,
                        originY: y,
                        x: x,
                        y: y,
                        vx: 0,
                        vy: 0,
                        baseRadius: DOT_RADIUS,
                        radius: DOT_RADIUS,
                        alpha: 0.65,
                        phase: (x / width) * Math.PI * 2
                    });
                }
            }
        }
    }

    let time = 0;

    function render() {
        time += 0.035;
        ctx.clearRect(0, 0, width, height);

        const theme = document.documentElement.getAttribute('data-theme') || 'dark';
        const isDark = theme === 'dark';

        for (let i = 0; i < dots.length; i++) {
            const dot = dots[i];

            // Distance to mouse
            const dx = mouse.x - dot.x;
            const dy = mouse.y - dot.y;
            const dist = Math.sqrt(dx * dx + dy * dy);

            // Natural ambient wave
            const wave = Math.sin(time + dot.phase) * 0.5 + 0.5;

            let targetRadius = dot.baseRadius + wave * 0.6;
            let targetAlpha = isDark ? (0.5 + wave * 0.35) : (0.75 + wave * 0.25);

            if (dist < mouse.radius) {
                const force = (1 - dist / mouse.radius);
                const angle = Math.atan2(dy, dx);
                
                // Displace slightly away from cursor
                dot.vx -= Math.cos(angle) * force * 1.5;
                dot.vy -= Math.sin(angle) * force * 1.5;

                targetRadius = dot.baseRadius + force * 2.8;
                targetAlpha = 1.0;
            }

            // Spring return
            dot.vx += (dot.originX - dot.x) * 0.12;
            dot.vy += (dot.originY - dot.y) * 0.12;
            dot.vx *= 0.82;
            dot.vy *= 0.82;

            dot.x += dot.vx;
            dot.y += dot.vy;
            dot.radius += (targetRadius - dot.radius) * 0.2;
            dot.alpha += (targetAlpha - dot.alpha) * 0.2;

            ctx.beginPath();
            ctx.arc(dot.x, dot.y, dot.radius, 0, Math.PI * 2);

            // Glowing peach-to-cyan dot colors matching Grabient footer
            const colorGlow = dist < mouse.radius ? '#FFFFFF' : (wave > 0.5 ? '#FFC695' : '#48CAE4');
            ctx.fillStyle = colorGlow;
            ctx.globalAlpha = dot.alpha;
            ctx.fill();
        }

        ctx.globalAlpha = 1.0;
        animationFrameId = requestAnimationFrame(render);
    }

    container.addEventListener('mousemove', (e) => {
        const rect = canvas.getBoundingClientRect();
        mouse.x = e.clientX - rect.left;
        mouse.y = e.clientY - rect.top;
    });

    container.addEventListener('mouseleave', () => {
        mouse.x = -1000;
        mouse.y = -1000;
    });

    window.updateDottedCanvasTheme = () => {
        // Redraw will automatically use current theme in render loop
    };

    window.addEventListener('resize', resize);
    resize();
    render();
}

/* ==========================================================================
   7. MOBILE NAVIGATION (Accessible Hamburger Menu)
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
   8. FAQ ACCORDION
   ========================================================================== */
function initFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');

    faqItems.forEach(item => {
        const questionBtn = item.querySelector('.faq-question');
        const answer = item.querySelector('.faq-answer');

        if (!questionBtn || !answer) return;

        questionBtn.addEventListener('click', () => {
            const isActive = item.classList.contains('active');

            faqItems.forEach(otherItem => {
                if (otherItem !== item) {
                    otherItem.classList.remove('active');
                    const otherBtn = otherItem.querySelector('.faq-question');
                    const otherAns = otherItem.querySelector('.faq-answer');
                    if (otherBtn) otherBtn.setAttribute('aria-expanded', 'false');
                    if (otherAns) otherAns.style.maxHeight = null;
                }
            });

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
   9. SUPPORT MODAL
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
   10. COPYRIGHT YEAR
   ========================================================================== */
function initCopyright() {
    const copyrightYear = document.getElementById('copyrightYear');
    if (copyrightYear) {
        copyrightYear.textContent = new Date().getFullYear();
    }
}
