"use client";

import { useEffect, useState } from "react";
import { useAppDispatch } from "@/redux/hooks";
import { loginSuccess, setLoading } from "@/redux/features/userSlice";

export function AuthStateInitializer() {
  const dispatch = useAppDispatch();
  const [isInitialized, setIsInitialized] = useState(false);

  useEffect(() => {
    const initializeAuthState = async () => {
      // Set loading state while checking authentication
      dispatch(setLoading(true));

      // Check for authentication redirect params (for OAuth flows)
      const urlParams = new URLSearchParams(window.location.search);
      const authSuccess = urlParams.get("auth_success");
      const authError = urlParams.get("auth_error");

      if (authError) {
        console.error("Authentication error:", authError);
        // Clear the URL parameters without refreshing the page
        window.history.replaceState(
          {},
          document.title,
          window.location.pathname
        );
      }

      try {
        // Check if user is logged in by fetching current user data
        const response = await fetch("/api/auth/me");

        if (response.ok) {
          const userData = await response.json();

          // If we have user data, update Redux state
          if (userData && userData.userId) {
            dispatch(
              loginSuccess({
                id: userData.userId,
                username: userData.username || userData.email.split("@")[0],
                email: userData.email,
              })
            );

            // If this was a successful redirect from OAuth, clear the URL parameters
            if (authSuccess) {
              window.history.replaceState(
                {},
                document.title,
                window.location.pathname
              );
            }
          }
        }
      } catch (error) {
        console.error("Error initializing auth state:", error);
      } finally {
        // Finish loading regardless of outcome
        dispatch(setLoading(false));
        setIsInitialized(true);
      }
    };

    initializeAuthState();
  }, [dispatch]);

  // This component doesn't render anything visible
  return null;
}
