import Link from "next/link";
import { cookies } from "next/headers";
import Image from "next/image";

export default function Home() {
  const isLoggedIn = cookies().has("token");

  return (
    <div className="min-h-screen bg-gray-900 text-white relative overflow-hidden">
      {/* Background image with overlay */}
      <div className="absolute inset-0 z-0 opacity-40">
        <Image
          src="/poker-bg.jpg"
          alt="Poker table background"
          fill
          style={{ objectFit: "cover" }}
          priority
        />
      </div>

      {/* Content */}
      <div className="relative z-10 flex items-center min-h-screen">
        <div className="container mx-auto px-4 py-16 flex flex-col md:flex-row items-center">
          {/* Left side with poker icon */}
          <div className="md:w-1/3 mb-10 md:mb-0 flex justify-center">
            <div className="text-9xl text-white">♠️</div>
          </div>

          {/* Right side with text and buttons */}
          <div className="md:w-2/3 md:pl-12">
            <div className="space-y-6 max-w-2xl">
              <h1 className="text-6xl font-bold">
                <span className="text-white">PREMIUM</span>
                <br />
                <span className="text-yellow-400">Poker</span>
              </h1>
              <p className="text-xl text-gray-300">
                Best Poker Nights, Tables & Games for Everyone
              </p>

              <div className="flex flex-col sm:flex-row gap-4 pt-6">
                <Link
                  href={isLoggedIn ? "/games" : "/login"}
                  className="bg-yellow-400 hover:bg-yellow-500 text-gray-900 px-8 py-4 rounded-md font-medium transition-colors text-center"
                >
                  Start Now
                </Link>
                <Link
                  href="/about"
                  className="border border-gray-600 hover:border-yellow-400 text-white px-8 py-4 rounded-md font-medium transition-colors text-center"
                >
                  Learn More
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
