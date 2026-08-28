// Intersection Observer for scroll animations
document.addEventListener('DOMContentLoaded', () => {
    const reveals = document.querySelectorAll('.reveal');

    const revealOnScroll = () => {
        const windowHeight = window.innerHeight;
        const elementVisible = 100;

        reveals.forEach((reveal) => {
            const elementTop = reveal.getBoundingClientRect().top;
            if (elementTop < windowHeight - elementVisible) {
                reveal.classList.add('active');
            }
        });
    };

    // Initial check
    revealOnScroll();

    // Check on scroll
    window.addEventListener('scroll', revealOnScroll);

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

            targetX = mouseX * 0.001;
            targetY = mouseY * 0.001;

            particleMesh.rotation.y += 0.001;
            particleMesh.rotation.x += 0.0005;

            // Only apply parallax if not on mobile (touch devices don't have mousemove generally)
            if (window.innerWidth > 900) {
                particleMesh.rotation.y += 0.05 * (targetX - particleMesh.rotation.y);
                particleMesh.rotation.x += 0.05 * (targetY - particleMesh.rotation.x);
            }

            particleMesh.position.y = Math.sin(elapsedTime * 0.5) * 2;

            renderer.render(scene, camera);
        };

        animate();
    }
});
