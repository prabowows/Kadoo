'use client';

import React, { useEffect, useState } from 'react';

export default function HomePage() {
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [showInstallBanner, setShowInstallBanner] = useState(false);
  const [isIOS, setIsIOS] = useState(false);
  const [isStandalone, setIsStandalone] = useState(false);

  useEffect(() => {
    // 1. Register Service Worker for PWA
    if ('serviceWorker' in navigator) {
      window.addEventListener('load', () => {
        navigator.serviceWorker
          .register('/sw.js')
          .then((registration) => {
            console.log('PWA ServiceWorker registered successfully:', registration.scope);
          })
          .catch((error) => {
            console.warn('PWA ServiceWorker registration failed:', error);
          });
      });
    }

    // 2. Check if already running in standalone / installed PWA mode
    const standalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      (window.navigator as any).standalone === true;
    setIsStandalone(standalone);

    // 3. Detect iOS Safari
    const userAgent = window.navigator.userAgent.toLowerCase();
    const isIosDevice = /iphone|ipad|ipod/.test(userAgent);
    setIsIOS(isIosDevice);

    // 4. Capture native browser PWA install prompt
    const handleBeforeInstallPrompt = (e: Event) => {
      e.preventDefault();
      setDeferredPrompt(e);
      if (!standalone) {
        setShowInstallBanner(true);
      }
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    // If installed, dismiss
    window.addEventListener('appinstalled', () => {
      setShowInstallBanner(false);
      setDeferredPrompt(null);
    });

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstallPrompt);
    };
  }, []);

  const handleInstallClick = async () => {
    if (!deferredPrompt) {
      if (isIOS) {
        alert(
          'Untuk menginstall di iPhone/iPad:\n1. Ketuk tombol Share (ikon kotak panah ke atas) di Safari.\n2. Pilih "Add to Home Screen" (Tambahkan ke Layar Utama).'
        );
      }
      return;
    }

    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      setShowInstallBanner(false);
    }
    setDeferredPrompt(null);
  };

  return (
    <main
      style={{
        position: 'fixed',
        inset: 0,
        width: '100vw',
        height: '100vh',
        margin: 0,
        padding: 0,
        overflow: 'hidden',
        backgroundColor: '#DC2626',
      }}
    >
      {/* Floating PWA Install Prompt Banner */}
      {showInstallBanner && !isStandalone && (
        <aside
          aria-label="Install App Banner"
          style={{
            position: 'absolute',
            top: '14px',
            left: '50%',
            transform: 'translateX(-50%)',
            zIndex: 9999,
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            backgroundColor: '#0F172A',
            color: '#FFFFFF',
            padding: '10px 16px',
            borderRadius: '9999px',
            boxShadow: '0 10px 25px -5px rgba(0, 0, 0, 0.4), 0 8px 10px -6px rgba(0, 0, 0, 0.3)',
            border: '1px solid rgba(255, 255, 255, 0.15)',
            fontFamily: 'system-ui, -apple-system, sans-serif',
            fontSize: '13px',
            fontWeight: 600,
            animation: 'fadeInDown 0.4s ease-out',
          }}
        >
          <span style={{ fontSize: '18px' }}>🎲</span>
          <span>Install Kadoo sebagai Aplikasi?</span>
          <button
            onClick={handleInstallClick}
            style={{
              backgroundColor: '#DC2626',
              color: '#FFFFFF',
              border: 'none',
              borderRadius: '9999px',
              padding: '6px 14px',
              fontSize: '12px',
              fontWeight: 800,
              cursor: 'pointer',
              boxShadow: '0 2px 8px rgba(220, 38, 38, 0.4)',
              transition: 'transform 0.1s ease',
            }}
            onMouseDown={(e) => (e.currentTarget.style.transform = 'scale(0.95)')}
            onMouseUp={(e) => (e.currentTarget.style.transform = 'scale(1)')}
          >
            INSTALL
          </button>
          <button
            onClick={() => setShowInstallBanner(false)}
            aria-label="Close"
            style={{
              background: 'transparent',
              border: 'none',
              color: '#94A3B8',
              fontSize: '16px',
              cursor: 'pointer',
              padding: '2px',
              lineHeight: 1,
            }}
          >
            ✕
          </button>
        </aside>
      )}

      {/* Embedded Flutter Web Application */}
      <iframe
        src="/app/index.html"
        title="Kadoo - Roll Your Luck!"
        style={{
          width: '100%',
          height: '100%',
          border: 'none',
          display: 'block',
        }}
        allow="accelerometer; gyroscope; autoplay; clipboard-write; microphone; camera"
        allowFullScreen
      />
    </main>
  );
}
