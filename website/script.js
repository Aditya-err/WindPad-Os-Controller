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
                target.scrollIntoView({
                    behavior: 'smooth'
                });
            }
        });
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
        const particlesCount = 1500;
        
        const posArray = new Float32Array(particlesCount * 3);
        const colorsArray = new Float32Array(particlesCount * 3);

        // Create a circular texture dynamically for soft particles
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
        const color3 = new THREE.Color(0x10b981); // Emerald Green (Added as requested)

        for(let i = 0; i < particlesCount * 3; i+=3) {
            // Position
            posArray[i] = (Math.random() - 0.5) * 100;     // x
            posArray[i+1] = (Math.random() - 0.5) * 100;   // y
            posArray[i+2] = (Math.random() - 0.5) * 100;   // z

            // Colors (mix of blue, purple, and green)
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

        // Create custom shader-like material for soft glowing dots (no more squares!)
        const particlesMaterial = new THREE.PointsMaterial({
            size: 0.3, // Slightly larger to show the soft texture
            vertexColors: true,
            transparent: true,
            opacity: 0.8,
            map: createCircleTexture(), // Apply the circle texture
            blending: THREE.AdditiveBlending,
            depthWrite: false
        });

        const particleMesh = new THREE.Points(particlesGeometry, particlesMaterial);
        scene.add(particleMesh);

        // Mouse interaction variables
        let mouseX = 0;
        let mouseY = 0;
        let targetX = 0;
        let targetY = 0;
        const windowHalfX = window.innerWidth / 2;
        const windowHalfY = window.innerHeight / 2;

        document.addEventListener('mousemove', (event) => {
            mouseX = (event.clientX - windowHalfX);
            mouseY = (event.clientY - windowHalfY);
        });

        // Resize handler
        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });

        // Animation Loop
        const clock = new THREE.Clock();

        const animate = () => {
            requestAnimationFrame(animate);
            const elapsedTime = clock.getElapsedTime();

            targetX = mouseX * 0.001;
            targetY = mouseY * 0.001;

            // Rotate particle mesh slowly
            particleMesh.rotation.y += 0.001;
            particleMesh.rotation.x += 0.0005;

            // Interact with mouse (Parallax)
            particleMesh.rotation.y += 0.05 * (targetX - particleMesh.rotation.y);
            particleMesh.rotation.x += 0.05 * (targetY - particleMesh.rotation.x);

            // Subtle floating motion
            particleMesh.position.y = Math.sin(elapsedTime * 0.5) * 2;

            renderer.render(scene, camera);
        };

        animate();
    }

    // --- Custom Cursor ---
    const cursorDot = document.createElement('div');
    cursorDot.classList.add('cursor-dot');
    document.body.appendChild(cursorDot);

    const cursorOutline = document.createElement('div');
    cursorOutline.classList.add('cursor-outline');
    document.body.appendChild(cursorOutline);

    window.addEventListener('mousemove', (e) => {
        const posX = e.clientX;
        const posY = e.clientY;
        
        cursorDot.style.left = `${posX}px`;
        cursorDot.style.top = `${posY}px`;

        // Smooth follow for outline
        cursorOutline.animate({
            left: `${posX}px`,
            top: `${posY}px`
        }, { duration: 500, fill: "forwards" });
    });

    // Add hover effect for links and buttons
    document.querySelectorAll('a, button, .btn').forEach(el => {
        el.addEventListener('mouseenter', () => {
            cursorOutline.classList.add('hovered');
            cursorDot.classList.add('hovered');
        });
        el.addEventListener('mouseleave', () => {
            cursorOutline.classList.remove('hovered');
            cursorDot.classList.remove('hovered');
        });
    });

    // --- Interactive Particle Text ---
    const textCanvas = document.getElementById('text-canvas');
    if (textCanvas) {
        const ctx = textCanvas.getContext('2d', { willReadFrequently: true });
        let particleArray = [];
        let mouseText = { x: null, y: null, radius: 80 };

        const initCanvas = () => {
            textCanvas.width = textCanvas.parentElement.clientWidth;
            textCanvas.height = 250;
            
            // Draw text
            ctx.fillStyle = 'white';
            const fontSize = Math.min(window.innerWidth / 5, 150);
            ctx.font = `bold ${fontSize}px Inter`;
            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';
            ctx.fillText('WindPad', textCanvas.width / 2, textCanvas.height / 2);
            
            const textCoordinates = ctx.getImageData(0, 0, textCanvas.width, textCanvas.height);
            particleArray = [];
            
            // Iterate over pixels to create dots
            for (let y = 0, y2 = textCoordinates.height; y < y2; y += 5) {
                for (let x = 0, x2 = textCoordinates.width; x < x2; x += 5) {
                    const index = (y * textCoordinates.width + x) * 4 + 3;
                    if (textCoordinates.data[index] > 128) {
                        let positionX = x;
                        let positionY = y;
                        particleArray.push(new Particle(positionX, positionY));
                    }
                }
            }
        };

        class Particle {
            constructor(x, y) {
                this.x = x;
                this.y = y;
                this.size = 3.5; // Bigger dots
                this.baseX = x;
                this.baseY = y;
                this.density = (Math.random() * 30) + 1;
                
                // Color variation (White, 50% opacity)
                this.color = 'rgba(255, 255, 255, 0.5)';
            }
            draw() {
                ctx.fillStyle = this.color;
                ctx.beginPath();
                ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
                ctx.closePath();
                ctx.fill();
            }
            update() {
                let dx = mouseText.x - this.x;
                let dy = mouseText.y - this.y;
                let distance = Math.sqrt(dx * dx + dy * dy);
                let forceDirectionX = dx / distance;
                let forceDirectionY = dy / distance;
                let maxDistance = mouseText.radius;
                let force = (maxDistance - distance) / maxDistance;
                let directionX = forceDirectionX * force * this.density;
                let directionY = forceDirectionY * force * this.density;

                if (distance < maxDistance && mouseText.x != null) {
                    this.x -= directionX;
                    this.y -= directionY;
                } else {
                    if (this.x !== this.baseX) {
                        let dx = this.x - this.baseX;
                        this.x -= dx / 10;
                    }
                    if (this.y !== this.baseY) {
                        let dy = this.y - this.baseY;
                        this.y -= dy / 10;
                    }
                }
            }
        }

        textCanvas.addEventListener('mousemove', (event) => {
            const rect = textCanvas.getBoundingClientRect();
            mouseText.x = event.clientX - rect.left;
            mouseText.y = event.clientY - rect.top;
        });

        textCanvas.addEventListener('mouseleave', () => {
            mouseText.x = null;
            mouseText.y = null;
        });

        const animateText = () => {
            ctx.clearRect(0, 0, textCanvas.width, textCanvas.height);
            for (let i = 0; i < particleArray.length; i++) {
                particleArray[i].draw();
                particleArray[i].update();
            }
            requestAnimationFrame(animateText);
        }

        // Slight delay to ensure fonts are loaded
        setTimeout(() => {
            initCanvas();
            animateText();
        }, 500);
        
        let resizeTimer;
        window.addEventListener('resize', () => {
            clearTimeout(resizeTimer);
            resizeTimer = setTimeout(initCanvas, 200);
        });
    }
});
