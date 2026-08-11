import mysql from "mysql2/promise";
import dotenv from "dotenv";

dotenv.config();

async function clearUserData() {
  console.log("=========================================");
  console.log("🧹 Starting User Account Data Clean-up...");
  console.log("=========================================");

  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "3306"),
    user: process.env.DB_USER || "root",
    password: process.env.DB_PASSWORD || "",
    database: process.env.DB_NAME || "wirapath_db",
    multipleStatements: true,
  });

  try {
    await connection.query("SET FOREIGN_KEY_CHECKS = 0;");

    console.log("1. Clearing user assessment answers & assessments...");
    await connection.query("DELETE FROM user_assessment_answers;");
    await connection.query("DELETE FROM user_assessments;");

    console.log("2. Clearing CV & Transcript screenings...");
    await connection.query("DELETE FROM cv_screenings;");
    await connection.query("DELETE FROM transcript_screenings;");

    console.log("3. Clearing simulations & messages & results...");
    await connection.query("DELETE FROM simulation_messages;");
    await connection.query("DELETE FROM simulation_results;");
    await connection.query("DELETE FROM simulations;");

    console.log("4. Clearing user mini project submissions...");
    await connection.query("DELETE FROM user_mini_project_submissions;");

    console.log("5. Clearing auth providers & user profiles...");
    await connection.query("DELETE FROM auth_providers;");
    await connection.query("DELETE FROM users;");

    await connection.query("SET FOREIGN_KEY_CHECKS = 1;");

    console.log("=========================================");
    console.log("✅ All user account data cleared successfully!");
    console.log("🔒 Master data (questions, categories, mini projects) preserved!");
    console.log("=========================================");
  } catch (error: any) {
    console.error("❌ Error clearing user data:", error.message);
  } finally {
    await connection.end();
  }
}

clearUserData();
