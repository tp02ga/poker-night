"use client";

import { useAppSelector, useAppDispatch } from "@/redux/hooks";
import {
  selectUser,
  selectIsLoggedIn,
  logout,
} from "@/redux/features/userSlice";

export function UserProfile() {
  const user = useAppSelector(selectUser);
  const isLoggedIn = useAppSelector(selectIsLoggedIn);
  const dispatch = useAppDispatch();

  const handleLogout = () => {
    dispatch(logout());
    // You would also want to handle the actual logout API call here
    // and clear cookies/local storage as needed
  };

  if (!isLoggedIn || !user) {
    return <div>Not logged in</div>;
  }

  return (
    <div className="p-4 bg-gray-100 rounded-lg shadow">
      <h2 className="text-xl font-bold mb-2">User Profile</h2>
      <p>
        <strong>Username:</strong> {user.username}
      </p>
      <p>
        <strong>Email:</strong> {user.email}
      </p>
      <button
        onClick={handleLogout}
        className="mt-4 px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 transition-colors"
      >
        Logout
      </button>
    </div>
  );
}
