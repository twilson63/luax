// Terminal-style interactive features

// Copy code functionality
function copyCode(button) {
    const codeBlock = button.parentElement;
    const code = codeBlock.querySelector('code');
    const text = code.textContent || code.innerText;
    
    navigator.clipboard.writeText(text).then(() => {
        const originalText = button.textContent;
        button.textContent = 'COPIED';
        button.style.background = '#00ff41';
        button.style.color = '#0a0a0a';
        
        setTimeout(() => {
            button.textContent = originalText;
            button.style.background = 'transparent';
            button.style.color = '#00ff41';
        }, 2000);
    }).catch(err => {
        console.error('Failed to copy text: ', err);
        button.textContent = 'ERROR';
        button.style.background = '#ff4444';
        setTimeout(() => {
            button.textContent = 'COPY';
            button.style.background = 'transparent';
        }, 2000);
    });
}

// Terminal typing effect
function typeWriter(element, text, speed = 50) {
    let i = 0;
    element.innerHTML = '';
    
    function type() {
        if (i < text.length) {
            element.innerHTML += text.charAt(i);
            i++;
            setTimeout(type, speed);
        }
    }
    type();
}

// Matrix rain effect (optional background)
function createMatrixRain() {
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');
    
    canvas.style.position = 'fixed';
    canvas.style.top = '0';
    canvas.style.left = '0';
    canvas.style.width = '100%';
    canvas.style.height = '100%';
    canvas.style.zIndex = '-1';
    canvas.style.opacity = '0.1';
    canvas.style.pointerEvents = 'none';
    
    document.body.appendChild(canvas);
    
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789@#$%^&*(){}[]|\\:";\'<>?,./';
    const fontSize = 14;
    const columns = canvas.width / fontSize;
    const drops = [];
    
    for (let i = 0; i < columns; i++) {
        drops[i] = 1;
    }
    
    function draw() {
        ctx.fillStyle = 'rgba(10, 10, 10, 0.05)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        
        ctx.fillStyle = '#00ff41';
        ctx.font = fontSize + 'px JetBrains Mono';
        
        for (let i = 0; i < drops.length; i++) {
            const text = chars[Math.floor(Math.random() * chars.length)];
            ctx.fillText(text, i * fontSize, drops[i] * fontSize);
            
            if (drops[i] * fontSize > canvas.height && Math.random() > 0.975) {
                drops[i] = 0;
            }
            drops[i]++;
        }
    }
    
    setInterval(draw, 33);
    
    window.addEventListener('resize', () => {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    });
}

// Glitch effect for headers
function addGlitchEffect() {
    const headers = document.querySelectorAll('h1, h2, h3');
    
    headers.forEach(header => {
        header.addEventListener('mouseenter', () => {
            const originalText = header.textContent;
            const glitchChars = '!@#$%^&*()_+-=[]{}|;:,.<>?';
            let glitchText = '';
            
            for (let i = 0; i < originalText.length; i++) {
                if (Math.random() > 0.8 && originalText[i] !== ' ') {
                    glitchText += glitchChars[Math.floor(Math.random() * glitchChars.length)];
                } else {
                    glitchText += originalText[i];
                }
            }
            
            header.textContent = glitchText;
            
            setTimeout(() => {
                header.textContent = originalText;
            }, 100);
        });
    });
}

// Terminal cursor effect
function addCursorEffect() {
    const elements = document.querySelectorAll('.cursor');
    
    elements.forEach(element => {
        setInterval(() => {
            if (element.classList.contains('blink')) {
                element.classList.remove('blink');
            } else {
                element.classList.add('blink');
            }
        }, 500);
    });
}

// Smooth scrolling for navigation links
function smoothScroll() {
    const links = document.querySelectorAll('a[href^="#"]');
    
    links.forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const target = document.querySelector(link.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Initialize all effects when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    // Add glitch effect to headers
    addGlitchEffect();
    
    // Add smooth scrolling
    smoothScroll();
    
    // Add terminal typing effect to hero subtitle
    const heroSubtitle = document.querySelector('.hero-subtitle');
    if (heroSubtitle) {
        const originalText = heroSubtitle.textContent;
        heroSubtitle.classList.add('cursor');
        typeWriter(heroSubtitle, originalText, 80);
    }
    
    // Optional: Enable matrix rain effect (uncomment to enable)
    // createMatrixRain();
    
    // Add loading effect to feature cards
    const featureCards = document.querySelectorAll('.feature-card');
    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.style.opacity = '1';
                entry.target.style.transform = 'translateY(0)';
            }
        });
    });
    
    featureCards.forEach(card => {
        card.style.opacity = '0';
        card.style.transform = 'translateY(20px)';
        card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
        observer.observe(card);
    });
});

// Add terminal prompt to console
console.log(`
██╗  ██╗██╗   ██╗██████╗ ███████╗
██║  ██║╚██╗ ██╔╝██╔══██╗██╔════╝
███████║ ╚████╔╝ ██████╔╝█████╗  
██╔══██║  ╚██╔╝  ██╔═══╝ ██╔══╝  
██║  ██║   ██║   ██║     ███████╗
╚═╝  ╚═╝   ╚═╝   ╚═╝     ╚══════╝

> Lua Script to Executable Packager
> Version: 1.0.3
> Status: ONLINE
> Documentation loaded successfully...

Type 'help' for available commands.
`);

// Easter egg: konami code
let konamiCode = [38, 38, 40, 40, 37, 39, 37, 39, 66, 65];
let konamiIndex = 0;

document.addEventListener('keydown', (e) => {
    if (e.keyCode === konamiCode[konamiIndex]) {
        konamiIndex++;
        if (konamiIndex === konamiCode.length) {
            // Enable matrix rain effect
            createMatrixRain();
            console.log('> MATRIX MODE ACTIVATED');
            konamiIndex = 0;
        }
    } else {
        konamiIndex = 0;
    }
});