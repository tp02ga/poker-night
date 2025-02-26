import "./globals.css";
import { Inter } from "next/font/google";
import Link from "next/link";
import { cookies } from "next/headers";
import { LogoutButton } from "@/components/logout-button";
import type React from "react";
import { Toaster } from "@/components/ui/toaster";

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
  const isLoggedIn = cookies().has("token");

  return (
    <html lang="en">
      <body className={`${inter.className} bg-background text-foreground`}>
        <nav className="bg-gray-900 p-4 shadow-md">
          <div className="container mx-auto flex justify-between items-center">
            <Link href="/" className="text-2xl font-bold text-yellow-400">
              P<span className="text-red-500">♥</span>ker Night
            </Link>
            <div className="flex items-center gap-8">
              {isLoggedIn ? (
                <>
                  <Link
                    href="/games"
                    className="text-white hover:text-yellow-400 transition-colors"
                  >
                    Games
                  </Link>
                  <LogoutButton />
                </>
              ) : (
                <Link
                  href="/login"
                  className="text-white hover:text-yellow-400 transition-colors"
                >
                  Login
                </Link>
              )}
            </div>
          </div>
        </nav>
        <main>{children}</main>
        <Toaster />
      </body>
    </html>
  );
}
