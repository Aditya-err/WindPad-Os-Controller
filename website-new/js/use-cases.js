/* ============================================
   WINDPAD WEBSITE - USE CASES PAGE JAVASCRIPT
   Scroll animations and interactions
   ============================================ */

// Use Cases Scroll Animations
class UseCasesAnimations {
    constructor() {
        this.stories = document.querySelectorAll('.use-case-story');
        this.init();
    }
    
    init() {
        this.initScrollAnimations();
        this.initParallax();
        this.initInteractions();
    }
    
    initScrollAnimations() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -100px 0px'
        });
        
        this.stories.forEach(story => {
            story.classList.add('scroll-reveal');
            observer.observe(story);
        });
    }
    
    initParallax() {
        const storyVisuals = document.querySelectorAll('.story-visual');
        
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            
            storyVisuals.forEach(visual => {
                const rect = visual.getBoundingClientRect();
                const speed = 0.1;
                
                if (rect.top < window.innerHeight && rect.bottom > 0) {
                    const yPos = (rect.top - window.innerHeight / 2) * speed;
                    visual.style.transform = `translateY(${yPos}px)`;
                }
            });
        });
    }
    
    initInteractions() {
        // Add hover effects to story cards
        this.stories.forEach(story => {
            story.addEventListener('mouseenter', () => {
                const visual = story.querySelector('.story-visual');
                if (visual) {
                    visual.style.transform = 'scale(1.05)';
                }
            });
            
            story.addEventListener('mouseleave', () => {
                const visual = story.querySelector('.story-visual');
                if (visual) {
                    visual.style.transform = 'scale(1)';
                }
            });
        });
        
        // Animate story numbers on scroll
        this.animateStoryNumbers();
    }
    
    animateStoryNumbers() {
        const storyNumbers = document.querySelectorAll('.story-number');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const number = entry.target;
                    const finalValue = parseInt(number.textContent);
                    
                    let current = 0;
                    const increment = finalValue / 30;
                    const duration = 1000;
                    const stepTime = duration / 30;
                    
                    const counter = setInterval(() => {
                        current += increment;
                        if (current >= finalValue) {
                            number.textContent = finalValue.toString().padStart(2, '0');
                            clearInterval(counter);
                        } else {
                            number.textContent = Math.floor(current).toString().padStart(2, '0');
                        }
                    }, stepTime);
                    
                    observer.unobserve(number);
                }
            });
        }, {
            threshold: 0.5
        });
        
        storyNumbers.forEach(number => {
            observer.observe(number);
        });
    }
}

// Feature Tags Animation
class FeatureTagsAnimation {
    constructor() {
        this.featureTags = document.querySelectorAll('.story-feature');
        this.init();
    }
    
    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const tags = entry.target.querySelectorAll('.story-feature');
                    tags.forEach((tag, index) => {
                        setTimeout(() => {
                            tag.style.opacity = '1';
                            tag.style.transform = 'translateY(0)';
                        }, index * 100);
                    });
                }
            });
        }, {
            threshold: 0.5
        });
        
        this.featureTags.forEach(tag => {
            tag.style.opacity = '0';
            tag.style.transform = 'translateY(10px)';
            tag.style.transition = 'all 0.3s ease';
        });
        
        const storyContents = document.querySelectorAll('.story-content');
        storyContents.forEach(content => {
            observer.observe(content);
        });
    }
}

// Visual Element Animations
class VisualAnimations {
    constructor() {
        this.init();
    }
    
    init() {
        this.animateCodeWindow();
        this.animateTimeline();
        this.animatePresentation();
        this.animateWorkflow();
    }
    
    animateCodeWindow() {
        const codeLines = document.querySelectorAll('.code-line');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    codeLines.forEach((line, index) => {
                        setTimeout(() => {
                            line.style.opacity = '1';
                            line.style.transform = 'translateX(0)';
                        }, index * 200);
                    });
                }
            });
        }, {
            threshold: 0.5
        });
        
        codeLines.forEach(line => {
            line.style.opacity = '0';
            line.style.transform = 'translateX(-20px)';
            line.style.transition = 'all 0.3s ease';
        });
        
        const codeWindow = document.querySelector('.code-window');
        if (codeWindow) {
            observer.observe(codeWindow);
        }
    }
    
    animateTimeline() {
        const timelinePlayhead = document.querySelector('.timeline-playhead');
        
        if (timelinePlayhead) {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        let position = 0;
                        const animate = () => {
                            position += 0.5;
                            if (position > 100) position = 0;
                            timelinePlayhead.style.left = position + '%';
                            requestAnimationFrame(animate);
                        };
                        animate();
                        observer.unobserve(entry.target);
                    }
                });
            }, {
                threshold: 0.5
            });
            
            const creativeWorkspace = document.querySelector('.creative-workspace');
            if (creativeWorkspace) {
                observer.observe(creativeWorkspace);
            }
        }
    }
    
    animatePresentation() {
        const presentationSlide = document.querySelector('.presentation-slide');
        
        if (presentationSlide) {
            const observer = new IntersectionObserver((entries) => {
                entries.forEach(entry => {
                    if (entry.isIntersecting) {
                        let scale = 1;
                        let direction = 1;
                        
                        const animate = () => {
                            scale += direction * 0.001;
                            if (scale > 1.02 || scale < 0.98) direction *= -1;
                            presentationSlide.style.transform = `scale(${scale})`;
                            requestAnimationFrame(animate);
                        };
                        animate();
                        observer.unobserve(entry.target);
                    }
                });
            }, {
                threshold: 0.5
            });
            
            observer.observe(presentationSlide);
        }
    }
    
    animateWorkflow() {
        const workflowNodes = document.querySelectorAll('.workflow-node');
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    workflowNodes.forEach((node, index) => {
                        setTimeout(() => {
                            node.style.opacity = '1';
                            node.style.transform = 'scale(1)';
                        }, index * 300);
                    });
                }
            });
        }, {
            threshold: 0.5
        });
        
        workflowNodes.forEach(node => {
            node.style.opacity = '0';
            node.style.transform = 'scale(0.8)';
            node.style.transition = 'all 0.5s ease';
        });
        
        const workflowDiagram = document.querySelector('.workflow-diagram');
        if (workflowDiagram) {
            observer.observe(workflowDiagram);
        }
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new UseCasesAnimations();
    new FeatureTagsAnimation();
    new VisualAnimations();
});

// Smooth scroll for internal links
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
