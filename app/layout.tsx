import "./globals.css";
import { Inter } from "next/font/google";
import Link from "next/link";
import { cookies } from "next/headers";
import { LogoutButton } from "@/components/logout-button";
import type React from "react";
import { Toaster } from "@/components/ui/toaster";

const inter = Inter({ subsets: ["latin"] });

export const metadata = {
  title: "Poker Game Planner",
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
        <nav className="bg-gray-800 p-4">
          <div className="container mx-auto flex justify-between items-center">
            <Link href="/" className="text-2xl font-bold">
              Poker Game Planner
            </Link>
            <div className="flex items-center gap-4">
              {isLoggedIn ? (
                <>
                  <Link
                    href="/games"
                    className="text-white hover:text-gray-300"
                  >
                    Games
                  </Link>
                  <LogoutButton />
                </>
              ) : (
                <>
                  <Link
                    href="/login"
                    className="text-white hover:text-gray-300"
                  >
                    Login
                  </Link>
                  <Link
                    href="/register"
                    className="text-white hover:text-gray-300"
                  >
                    Register
                  </Link>
                </>
              )}
            </div>
          </div>
        </nav>
        <main className="container mx-auto mt-8">{children}</main>
        <Toaster />
      </body>
    </html>
  );
}
