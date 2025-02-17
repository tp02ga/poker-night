import Link from "next/link";
import { cookies } from "next/headers";

export default function Home() {
  const isLoggedIn = cookies().has("token");

  return (
    <div className="min-h-screen gradient-bg flex flex-col items-center justify-center p-8">
      <div className="text-center space-y-6 max-w-2xl">
        <div className="space-y-4">
          <h1 className="text-5xl font-bold mb-2 bg-clip-text text-transparent bg-gradient-to-r from-blue-400 via-purple-400 to-blue-500">
            Welcome to Poker Game Planner
          </h1>
          <p className="text-blue-400/80 text-lg font-medium">
            Your destination for organizing poker nights
          </p>
        </div>
        {isLoggedIn ? (
          <div className="space-y-6">
            <Link
              href="/games"
              className="button-gradient block w-full max-w-md mx-auto text-white px-8 py-4 rounded-lg shadow-lg transform transition-all hover:scale-105 hover:shadow-blue-500/20"
            >
              View Games
            </Link>
            <Link
              href="/games/create"
              className="bg-blue-600 hover:bg-blue-500 block w-full max-w-md mx-auto text-white px-8 py-4 rounded-lg shadow-lg transform transition-all hover:scale-105 hover:shadow-blue-500/20"
            >
              Create New Game
            </Link>
          </div>
        ) : (
          <div className="space-y-8">
            <p className="text-xl text-gray-300">
              Join our community to plan and participate in poker games!
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/login"
                className="button-gradient px-8 py-4 rounded-lg text-white shadow-lg transform transition-all hover:scale-105 hover:shadow-blue-500/20"
              >
                Login
              </Link>
              <Link
                href="/register"
                className="bg-blue-600 hover:bg-blue-500 px-8 py-4 rounded-lg text-white shadow-lg transform transition-all hover:scale-105 hover:shadow-blue-500/20"
              >
                Register
              </Link>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
