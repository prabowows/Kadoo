'use client';

import React from 'react';

export default function HomePage() {
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
