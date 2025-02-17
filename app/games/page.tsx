"use client";

import { useState, useEffect } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";

interface Game {
  id: number;
  dateTime: string;
  host: { name: string };
  maxPlayers: number;
  address: string;
  attendees: { id: number; name: string; waitlist: boolean }[];
  isHost: boolean;
  isAttending: boolean;
}

export default function Games() {
  const [upcomingGames, setUpcomingGames] = useState<Game[]>([]);
  const [pastGames, setPastGames] = useState<Game[]>([]);
  const router = useRouter();
  const { toast } = useToast();

  useEffect(() => {
    const fetchGames = async () => {
      const response = await fetch("/api/games");
      if (response.ok) {
        const data = await response.json();
        setUpcomingGames(data.upcomingGames);
        setPastGames(data.pastGames);
      }
    };
    fetchGames();
  }, []);

  const handleJoinGame = async (gameId: number) => {
    const response = await fetch(`/api/games/${gameId}/join`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    });

    const data = await response.json();

    if (!response.ok) {
      toast({
        title: "Error",
        description: data.error,
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "Success",
      description: data.message,
    });
    router.refresh();
  };

  const handleLeaveGame = async (gameId: number) => {
    const response = await fetch(`/api/games/${gameId}/leave`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
    });

    const data = await response.json();

    if (!response.ok) {
      toast({
        title: "Error",
        description: data.error,
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "Success",
      description: data.message,
    });
    router.refresh();
  };

  const removeAttendee = async (gameId: number, attendeeId: number) => {
    const response = await fetch(
      `/api/games/${gameId}/attendees/${attendeeId}`,
      { method: "DELETE" }
    );

    const data = await response.json();

    if (!response.ok) {
      toast({
        title: "Error",
        description: data.error,
        variant: "destructive",
      });
      return;
    }

    toast({
      title: "Success",
      description: "Attendee removed successfully",
    });
    router.refresh();
  };

  const GameCard = ({ game }: { game: Game }) => {
    const router = useRouter();

    const handleGameClick = () => {
      router.push(`/games/${game.id}`);
    };

    return (
      <div
        onClick={handleGameClick}
        className="bg-gray-800 p-6 rounded-lg shadow-md cursor-pointer hover:bg-gray-700 transition-colors"
        role="button"
        tabIndex={0}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === " ") {
            handleGameClick();
          }
        }}
        aria-label={`View details for game on ${new Date(
          game.dateTime
        ).toLocaleDateString()} at ${game.address}`}
      >
        <h3 className="text-xl font-bold mb-2">
          {new Date(game.dateTime).toLocaleString()}
        </h3>
        <p className="mb-2">Host: {game.host.name}</p>
        <p className="mb-2">Address: {game.address}</p>
        <p className="mb-2">
          Players: {game.attendees.filter((a) => !a.waitlist).length} /{" "}
          {game.maxPlayers}
        </p>
        <p className="mb-2">
          Waitlist: {game.attendees.filter((a) => a.waitlist).length}
        </p>
        {game.isHost ? (
          <div>
            <h4 className="font-bold mt-4 mb-2">Attendees:</h4>
            <ul>
              {game.attendees.map((attendee) => (
                <li
                  key={attendee.id}
                  className="flex justify-between items-center mb-1"
                >
                  <span>
                    {attendee.name} {attendee.waitlist ? "(Waitlist)" : ""}
                  </span>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      removeAttendee(game.id, attendee.id);
                    }}
                    className="bg-secondary text-white px-2 py-1 rounded text-sm hover:bg-opacity-80 transition-colors"
                  >
                    Remove
                  </button>
                </li>
              ))}
            </ul>
          </div>
        ) : game.isAttending ? (
          <Button
            onClick={(e) => {
              e.stopPropagation();
              handleLeaveGame(game.id);
            }}
            variant="destructive"
            className="w-full"
          >
            Leave Game
          </Button>
        ) : (
          <Button
            onClick={(e) => {
              e.stopPropagation();
              handleJoinGame(game.id);
            }}
            variant="default"
            className="w-full"
            disabled={
              new Date(game.dateTime).getTime() - new Date().getTime() <
              5 * 60 * 1000
            }
          >
            {game.attendees.length >= game.maxPlayers
              ? "Join Waitlist"
              : "Join Game"}
          </Button>
        )}
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-background text-foreground p-8">
      <h1 className="text-3xl font-bold mb-8">Poker Games</h1>
      <Button
        onClick={() => router.push("/games/create")}
        className="mb-8"
        variant="default"
      >
        Create New Game
      </Button>

      <h2 className="text-2xl font-bold mb-4">Upcoming Games</h2>
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3 mb-8">
        {upcomingGames.map((game) => (
          <GameCard key={game.id} game={game} />
        ))}
      </div>

      <h2 className="text-2xl font-bold mb-4">Past Games</h2>
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {pastGames.map((game) => (
          <div key={game.id} className="bg-gray-800 p-6 rounded-lg shadow-lg">
            <h3 className="text-xl font-bold mb-2">
              {new Date(game.dateTime).toLocaleString()}
            </h3>
            <p className="mb-2">Host: {game.host.name}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
