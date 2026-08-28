// Intersection Observer for scroll animations
document.addEventListener('DOMContentLoaded', () => {
    // Global state for Three.js active section
    window.activeSection = 'home';
    
    // Intersection Observer for scroll animations (Staggered)
    const revealObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const el = entry.target;
                
                // Add staggered delay for grid items
                if (el.classList.contains('feature-card') || 
                    el.classList.contains('use-card') || 
                    el.classList.contains('comparison-card') ||
                    el.classList.contains('faq-item') ||
                    el.classList.contains('gallery-img') ||
                    el.classList.contains('download-card')) {
                    
                    const parent = el.parentElement;
                    const siblings = Array.from(parent.children).filter(child => child.classList.contains('reveal'));
                    const index = siblings.indexOf(el);
                    el.style.transitionDelay = `${index * 0.15}s`;
                }
                
                el.classList.add('active');
                revealObserver.unobserve(el);
            }
        });
    }, { threshold: 0.15 });

    document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

    // Section Observer for Three.js Background changes
    const sectionObserver = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const sectionId = entry.target.id || 'home';
                window.activeSection = sectionId;
                
                // Update body class for CSS glow color transitions
                document.body.className = document.body.className.replace(/\bsection-\S+/g, '');
                document.body.classList.add(`section-${sectionId}`);
            }
        });
    }, { threshold: 0.3 }); // 30% of the section must be visible
    
    document.querySelectorAll('section').forEach(sec => sectionObserver.observe(sec));

    // Smooth scrolling for anchor links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                // Close mobile menu if open
                document.querySelector('.nav-links').classList.remove('open');
                document.querySelector('.mobile-menu-btn').classList.remove('open');
                
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
    });

    // --- Mobile Menu Toggle ---
    const menuBtn = document.querySelector('.mobile-menu-btn');
    const navLinks = document.querySelector('.nav-links');
    
    if (menuBtn && navLinks) {
        menuBtn.addEventListener('click', () => {
            navLinks.classList.toggle('open');
            menuBtn.classList.toggle('open');
        });
    }

    // --- Support Modal Logic ---
    const supportBtns = document.querySelectorAll('.support-btn, .footer-support-btn');
    const modal = document.getElementById('supportModal');
    const closeBtn = document.querySelector('.modal-close');
    const cancelBtn = document.getElementById('cancelSupport');
    const submitBtn = document.getElementById('submitSupport');
    const messageInput = document.getElementById('supportMessage');
    const errorMsg = document.getElementById('supportError');
    const formContainer = document.getElementById('supportFormContainer');
    const successContainer = document.getElementById('supportSuccessMessage');
    const closeSuccessBtn = document.getElementById('closeSuccess');

    const openModal = () => {
        // Reset state
        formContainer.style.display = 'block';
        successContainer.style.display = 'none';
        messageInput.value = '';
        errorMsg.textContent = '';
        
        modal.classList.add('open');
        document.body.classList.add('modal-open');
        
        // Close mobile menu if open
        if (navLinks.classList.contains('open')) {
            navLinks.classList.remove('open');
            menuBtn.classList.remove('open');
        }
    };

    const closeModal = () => {
        modal.classList.remove('open');
        document.body.classList.remove('modal-open');
    };

    supportBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            openModal();
        });
    });

    closeBtn.addEventListener('click', closeModal);
    cancelBtn.addEventListener('click', closeModal);
    closeSuccessBtn.addEventListener('click', closeModal);

    // Close on outside click
    modal.addEventListener('click', (e) => {
        if (e.target === modal) {
            closeModal();
        }
    });

    // Close on ESC key
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.classList.contains('open')) {
            closeModal();
        }
    });

    // Submit logic (mailto fallback)
    submitBtn.addEventListener('click', () => {
        const message = messageInput.value.trim();
        if (!message) {
            errorMsg.textContent = 'Please describe your update or request before sending.';
            return;
        }

        errorMsg.textContent = '';
        
        // Prepare mailto link
        const recipient = 'gadityaprasadachary@gmail.com';
        const subject = encodeURIComponent('WindPad User Update');
        
        const date = new Date().toLocaleString();
        const bodyText = `New WindPad user update/request:\n\n${message}\n\nSource: WindPad Website\nDate: ${date}`;
        const body = encodeURIComponent(bodyText);
        
        const mailtoLink = `mailto:${recipient}?subject=${subject}&body=${body}`;
        
        // Attempt to open email client
        window.location.href = mailtoLink;
        
        // Show success UI
        formContainer.style.display = 'none';
        successContainer.style.display = 'block';
    });

});
