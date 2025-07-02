// Smooth scroll for navigation links
document.addEventListener('DOMContentLoaded', function() {
    // Navigation smooth scroll
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);
            if (targetElement) {
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });

    // Scroll progress indicator
    const createScrollIndicator = () => {
        const indicator = document.createElement('div');
        indicator.className = 'scroll-indicator';
        const progress = document.createElement('div');
        progress.className = 'scroll-progress';
        indicator.appendChild(progress);
        document.body.insertBefore(indicator, document.body.firstChild);
        return progress;
    };

    const progressBar = createScrollIndicator();

    // Update scroll progress
    const updateScrollProgress = () => {
        const scrollTop = window.pageYOffset;
        const docHeight = document.documentElement.scrollHeight - window.innerHeight;
        const scrollPercent = (scrollTop / docHeight) * 100;
        progressBar.style.width = scrollPercent + '%';
    };

    window.addEventListener('scroll', updateScrollProgress);

    // Active navigation highlighting
    const sections = document.querySelectorAll('section[id]');
    const observerOptions = {
        rootMargin: '-100px 0px -50% 0px',
        threshold: 0.1
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                // Remove active class from all nav links
                navLinks.forEach(link => {
                    link.classList.remove('active');
                });
                
                // Add active class to current section's nav link
                const activeLink = document.querySelector(`.nav-link[href="#${entry.target.id}"]`);
                if (activeLink) {
                    activeLink.classList.add('active');
                }
            }
        });
    }, observerOptions);

    sections.forEach(section => {
        observer.observe(section);
    });

    // Animate cards on scroll
    const animateOnScroll = () => {
        const cards = document.querySelectorAll('.overview-card, .feature-card, .tech-category, .api-card, .deployment-card');
        
        const cardObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'translateY(0)';
                }
            });
        }, {
            threshold: 0.1,
            rootMargin: '0px 0px -50px 0px'
        });

        cards.forEach(card => {
            card.style.opacity = '0';
            card.style.transform = 'translateY(30px)';
            card.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            cardObserver.observe(card);
        });
    };

    animateOnScroll();

    // Tech stack interactive features
    const techItems = document.querySelectorAll('.tech-item');
    techItems.forEach(item => {
        item.addEventListener('mouseenter', function() {
            this.style.transform = 'scale(1.02)';
            this.style.transition = 'transform 0.2s ease';
        });
        
        item.addEventListener('mouseleave', function() {
            this.style.transform = 'scale(1)';
        });
    });

    // Code block copy functionality
    const addCopyButtons = () => {
        const codeBlocks = document.querySelectorAll('.code-block pre');
        codeBlocks.forEach(block => {
            const button = document.createElement('button');
            button.innerHTML = '📋 コピー';
            button.className = 'copy-button';
            button.style.cssText = `
                position: absolute;
                top: 10px;
                right: 10px;
                background: #4a5568;
                color: white;
                border: none;
                padding: 5px 10px;
                border-radius: 4px;
                font-size: 12px;
                cursor: pointer;
                opacity: 0.7;
                transition: opacity 0.3s ease;
            `;
            
            // Make parent relative for absolute positioning
            block.parentElement.style.position = 'relative';
            
            button.addEventListener('click', () => {
                const code = block.textContent;
                navigator.clipboard.writeText(code).then(() => {
                    button.innerHTML = '✅ コピー済み';
                    setTimeout(() => {
                        button.innerHTML = '📋 コピー';
                    }, 2000);
                });
            });
            
            button.addEventListener('mouseenter', () => {
                button.style.opacity = '1';
            });
            
            button.addEventListener('mouseleave', () => {
                button.style.opacity = '0.7';
            });
            
            block.parentElement.appendChild(button);
        });
    };

    addCopyButtons();

    // Search functionality
    const addSearchFeature = () => {
        const searchContainer = document.createElement('div');
        searchContainer.innerHTML = `
            <div style="position: fixed; top: 100px; right: 20px; z-index: 1000;">
                <input type="text" id="search-input" placeholder="検索..." 
                       style="padding: 10px; border: 1px solid #ccc; border-radius: 4px; width: 200px; display: none;">
                <button id="search-toggle" style="background: #667eea; color: white; border: none; padding: 10px; border-radius: 4px; cursor: pointer;">🔍</button>
            </div>
        `;
        document.body.appendChild(searchContainer);

        const searchInput = document.getElementById('search-input');
        const searchToggle = document.getElementById('search-toggle');

        searchToggle.addEventListener('click', () => {
            if (searchInput.style.display === 'none') {
                searchInput.style.display = 'inline-block';
                searchInput.focus();
            } else {
                searchInput.style.display = 'none';
                clearHighlights();
            }
        });

        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase();
            if (query.length > 2) {
                highlightText(query);
            } else {
                clearHighlights();
            }
        });
    };

    const highlightText = (query) => {
        clearHighlights();
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );

        const textNodes = [];
        let node;
        while (node = walker.nextNode()) {
            if (node.nodeValue.toLowerCase().includes(query)) {
                textNodes.push(node);
            }
        }

        textNodes.forEach(textNode => {
            const parent = textNode.parentNode;
            if (parent.className.includes('highlight')) return;

            const regex = new RegExp(`(${query})`, 'gi');
            const highlighted = textNode.nodeValue.replace(regex, '<mark class="highlight">$1</mark>');
            const span = document.createElement('span');
            span.innerHTML = highlighted;
            parent.replaceChild(span, textNode);
        });
    };

    const clearHighlights = () => {
        const highlights = document.querySelectorAll('.highlight');
        highlights.forEach(highlight => {
            const parent = highlight.parentNode;
            parent.replaceChild(document.createTextNode(highlight.textContent), highlight);
            parent.normalize();
        });
    };

    addSearchFeature();

    // Mobile menu toggle
    const addMobileMenu = () => {
        if (window.innerWidth <= 768) {
            const navMenu = document.querySelector('.nav-menu');
            const navContainer = document.querySelector('.nav-container');
            
            const menuToggle = document.createElement('button');
            menuToggle.innerHTML = '☰';
            menuToggle.className = 'mobile-menu-toggle';
            menuToggle.style.cssText = `
                background: none;
                border: none;
                color: white;
                font-size: 1.5rem;
                cursor: pointer;
                display: none;
            `;
            
            if (window.innerWidth <= 768) {
                menuToggle.style.display = 'block';
                navContainer.appendChild(menuToggle);
                navMenu.style.display = 'none';
                
                menuToggle.addEventListener('click', () => {
                    if (navMenu.style.display === 'none') {
                        navMenu.style.display = 'flex';
                        menuToggle.innerHTML = '✕';
                    } else {
                        navMenu.style.display = 'none';
                        menuToggle.innerHTML = '☰';
                    }
                });
            }
        }
    };

    addMobileMenu();
    window.addEventListener('resize', addMobileMenu);

    // Performance optimization: Lazy load images if any
    const lazyLoadImages = () => {
        const images = document.querySelectorAll('img[data-src]');
        const imageObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    const img = entry.target;
                    img.src = img.dataset.src;
                    img.removeAttribute('data-src');
                    imageObserver.unobserve(img);
                }
            });
        });

        images.forEach(img => imageObserver.observe(img));
    };

    lazyLoadImages();

    // Add CSS for highlighted search results
    const style = document.createElement('style');
    style.textContent = `
        .highlight {
            background-color: #ffeb3b;
            padding: 2px 4px;
            border-radius: 2px;
        }
        
        .nav-link.active {
            opacity: 1;
            font-weight: 600;
            text-decoration: underline;
        }
        
        @media (max-width: 768px) {
            .mobile-menu-toggle {
                display: block !important;
            }
        }
    `;
    document.head.appendChild(style);

    console.log('まちなか保健室アプリ ドキュメントサイト initialized successfully! 🚀');
});
