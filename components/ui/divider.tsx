import React from "react";
import { cn } from "@/lib/utils";

interface DividerProps extends React.HTMLAttributes<HTMLDivElement> {
  children?: React.ReactNode;
}

export function Divider({ className, children, ...props }: DividerProps) {
  if (children) {
    return (
      <div className={cn("relative my-6", className)} {...props}>
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-gray-600"></div>
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-gray-800 px-2 text-gray-400">{children}</span>
        </div>
      </div>
    );
  }

  return (
    <div
      className={cn("w-full border-t border-gray-600 my-6", className)}
      {...props}
    />
  );
}
