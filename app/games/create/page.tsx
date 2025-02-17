"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";

export default function CreateGame() {
  const [dateTime, setDateTime] = useState("");
  const [maxPlayers, setMaxPlayers] = useState("");
  const [address, setAddress] = useState("");
  const router = useRouter();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const response = await fetch("/api/games", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        dateTime,
        maxPlayers: Number.parseInt(maxPlayers),
        address,
      }),
    });

    if (response.ok) {
      router.push("/games");
    } else {
      const data = await response.json();
      alert(data.error);
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col items-center justify-center">
      <form
        onSubmit={handleSubmit}
        className="bg-gray-800 p-8 rounded-lg shadow-lg"
      >
        <h2 className="text-2xl font-bold mb-6">Create New Game</h2>
        <div className="mb-4">
          <label htmlFor="dateTime" className="block mb-2">
            Date and Time
          </label>
          <input
            type="datetime-local"
            id="dateTime"
            value={dateTime}
            onChange={(e) => setDateTime(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 rounded"
            required
          />
        </div>
        <div className="mb-4">
          <label htmlFor="maxPlayers" className="block mb-2">
            Maximum Players
          </label>
          <input
            type="number"
            id="maxPlayers"
            value={maxPlayers}
            onChange={(e) => setMaxPlayers(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 rounded"
            required
          />
        </div>
        <div className="mb-6">
          <label htmlFor="address" className="block mb-2">
            Address
          </label>
          <input
            type="text"
            id="address"
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 rounded"
            required
          />
        </div>
        <Button type="submit" className="w-full">
          Create Game
        </Button>
      </form>
    </div>
  );
}
