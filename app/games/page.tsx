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

  const getDayOfWeek = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", { weekday: "short" }).toUpperCase();
  };

  const getDayOfMonth = (dateString: string) => {
    const date = new Date(dateString);
    return date.getDate();
  };

  const GameCard = ({ game }: { game: Game }) => {
    const router = useRouter();
    const date = new Date(game.dateTime);
    const dayOfWeek = getDayOfWeek(game.dateTime);
    const dayOfMonth = getDayOfMonth(game.dateTime);

    const handleGameClick = () => {
      router.push(`/games/${game.id}`);
    };

    return (
      <div className="bg-gray-800 rounded-lg overflow-hidden shadow-md hover:shadow-lg transition-shadow">
        <div className="flex">
          {/* Date display on the left */}
          <div className="bg-gray-700 p-4 flex flex-col items-center justify-center w-24 text-center">
            <div className="text-gray-300 font-medium">{dayOfWeek}</div>
            <div className="text-4xl font-bold text-yellow-400">
              {dayOfMonth}
            </div>
          </div>

          {/* Game details on the right */}
          <div className="p-4 flex-1">
            <h3 className="text-xl font-semibold text-white mb-1">
              Poker Night at {game.address.split(",")[0]}
            </h3>
            <div className="flex items-center text-sm text-gray-300 mb-2">
              <svg
                className="w-4 h-4 mr-1"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              {date.toLocaleDateString("en-US", {
                month: "long",
                day: "numeric",
                year: "numeric",
              })}
            </div>
            <div className="flex items-center text-sm text-gray-300 mb-2">
              <svg
                className="w-4 h-4 mr-1"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              {date.toLocaleTimeString("en-US", {
                hour: "numeric",
                minute: "2-digit",
              })}
            </div>
            <div className="flex items-center text-sm text-gray-300 mb-4">
              <svg
                className="w-4 h-4 mr-1"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                />
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              {game.address}
            </div>
            <p className="text-sm text-gray-300 mb-2">Host: {game.host.name}</p>
            <p className="text-sm text-gray-300 mb-4">
              Players: {game.attendees.filter((a) => !a.waitlist).length} /{" "}
              {game.maxPlayers}
              {game.attendees.filter((a) => a.waitlist).length > 0 &&
                ` (${
                  game.attendees.filter((a) => a.waitlist).length
                } on waitlist)`}
            </p>

            {game.isHost && (
              <div className="mb-4">
                <h4 className="font-medium text-gray-200 mb-2">Attendees:</h4>
                <ul className="text-sm">
                  {game.attendees.map((attendee) => (
                    <li
                      key={attendee.id}
                      className="flex justify-between items-center mb-1 py-1 border-b border-gray-700"
                    >
                      <span className="text-gray-300">
                        {attendee.name} {attendee.waitlist ? "(Waitlist)" : ""}
                      </span>
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          removeAttendee(game.id, attendee.id);
                        }}
                        className="text-red-400 hover:text-red-300 text-xs font-medium"
                      >
                        Remove
                      </button>
                    </li>
                  ))}
                </ul>
              </div>
            )}

            <div className="flex space-x-2">
              <button
                onClick={handleGameClick}
                className="flex-1 bg-gray-700 text-white py-2 rounded hover:bg-gray-600 transition-colors text-center"
              >
                Learn More
              </button>

              {!game.isHost && (
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    game.isAttending
                      ? handleLeaveGame(game.id)
                      : handleJoinGame(game.id);
                  }}
                  className={`flex-1 py-2 rounded transition-colors text-center ${
                    game.isAttending
                      ? "bg-red-600 text-white hover:bg-red-700"
                      : "bg-yellow-400 text-gray-900 hover:bg-yellow-500"
                  }`}
                  disabled={
                    !game.isAttending &&
                    new Date(game.dateTime).getTime() - new Date().getTime() <
                      5 * 60 * 1000
                  }
                >
                  {game.isAttending
                    ? "RSVP Cancel"
                    : game.attendees.length >= game.maxPlayers
                    ? "Join Waitlist"
                    : "RSVP"}
                </button>
              )}
            </div>
          </div>
        </div>
      </div>
    );
  };

  const PastGameCard = ({ game }: { game: Game }) => {
    const dayOfWeek = getDayOfWeek(game.dateTime);
    const dayOfMonth = getDayOfMonth(game.dateTime);
    const date = new Date(game.dateTime);

    return (
      <div className="bg-gray-800 rounded-lg overflow-hidden shadow-md">
        <div className="flex">
          {/* Date display on the left */}
          <div className="bg-gray-700 p-4 flex flex-col items-center justify-center w-24 text-center">
            <div className="text-gray-300 font-medium">{dayOfWeek}</div>
            <div className="text-4xl font-bold text-yellow-400">
              {dayOfMonth}
            </div>
          </div>

          {/* Game details on the right */}
          <div className="p-4 flex-1">
            <h3 className="text-xl font-semibold text-white mb-1">
              Poker Night at {game.address.split(",")[0]}
            </h3>
            <div className="flex items-center text-sm text-gray-300 mb-2">
              <svg
                className="w-4 h-4 mr-1"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
                xmlns="http://www.w3.org/2000/svg"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              {date.toLocaleDateString("en-US", {
                month: "long",
                day: "numeric",
                year: "numeric",
              })}
            </div>
            <p className="text-sm text-gray-300 mb-2">Host: {game.host.name}</p>
            <div className="flex space-x-2 mt-4">
              <button
                onClick={() => router.push(`/games/${game.id}`)}
                className="flex-1 bg-gray-700 text-white py-2 rounded hover:bg-gray-600 transition-colors text-center"
              >
                Learn More
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="min-h-screen bg-gray-900 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-3xl font-bold text-white">Poker Games</h1>
          <Button
            onClick={() => router.push("/games/create")}
            className="bg-yellow-400 hover:bg-yellow-500 text-gray-900"
          >
            Create New Game
          </Button>
        </div>

        <h2 className="text-2xl font-bold mb-4 text-gray-200">
          Upcoming Games
        </h2>
        <div className="grid gap-6 md:grid-cols-1 lg:grid-cols-2 mb-12">
          {upcomingGames.length > 0 ? (
            upcomingGames.map((game) => <GameCard key={game.id} game={game} />)
          ) : (
            <p className="text-gray-400">No upcoming games. Create one!</p>
          )}
        </div>

        <h2 className="text-2xl font-bold mb-4 text-gray-200">Past Games</h2>
        <div className="grid gap-6 md:grid-cols-1 lg:grid-cols-2">
          {pastGames.length > 0 ? (
            pastGames.map((game) => <PastGameCard key={game.id} game={game} />)
          ) : (
            <p className="text-gray-400">No past games.</p>
          )}
        </div>
      </div>
    </div>
  );
}
