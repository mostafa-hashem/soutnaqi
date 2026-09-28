document.addEventListener('DOMContentLoaded', () => {
    // 1. Prevent default action on Coming Soon buttons
    const comingSoonBtns = document.querySelectorAll('.coming-soon-btn');
    comingSoonBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            // Optional: Add a small shake animation or toast notification
            btn.style.transform = 'scale(0.95)';
            setTimeout(() => {
                btn.style.transform = '';
            }, 150);
        });
    });

    // 2. Intersection Observer for Scroll Animations
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.15
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('show');
                // Optional: Unobserve if you only want the animation to happen once
                // observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // Select all elements with the 'hidden' class
    const hiddenElements = document.querySelectorAll('.hidden');
    hiddenElements.forEach(el => observer.observe(el));

    // 3. FAQ Accordion Logic
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
        const questionBtn = item.querySelector('.faq-question');
        questionBtn.addEventListener('click', () => {
            const isActive = item.classList.contains('active');
            
            // Close all items
            faqItems.forEach(faq => {
                faq.classList.remove('active');
                faq.querySelector('.faq-answer').style.maxHeight = null;
            });

            // Open if wasn't active
            if (!isActive) {
                item.classList.add('active');
                const answer = item.querySelector('.faq-answer');
                answer.style.maxHeight = answer.scrollHeight + "px";
            }
        });
    });

    // 4. Newsletter Form Logic (Simulated)
    const form = document.getElementById('notify-form');
    const formMsg = document.getElementById('form-msg');
    
    if (form) {
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            const emailInput = form.querySelector('input[type="email"]');
            const btn = form.querySelector('button');
            
            // UI state
            btn.textContent = 'جاري التسجيل...';
            btn.style.opacity = '0.7';
            
            // Simulate network request
            setTimeout(() => {
                emailInput.value = '';
                btn.textContent = 'أخبرني عند الإطلاق';
                btn.style.opacity = '1';
                formMsg.textContent = 'تم تسجيل بريدك بنجاح! سنبقيك على اطلاع.';
                
                // Hide message after 5 seconds
                setTimeout(() => {
                    formMsg.textContent = '';
                }, 5000);
            }, 1500);
        });
    }
});
