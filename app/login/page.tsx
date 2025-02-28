"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { useAppDispatch } from "@/redux/hooks";
import { loginSuccess, setLoading, setError } from "@/redux/features/userSlice";
import { FcGoogle } from "react-icons/fc";
import { Divider } from "@/components/ui/divider";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const router = useRouter();
  const dispatch = useAppDispatch();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    dispatch(setLoading(true));

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      if (response.ok) {
        // Get user data from the response
        const userData = await response.json();

        // Dispatch login success with user data
        dispatch(
          loginSuccess({
            id: userData.userId || "",
            username: email,
            email: email,
          })
        );

        router.push("/games");
      } else {
        const data = await response.json();
        dispatch(setError(data.error || "Login failed"));
        alert(data.error);
      }
    } catch (error) {
      dispatch(setError("An error occurred during login"));
      alert("An error occurred during login");
    } finally {
      dispatch(setLoading(false));
    }
  };

  const handleGoogleSignIn = async () => {
    dispatch(setLoading(true));
    try {
      // Redirect to Google OAuth endpoint
      window.location.href = "/api/auth/google";
    } catch (error) {
      dispatch(setError("An error occurred with Google Sign-in"));
      alert("An error occurred with Google Sign-in");
      dispatch(setLoading(false));
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col items-center justify-center">
      <form
        onSubmit={handleSubmit}
        className="bg-gray-800 p-8 rounded-lg shadow-lg w-full max-w-md"
      >
        <h2 className="text-2xl font-bold mb-6">Login</h2>

        {/* Google Sign-in Button */}
        <Button
          type="button"
          variant="outline"
          className="w-full mb-4 flex items-center justify-center gap-2 bg-white text-black hover:bg-gray-100"
          onClick={handleGoogleSignIn}
        >
          <FcGoogle className="text-xl" />
          <span>Sign in with Google</span>
        </Button>

        <div className="relative my-6">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-gray-600"></div>
          </div>
          <div className="relative flex justify-center text-xs uppercase">
            <span className="bg-gray-800 px-2 text-gray-400">
              Or continue with email
            </span>
          </div>
        </div>

        <div className="mb-4">
          <label htmlFor="email" className="block mb-2">
            Email
          </label>
          <input
            type="email"
            id="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 rounded"
            required
          />
        </div>
        <div className="mb-6">
          <label htmlFor="password" className="block mb-2">
            Password
          </label>
          <input
            type="password"
            id="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="w-full px-3 py-2 bg-gray-700 rounded"
            required
          />
        </div>
        <Button type="submit" className="w-full">
          Login
        </Button>
      </form>
    </div>
  );
}
