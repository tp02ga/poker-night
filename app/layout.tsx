import "./globals.css";
import { Inter } from "next/font/google";
import type React from "react";
import { Toaster } from "@/components/ui/toaster";
import { Providers } from "@/redux/provider";
import { AuthStateInitializer } from "@/components/auth-state-initializer";
import { Navbar } from "@/components/navbar";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Poker Night",
  description: "Plan and manage your poker games",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-background text-foreground`}>
        <Providers>
          <AuthStateInitializer />
          <Navbar />
          <main>{children}</main>
          <Toaster />
        </Providers>
      </body>
    </html>
  );
}
