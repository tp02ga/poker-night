#!/usr/bin/env node

/**
 * Database Sync Script
 *
 * This script runs Prisma commands to sync the RDS database with the schema.
 * It handles both schema generation and migrations.
 */

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

// RDS Connection string
const DATABASE_URL =
  "mysql://admin:my-secret-password@poker-night-app-db.cw1e2gugisfd.us-east-1.rds.amazonaws.com:3306/poker_game_planner";

// Create a temporary .env file with the DATABASE_URL
const createTempEnv = () => {
  console.log("Creating temporary .env file with RDS connection string...");

  // Backup existing .env if it exists
  if (fs.existsSync(".env")) {
    console.log("Backing up existing .env file...");
    fs.copyFileSync(".env", ".env.backup");
  }

  // Write the new .env file with the RDS connection
  fs.writeFileSync(".env", `DATABASE_URL="${DATABASE_URL}"\n`);
  console.log("Temporary .env file created successfully.");
};

// Restore the original .env file
const restoreEnv = () => {
  console.log("Restoring original .env file...");

  if (fs.existsSync(".env.backup")) {
    fs.copyFileSync(".env.backup", ".env");
    fs.unlinkSync(".env.backup");
    console.log("Original .env file restored successfully.");
  } else {
    // If there was no original .env, remove the temporary one
    fs.unlinkSync(".env");
    console.log("Temporary .env file removed.");
  }
};

// Run Prisma commands
const runPrismaCommands = () => {
  try {
    console.log("Running prisma generate...");
    execSync("npx prisma generate", { stdio: "inherit" });

    console.log("Running prisma migrate deploy...");
    execSync("npx prisma migrate deploy", { stdio: "inherit" });

    console.log("Database sync completed successfully!");
  } catch (error) {
    console.error("Error running Prisma commands:", error.message);
    process.exit(1);
  }
};

// Main function
const main = () => {
  try {
    createTempEnv();
    runPrismaCommands();
  } catch (error) {
    console.error("Error:", error.message);
  } finally {
    restoreEnv();
  }
};

// Run the script
main();
