/* ============================================
   WINDPAD WEBSITE - ABOUT PAGE JAVASCRIPT
   Roadmap animations and scroll effects
   ============================================ */

// Roadmap Animation
class RoadmapAnimation {
    constructor() {
        this.roadmapItems = document.querySelectorAll('.roadmap-item');
        this.init();
    }
    
    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateItem(entry.target);
                }
            });
        }, {
            threshold: 0.3,
            rootMargin: '0px 0px -50px 0px'
        });
        
        this.roadmapItems.forEach((item, index) => {
            item.classList.add('scroll-reveal');
            item.style.transitionDelay = `${index * 100}ms`;
            observer.observe(item);
        });
    }
    
    animateItem(item) {
        item.style.transform = 'translateX(30px)';
        item.style.opacity = '0';
        
        setTimeout(() => {
            item.style.transition = 'all 0.5s ease';
            item.style.transform = 'translateX(0)';
            item.style.opacity = '1';
        }, 50);
    }
}

// Vision Cards Animation
class VisionCardsAnimation {
    constructor() {
        this.cards = document.querySelectorAll('.principle-card');
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

// Contribute Cards Animation
class ContributeCardsAnimation {
    constructor() {
        this.cards = document.querySelectorAll('.contribute-card');
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

// Story Section Animation
class StoryAnimation {
    constructor() {
        this.storySection = document.querySelector('.story-section');
        this.init();
    }
    
    init() {
        if (!this.storySection) return;
        
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateStory();
                }
            });
        }, {
            threshold: 0.3
        });
        
        observer.observe(this.storySection);
    }
    
    animateStory() {
        const storyContent = this.storySection.querySelector('.story-content');
        const storyVisual = this.storySection.querySelector('.story-visual');
        
        if (storyContent) {
            storyContent.style.transform = 'translateX(-30px)';
            storyContent.style.opacity = '0';
            
            setTimeout(() => {
                storyContent.style.transition = 'all 0.6s ease';
                storyContent.style.transform = 'translateX(0)';
                storyContent.style.opacity = '1';
            }, 100);
        }
        
        if (storyVisual) {
            storyVisual.style.transform = 'translateX(30px)';
            storyVisual.style.opacity = '0';
            
            setTimeout(() => {
                storyVisual.style.transition = 'all 0.6s ease';
                storyVisual.style.transform = 'translateX(0)';
                storyVisual.style.opacity = '1';
            }, 200);
        }
    }
}

// GitHub Button Animation
class GitHubButtonAnimation {
    constructor() {
        this.githubBtns = document.querySelectorAll('.btn[href*="github.com"]');
        this.init();
    }
    
    init() {
        this.githubBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                // Add click animation
                btn.style.transform = 'scale(0.95)';
                
                setTimeout(() => {
                    btn.style.transform = '';
                }, 150);
            });
        });
    }
}

// Counter Animation for Stats
class CounterAnimation {
    constructor() {
        this.stats = document.querySelectorAll('.stat-value');
        this.init();
    }
    
    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.animateCounter(entry.target);
                    observer.unobserve(entry.target);
                }
            });
        }, {
            threshold: 0.5
        });
        
        this.stats.forEach(stat => observer.observe(stat));
    }
    
    animateCounter(element) {
        const target = element.textContent;
        const duration = 2000;
        const steps = 60;
        const stepDuration = duration / steps;
        
        let current = 0;
        const increment = this.parseValue(target) / steps;
        
        const update = () => {
            current += increment;
            if (current >= this.parseValue(target)) {
                element.textContent = target;
            } else {
                element.textContent = this.formatValue(current, target);
                setTimeout(update, stepDuration);
            }
        };
        
        update();
    }
    
    parseValue(value) {
        if (value.includes('K')) return parseFloat(value) * 1000;
        if (value.includes('M')) return parseFloat(value) * 1000000;
        return parseFloat(value);
    }
    
    formatValue(current, target) {
        if (target.includes('K')) return (current / 1000).toFixed(1) + 'K';
        if (target.includes('M')) return (current / 1000000).toFixed(1) + 'M';
        return Math.round(current);
    }
}

// Parallax Effect for Background
class ParallaxEffect {
    constructor() {
        this.init();
    }
    
    init() {
        window.addEventListener('scroll', () => {
            const scrolled = window.pageYOffset;
            const header = document.querySelector('.about-header');
            
            if (header) {
                const rate = scrolled * 0.3;
                header.style.transform = `translateY(${rate}px)`;
            }
        });
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new RoadmapAnimation();
    new VisionCardsAnimation();
    new ContributeCardsAnimation();
    new StoryAnimation();
    new GitHubButtonAnimation();
    new CounterAnimation();
    new ParallaxEffect();
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
