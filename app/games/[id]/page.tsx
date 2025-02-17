"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";

type Attendee = {
  id: string;
  user: {
    name: string;
    email: string;
  };
};

type Game = {
  id: string;
  dateTime: string;
  address: string;
  attendees: Attendee[];
  host: {
    name: string;
  };
};

export default function GameDetails({ params }: { params: { id: string } }) {
  const [game, setGame] = useState<Game | null>(null);
  const [loading, setLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    const fetchGameDetails = async () => {
      try {
        const response = await fetch(`/api/games/${params.id}`);
        if (response.ok) {
          const data = await response.json();
          console.log("Game data:", data);
          setGame(data);
        } else {
          console.error("Failed to fetch game details");
        }
      } catch (error) {
        console.error("Error fetching game details:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchGameDetails();
  }, [params.id]);

  const handleBack = () => {
    router.push("/games");
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <p className="text-foreground">Loading...</p>
      </div>
    );
  }

  if (!game) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <p className="text-foreground">Game not found</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background text-foreground p-8">
      <Button
        onClick={handleBack}
        className="mb-6 flex items-center gap-2"
        variant="outline"
      >
        <ArrowLeft className="h-4 w-4" />
        Back to Games
      </Button>

      <div className="max-w-2xl mx-auto bg-gray-800 rounded-lg shadow-lg p-6">
        <h1 className="text-2xl font-bold mb-6">Game Details</h1>

        <div className="mb-6">
          <p className="mb-2">
            <span className="font-semibold">Host:</span> {game.host.name}
          </p>
          <p className="mb-2">
            <span className="font-semibold">Date:</span>{" "}
            {new Date(game.dateTime).toLocaleDateString()}
          </p>
          <p className="mb-2">
            <span className="font-semibold">Time:</span>{" "}
            {new Date(game.dateTime).toLocaleTimeString()}
          </p>
          <p className="mb-2">
            <span className="font-semibold">Location:</span> {game.address}
          </p>
        </div>

        <div>
          <h2 className="text-xl font-semibold mb-4">Players</h2>
          {game.attendees && game.attendees.length === 0 ? (
            <p className="text-gray-400">No players have signed up yet</p>
          ) : (
            <ul className="space-y-2">
              {game.attendees.map((attendee) => (
                <li
                  key={attendee.id}
                  className="bg-gray-700 p-3 rounded-md flex items-center justify-between"
                >
                  <span>{attendee.user.name}</span>
                  <span className="text-gray-400 text-sm">
                    {attendee.user.email}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
