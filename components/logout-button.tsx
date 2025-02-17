"use client";

import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";

export const LogoutButton = () => {
  const router = useRouter();

  const handleLogout = async () => {
    try {
      await fetch("/api/auth/logout", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
      });

      router.push("/");
      router.refresh(); // This forces a refresh of server components
    } catch (error) {
      console.error("Logout failed:", error);
    }
  };

  return (
    <Button
      onClick={handleLogout}
      variant="ghost"
      className="text-red-500 hover:text-red-700 hover:bg-red-100/10"
    >
      Logout
    </Button>
  );
};
