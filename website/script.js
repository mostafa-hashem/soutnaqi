const translations = {
    ar: {
        nav_features: "المميزات",
        hero_title: 'إزالة <span class="gradient-text">الموسيقى</span> بضغطة زر',
        hero_subtitle: 'تطبيق "صوت نقي" يقوم بعزل وإزالة الموسيقى من ملفات الصوت والفيديو بكل سهولة وسرعة، مع الحفاظ على جودة الصوت البشري النقية.',
        btn_soon: "قريباً - Coming Soon",
        mockup_title: "جاري العزل...",
        mockup_subtitle: "يتم الآن إزالة الموسيقى",
        features_title: 'مميزات <span class="gradient-text">البرنامج</span>',
        f1_title: "عزل الموسيقى",
        f1_desc: "إزالة الموسيقى من الصوت والفيديو بدقة عالية بضغطة زر.",
        f2_title: "أداء سريع ومستقر",
        f2_desc: "سرعة فائقة في المعالجة للحصول على النتيجة في ثوانٍ.",
        f3_title: "واجهة سهلة",
        f3_desc: "تصميم بسيط ومريح للعين لتجربة استخدام سلسة.",
        steps_title: 'كيف <span class="gradient-text">نعمل؟</span>',
        s1_title: "اختر الملف",
        s1_desc: "قم باختيار ملف الصوت أو الفيديو من هاتفك.",
        s2_title: "اعزل الموسيقى",
        s2_desc: "بضغطة زر واحدة، سيقوم التطبيق بعزل وإزالة الموسيقى.",
        s3_title: "احفظ النتيجة",
        s3_desc: "احفظ المقطع الصوتي النقي وشاركه مع من تحب.",
        faq_title: 'الأسئلة <span class="gradient-text">الشائعة</span>',
        faq1_q: "هل يدعم التطبيق عزل الموسيقى من الفيديو؟",
        faq1_a: "نعم، يمكنك اختيار مقطع فيديو وسيقوم التطبيق بفصل الموسيقى عنه واستخراج الصوت النقي.",
        faq2_q: "متى سيتم إطلاق التطبيق؟",
        faq2_a: "نحن في المراحل النهائية من المراجعة، وسيتوفر التطبيق قريباً جداً على متجري جوجل بلاي وآبل ستور.",
        faq3_q: "هل يمكنني حفظ الملف بعد العزل؟",
        faq3_a: "بالتأكيد! يمكنك حفظ الملف الصوتي النقي على جهازك أو مشاركته مباشرة.",
        cta_title: "كن أول من يصله جديدنا!",
        cta_desc: "انضم لقائمتنا البريدية لنخبرك فور إطلاق التطبيق رسمياً.",
        cta_placeholder: "أدخل بريدك الإلكتروني...",
        cta_btn: "أخبرني عند الإطلاق",
        cta_loading: "جاري التسجيل...",
        cta_success: "تم تسجيل بريدك بنجاح! سنبقيك على اطلاع.",
        logo_text: "صوت نقي",
        footer_privacy: "سياسة الخصوصية",
        footer_rights: "&copy; 2026 جميع الحقوق محفوظة."
    },
    en: {
        nav_features: "Features",
        hero_title: 'Remove <span class="gradient-text">Music</span> in 1-Click',
        hero_subtitle: 'Sout Naqi effortlessly isolates and removes music from your audio and video files, preserving pure human voice quality.',
        btn_soon: "Coming Soon",
        mockup_title: "Isolating...",
        mockup_subtitle: "Removing music now",
        features_title: 'App <span class="gradient-text">Features</span>',
        f1_title: "Music Isolation",
        f1_desc: "Remove music from audio and video with high precision in just one click.",
        f2_title: "Fast & Stable",
        f2_desc: "Lightning-fast processing to get your results in seconds.",
        f3_title: "Easy to Use",
        f3_desc: "Simple and intuitive design for a smooth user experience.",
        steps_title: 'How it <span class="gradient-text">Works?</span>',
        s1_title: "Select File",
        s1_desc: "Choose an audio or video file from your device.",
        s2_title: "Remove Music",
        s2_desc: "With a single click, the app will isolate and remove the music.",
        s3_title: "Save Result",
        s3_desc: "Save the pure audio and share it instantly.",
        faq_title: 'Frequently Asked <span class="gradient-text">Questions</span>',
        faq1_q: "Does the app support videos?",
        faq1_a: "Yes, you can select a video file and the app will remove the music and extract the pure voice.",
        faq2_q: "When will the app be released?",
        faq2_a: "We are in the final review stages. It will be available very soon on Google Play and App Store.",
        faq3_q: "Can I save the file after isolation?",
        faq3_a: "Absolutely! You can save the pure audio file to your device or share it directly.",
        cta_title: "Be the First to Know!",
        cta_desc: "Join our newsletter to get notified as soon as we launch.",
        cta_placeholder: "Enter your email...",
        cta_btn: "Notify Me",
        cta_loading: "Registering...",
        cta_success: "Email registered successfully! We'll keep you updated.",
        logo_text: "Sout Naqi",
        footer_privacy: "Privacy Policy",
        footer_rights: "&copy; 2026 All rights reserved."
    }
};

let currentLang = 'ar';

document.addEventListener('DOMContentLoaded', () => {
    // 1. Language Toggle Logic
    const langBtn = document.getElementById('langToggle');
    const htmlTag = document.documentElement;
    const emailInput = document.getElementById('emailInput');

    function setLanguage(lang) {
        currentLang = lang;
        htmlTag.setAttribute('lang', lang);
        htmlTag.setAttribute('dir', lang === 'ar' ? 'rtl' : 'ltr');
        langBtn.textContent = lang === 'ar' ? 'English' : 'عربي';

        // Update all text elements
        const elements = document.querySelectorAll('[data-i18n]');
        elements.forEach(el => {
            const key = el.getAttribute('data-i18n');
            if (translations[lang][key]) {
                el.innerHTML = translations[lang][key];
            }
        });

        // Update placeholder
        if(emailInput) {
            emailInput.setAttribute('placeholder', translations[lang].cta_placeholder);
        }
    }

    langBtn.addEventListener('click', () => {
        setLanguage(currentLang === 'ar' ? 'en' : 'ar');
    });

    // 2. Prevent default action on Coming Soon buttons
    const comingSoonBtns = document.querySelectorAll('.coming-soon-btn');
    comingSoonBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            btn.style.transform = 'scale(0.95)';
            setTimeout(() => {
                btn.style.transform = '';
            }, 150);
        });
    });

    // 3. Intersection Observer for Scroll Animations
    const observerOptions = {
        root: null,
        rootMargin: '0px',
        threshold: 0.15
    };

    const observer = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('show');
            }
        });
    }, observerOptions);

    const hiddenElements = document.querySelectorAll('.hidden');
    hiddenElements.forEach(el => observer.observe(el));

    // 4. FAQ Accordion Logic
    const faqItems = document.querySelectorAll('.faq-item');
    faqItems.forEach(item => {
        const questionBtn = item.querySelector('.faq-question');
        questionBtn.addEventListener('click', () => {
            const isActive = item.classList.contains('active');
            
            faqItems.forEach(faq => {
                faq.classList.remove('active');
                faq.querySelector('.faq-answer').style.maxHeight = null;
            });

            if (!isActive) {
                item.classList.add('active');
                const answer = item.querySelector('.faq-answer');
                answer.style.maxHeight = answer.scrollHeight + "px";
            }
        });
    });

    // 5. Newsletter Form Logic (Simulated)
    const form = document.getElementById('notify-form');
    const formMsg = document.getElementById('form-msg');
    
    if (form) {
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            const btn = document.getElementById('submitBtn');
            
            btn.textContent = translations[currentLang].cta_loading;
            btn.style.opacity = '0.7';
            
            setTimeout(() => {
                emailInput.value = '';
                btn.textContent = translations[currentLang].cta_btn;
                btn.style.opacity = '1';
                formMsg.textContent = translations[currentLang].cta_success;
                
                setTimeout(() => {
                    formMsg.textContent = '';
                }, 5000);
            }, 1500);
        });
    }
});
