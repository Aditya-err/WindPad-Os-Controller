/* ============================================
   WINDPAD WEBSITE - HOW IT WORKS PAGE JAVASCRIPT
   Technical flow animations
   ============================================ */

// Flow Animation Controller
class FlowAnimation {
    constructor() {
        this.flowSteps = document.querySelectorAll('.flow-step');
        this.connections = document.querySelectorAll('.flow-connection');
        this.init();
    }
    
    init() {
        this.animateFlow();
        this.initInteractions();
    }
    
    animateFlow() {
        // Animate flow steps sequentially
        this.flowSteps.forEach((step, index) => {
            step.style.opacity = '0';
            step.style.transform = 'translateY(20px)';
            
            setTimeout(() => {
                step.style.transition = 'all 0.6s ease';
                step.style.opacity = '1';
                step.style.transform = 'translateY(0)';
            }, index * 300);
        });
        
        // Animate connections
        this.connections.forEach((connection, index) => {
            const pulse = connection.querySelector('.connection-pulse');
            if (pulse) {
                pulse.style.animationDelay = `${index * 0.5}s`;
            }
        });
    }
    
    initInteractions() {
        // Add hover effects to flow steps
        this.flowSteps.forEach(step => {
            step.addEventListener('mouseenter', () => {
                const device = step.querySelector('.flow-device');
                if (device) {
                    device.style.transform = 'scale(1.1)';
                }
            });
            
            step.addEventListener('mouseleave', () => {
                const device = step.querySelector('.flow-device');
                if (device) {
                    device.style.transform = 'scale(1)';
                }
            });
        });
        
        // Initialize scroll animations
        this.initScrollAnimations();
    }
    
    initScrollAnimations() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('visible');
                }
            });
        }, {
            threshold: 0.2
        });
        
        // Observe detail cards
        const detailCards = document.querySelectorAll('.detail-card');
        detailCards.forEach(card => {
            card.classList.add('scroll-reveal');
            observer.observe(card);
        });
        
        // Observe comparison table
        const comparisonTable = document.querySelector('.comparison-table');
        if (comparisonTable) {
            comparisonTable.classList.add('scroll-reveal');
            observer.observe(comparisonTable);
        }
        
        // Observe code block
        const codeBlock = document.querySelector('.code-block');
        if (codeBlock) {
            codeBlock.classList.add('scroll-reveal');
            observer.observe(codeBlock);
        }
    }
}

// Code Syntax Highlighting
class CodeHighlighter {
    constructor() {
        this.codeBlocks = document.querySelectorAll('.code-content code');
        this.init();
    }
    
    init() {
        this.codeBlocks.forEach(block => {
            this.highlightCode(block);
        });
    }
    
    highlightCode(block) {
        let code = block.innerHTML;
        
        // Highlight comments
        code = code.replace(/(\/\/.*$)/gm, '<span class="comment">$1</span>');
        
        // Highlight keywords
        const keywords = ['val', 'var', 'fun', 'class', 'object', 'interface', 'if', 'else', 'when', 'for', 'while', 'return', 'true', 'false', 'null'];
        keywords.forEach(keyword => {
            const regex = new RegExp(`\\b${keyword}\\b`, 'g');
            code = code.replace(regex, `<span class="keyword">${keyword}</span>`);
        });
        
        // Highlight strings
        code = code.replace(/(".*?")/g, '<span class="string">$1</span>');
        
        // Highlight functions
        code = code.replace(/(\w+)(\()/g, '<span class="function">$1</span>$2');
        
        block.innerHTML = code;
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new FlowAnimation();
    new CodeHighlighter();
});

// Parallax effect for header
window.addEventListener('scroll', () => {
    const header = document.querySelector('.how-header');
    if (header) {
        const scrolled = window.pageYOffset;
        const rate = scrolled * 0.3;
        header.style.transform = `translateY(${rate}px)`;
    }
});
