import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const viewport: Viewport = {
  themeColor: "#DC2626",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
};

export const metadata: Metadata = {
  title: "Kadoo - Roll Your Luck!",
  description: "Interactive Campus Booth Lucky Draw & Doorprize App - Developed by Computer Science Binus @Semarang",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Kadoo",
  },
  applicationName: "Kadoo",
  formatDetection: {
    telephone: false,
  },
  icons: {
    icon: [
      { url: "/app/favicon.png" },
      { url: "/icons/Icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/Icon-512.png", sizes: "512x512", type: "image/png" },
    ],
    apple: [
      { url: "/icons/Icon-192.png", sizes: "192x192", type: "image/png" },
      { url: "/icons/Icon-512.png", sizes: "512x512", type: "image/png" },
    ],
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="id"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <head>
        <link rel="manifest" href="/manifest.json" />
        <link rel="apple-touch-icon" href="/icons/Icon-192.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="Kadoo" />
        <meta name="theme-color" content="#DC2626" />
      </head>
      <body className="min-h-full flex flex-col m-0 p-0 overflow-hidden bg-[#DC2626]">{children}</body>
    </html>
  );
}
