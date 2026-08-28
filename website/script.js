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


    // --- Three.js Background Animation ---
    const canvas = document.querySelector('#bg-canvas');
    if (canvas && typeof THREE !== 'undefined') {
        const scene = new THREE.Scene();
        
        // Add a subtle fog for depth
        scene.fog = new THREE.FogExp2(0x0b0f19, 0.001);

        const camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        camera.position.z = 30;

        const renderer = new THREE.WebGLRenderer({ 
            canvas: canvas, 
            alpha: true,
            antialias: true 
        });
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

        // Create Particles
        const particlesGeometry = new THREE.BufferGeometry();
        const particlesCount = window.innerWidth < 768 ? 800 : 1500; // Optimize for mobile
        
        const posArray = new Float32Array(particlesCount * 3);
        const colorsArray = new Float32Array(particlesCount * 3);

        const createCircleTexture = () => {
            const canvas = document.createElement('canvas');
            canvas.width = 64;
            canvas.height = 64;
            const ctx = canvas.getContext('2d');
            
            const gradient = ctx.createRadialGradient(32, 32, 0, 32, 32, 32);
            gradient.addColorStop(0, 'rgba(255,255,255,1)');
            gradient.addColorStop(0.2, 'rgba(255,255,255,0.8)');
            gradient.addColorStop(1, 'rgba(255,255,255,0)');
            
            ctx.fillStyle = gradient;
            ctx.fillRect(0, 0, 64, 64);
            
            return new THREE.CanvasTexture(canvas);
        };

        const color1 = new THREE.Color(0x3b82f6); // Primary blue
        const color2 = new THREE.Color(0xa855f7); // Purple
        const color3 = new THREE.Color(0x10b981); // Emerald Green

        for(let i = 0; i < particlesCount * 3; i+=3) {
            posArray[i] = (Math.random() - 0.5) * 100;     // x
            posArray[i+1] = (Math.random() - 0.5) * 100;   // y
            posArray[i+2] = (Math.random() - 0.5) * 100;   // z

            const rand = Math.random();
            let mixedColor = new THREE.Color();
            
            if (rand < 0.33) {
                mixedColor.lerpColors(color1, color2, Math.random());
            } else if (rand < 0.66) {
                mixedColor.lerpColors(color2, color3, Math.random());
            } else {
                mixedColor.lerpColors(color3, color1, Math.random());
            }
            
            colorsArray[i] = mixedColor.r;
            colorsArray[i+1] = mixedColor.g;
            colorsArray[i+2] = mixedColor.b;
        }

        particlesGeometry.setAttribute('position', new THREE.BufferAttribute(posArray, 3));
        particlesGeometry.setAttribute('color', new THREE.BufferAttribute(colorsArray, 3));

        const particlesMaterial = new THREE.PointsMaterial({
            size: 0.4,
            vertexColors: true,
            transparent: true,
            opacity: 0.8,
            map: createCircleTexture(),
            blending: THREE.AdditiveBlending,
            depthWrite: false
        });

        const particleMesh = new THREE.Points(particlesGeometry, particlesMaterial);
        scene.add(particleMesh);

        let mouseX = 0;
        let mouseY = 0;
        let targetX = 0;
        let targetY = 0;
        let windowHalfX = window.innerWidth / 2;
        let windowHalfY = window.innerHeight / 2;

        document.addEventListener('mousemove', (event) => {
            mouseX = (event.clientX - windowHalfX);
            mouseY = (event.clientY - windowHalfY);
        });

        window.addEventListener('resize', () => {
            windowHalfX = window.innerWidth / 2;
            windowHalfY = window.innerHeight / 2;
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });

        const clock = new THREE.Clock();

        const animate = () => {
            requestAnimationFrame(animate);
            const elapsedTime = clock.getElapsedTime();
            
            // Scroll progression (0 to 1 across the document)
            const maxScroll = Math.max(document.body.scrollHeight, document.documentElement.scrollHeight) - window.innerHeight;
            const scrollPercent = maxScroll > 0 ? (window.scrollY / maxScroll) : 0;
            
            // 1. Fly-through camera effect: move camera forward as we scroll
            const targetCameraZ = 30 - (scrollPercent * 15);
            camera.position.z += (targetCameraZ - camera.position.z) * 0.05;

            // 2. Section-specific behaviors
            let targetRotSpeedY = 0.001;
            let targetRotSpeedX = 0.0005;
            let targetFogDensity = 0.001;
            
            switch(window.activeSection) {
                case 'home':
                    targetRotSpeedY = 0.001;
                    targetRotSpeedX = 0.0005;
                    break;
                case 'why-windpad':
                case 'features':
                    targetRotSpeedY = 0.003; // Speed up
                    targetRotSpeedX = 0.0015;
                    break;
                case 'compatibility':
                case 'use-cases':
                    targetRotSpeedY = -0.002; // Reverse flow
                    targetRotSpeedX = 0.001;
                    break;
                case 'setup':
                case 'screenshots':
                    targetRotSpeedY = 0.004;
                    targetRotSpeedX = -0.001; 
                    targetFogDensity = 0.002; // Thicker fog
                    break;
                case 'faq':
                case 'download':
                case 'contact':
                    targetRotSpeedY = 0.0005; // Slow down
                    targetRotSpeedX = 0.0005;
                    targetFogDensity = 0.003;
                    break;
            }

            // Smoothly interpolate fog density
            scene.fog.density += (targetFogDensity - scene.fog.density) * 0.02;

            // Apply continuous rotation based on section
            particleMesh.rotation.y += targetRotSpeedY;
            particleMesh.rotation.x += targetRotSpeedX;

            // 3. Mouse Parallax (Desktop)
            targetX = mouseX * 0.001;
            targetY = mouseY * 0.001;

            if (window.innerWidth > 900) {
                // Move the entire mesh slightly based on mouse
                particleMesh.position.x += (targetX * 10 - particleMesh.position.x) * 0.05;
                // Add vertical float + mouse parallax
                const targetPosY = (Math.sin(elapsedTime * 0.5) * 2) - (targetY * 10);
                particleMesh.position.y += (targetPosY - particleMesh.position.y) * 0.05;
            } else {
                // Mobile: Gentle float + slight extra rotation on scroll
                particleMesh.position.y = Math.sin(elapsedTime * 0.5) * 2;
                particleMesh.rotation.y += (window.scrollY * 0.00001);
            }

            renderer.render(scene, camera);
        };

        animate();
    }
});
