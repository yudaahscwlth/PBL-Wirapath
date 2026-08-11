import mysql from "mysql2/promise";
import dotenv from "dotenv";

const envResult = dotenv.config();
console.log("[Debug] dotenv config result:", {
  error: envResult.error,
  parsedKeys: envResult.parsed ? Object.keys(envResult.parsed) : null,
});

console.log("[Debug] DB connection parameters:", {
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  user: process.env.DB_USER,
  hasPassword: !!process.env.DB_PASSWORD,
  passwordLength: process.env.DB_PASSWORD ? process.env.DB_PASSWORD.length : 0,
  database: process.env.DB_NAME,
});

export const pool = mysql.createPool({
  host: process.env.DB_HOST || "localhost",
  port: parseInt(process.env.DB_PORT || "3306"),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  maxIdle: 10,
  idleTimeout: 60000,
  queueLimit: 0,
  enableKeepAlive: true,
  keepAliveInitialDelay: 0,
  multipleStatements: true,
});

export const query = async <T = any>(sql: string, params?: any[]): Promise<T> => {
  const [results] = await pool.execute(sql, params);
  return results as T;
};

import fs from "fs";
import path from "path";

// Automatically initialize schema & pre-seeded data if tables are missing
export const ensureSchemaInitialized = async (): Promise<void> => {
  try {
    const initSqlPath = path.join(process.cwd(), "db", "init.sql");
    if (fs.existsSync(initSqlPath)) {
      // Clean seed infrastructure data only (preserve user assessment attempts & project submissions)
      await pool.query(`SET FOREIGN_KEY_CHECKS = 0`);
      await pool.query(`DELETE FROM assessment_questions`);
      await pool.query(`DELETE FROM role_category_mapping`);
      await pool.query(`DELETE FROM mini_project_role_mapping`);
      await pool.query(`SET FOREIGN_KEY_CHECKS = 1`);

      // Safely ensure all modern columns exist on existing database tables
      const addCol = async (sql: string) => {
        try { await pool.query(sql); } catch (_) {}
      };

      await addCol(`ALTER TABLE mini_projects ADD COLUMN difficulty VARCHAR(50) DEFAULT 'Intermediate'`);
      await addCol(`ALTER TABLE mini_projects ADD COLUMN estimated_hours INT DEFAULT 4`);
      await addCol(`ALTER TABLE mini_projects ADD COLUMN points INT DEFAULT 100`);
      await addCol(`ALTER TABLE mini_projects ADD COLUMN tech_stack JSON`);
      await addCol(`ALTER TABLE mini_projects ADD COLUMN tasks JSON`);
      await addCol(`ALTER TABLE mini_projects ADD COLUMN sort_order INT DEFAULT 1`);
      await addCol(`ALTER TABLE mini_projects ADD COLUMN is_active BOOLEAN DEFAULT TRUE`);

      await addCol(`ALTER TABLE users ADD COLUMN github_username VARCHAR(255) NULL`);
      await addCol(`ALTER TABLE users ADD COLUMN github_languages JSON NULL`);
      await addCol(`ALTER TABLE users ADD COLUMN github_readiness_score DECIMAL(5,2) NULL`);
      await addCol(`ALTER TABLE users ADD COLUMN github_last_synced_at TIMESTAMP NULL`);

      await addCol(`ALTER TABLE user_mini_project_submissions ADD COLUMN github_repo_url TEXT`);
      await addCol(`ALTER TABLE user_mini_project_submissions ADD COLUMN submission_url TEXT`);
      await addCol(`ALTER TABLE user_mini_project_submissions ADD COLUMN overall_score INT DEFAULT 0`);
      await addCol(`ALTER TABLE user_mini_project_submissions ADD COLUMN feedback TEXT`);
      await addCol(`ALTER TABLE user_mini_project_submissions ADD COLUMN reviewed_at TIMESTAMP NULL`);

      const sql = fs.readFileSync(initSqlPath, "utf-8");
      await pool.query(sql);
      console.log("[Database] Schema & seed data cleanly initialized from db/init.sql");

      // Enforce clean 3 dedicated category mappings per role
      await pool.query(`
        INSERT IGNORE INTO role_category_mapping (id, target_role_pattern, category_slug, priority) VALUES
        (UUID(), 'Frontend Developer', 'fe_frameworks', 1),
        (UUID(), 'Frontend Developer', 'fe_css_responsive', 2),
        (UUID(), 'Frontend Developer', 'fe_performance_dom', 3),

        (UUID(), 'Backend Developer', 'be_server_api', 1),
        (UUID(), 'Backend Developer', 'be_database_sql', 2),
        (UUID(), 'Backend Developer', 'be_security_auth', 3),

        (UUID(), 'Fullstack Developer', 'fs_frontend_web', 1),
        (UUID(), 'Fullstack Developer', 'fs_backend_api', 2),
        (UUID(), 'Fullstack Developer', 'fs_database_orm', 3),

        (UUID(), 'Data Scientist', 'ds_python_libraries', 1),
        (UUID(), 'Data Scientist', 'ds_machine_learning', 2),
        (UUID(), 'Data Scientist', 'ds_data_engineering', 3),

        (UUID(), 'UI/UX Designer', 'ux_figma_design_systems', 1),
        (UUID(), 'UI/UX Designer', 'ux_principles_usability', 2),
        (UUID(), 'UI/UX Designer', 'ux_research_prototyping', 3),

        (UUID(), 'Mobile Developer', 'mb_flutter_dart', 1),
        (UUID(), 'Mobile Developer', 'mb_crossplatform_state', 2),
        (UUID(), 'Mobile Developer', 'mb_native_api_storage', 3);
      `);
      console.log("[Database] Enforced strictly 3 dedicated assessment categories per target role.");
    }
    
    // Ensure foreign key constraint exists for role_category_mapping -> assessment_categories(slug)
    try {
      await pool.query(
        `ALTER TABLE role_category_mapping ADD CONSTRAINT fk_rcm_category FOREIGN KEY (category_slug) REFERENCES assessment_categories(slug) ON DELETE CASCADE`
      );
      console.log("[Database] Added Foreign Key fk_rcm_category to role_category_mapping.");
    } catch (_) {
      // Constraint already exists, ignore
    }
  } catch (error: any) {
    console.error("[Database] Error initializing schema from db/init.sql:", error.message);
  }
};

// Dynamically ensure GitHub integration columns exist in users table
export const ensureGithubColumnsExist = async (): Promise<void> => {
  try {
    const checkColumns = [
      { name: "github_username", type: "VARCHAR(255) NULL" },
      { name: "github_languages", type: "JSON NULL" },
      { name: "github_readiness_score", type: "DECIMAL(5,2) NULL" },
      { name: "github_last_synced_at", type: "TIMESTAMP NULL" },
    ];

    for (const col of checkColumns) {
      const rows = await query<any[]>(`SHOW COLUMNS FROM users LIKE '${col.name}'`);
      if (rows.length === 0) {
        console.log(`[Database] Column '${col.name}' not found in 'users' table. Adding it...`);
        await pool.query(`ALTER TABLE users ADD COLUMN ${col.name} ${col.type}`);
        console.log(`[Database] Column '${col.name}' added successfully.`);
      }
    }
  } catch (error: any) {
    console.error("[Database] Error ensuring GitHub columns exist:", error.message);
  }
};
