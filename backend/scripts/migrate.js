/**
 * Database Migration Script
 * Runs all SQL migration files from the models directory
 */

const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

require('dotenv').config();

// Database configuration
const dbConfig = process.env.INSTANCE_CONNECTION_NAME
  ? {
      socketPath: `/cloudsql/${process.env.INSTANCE_CONNECTION_NAME}`,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'medqueue_db',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      acquireTimeout: 60000,
      timeout: 60000,
    }
  : {
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'medqueue_db',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      acquireTimeout: 60000,
      timeout: 60000,
    };

const runMigrations = async () => {
  let connection;

  try {
    // Create connection
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to database');

    // Get all SQL files from models directory
    const modelsDir = path.join(__dirname, '../models');
    const sqlFiles = fs.readdirSync(modelsDir)
      .filter(file => file.endsWith('.sql'))
      .sort();

    if (sqlFiles.length === 0) {
      console.log('⚠️  No SQL migration files found');
      await connection.end();
      return;
    }

    console.log(`\n📋 Found ${sqlFiles.length} migration file(s):\n`);

    // Execute each SQL file
    for (const file of sqlFiles) {
      const filePath = path.join(modelsDir, file);
      const sql = fs.readFileSync(filePath, 'utf8');

      try {
        // Split by semicolon to handle multiple statements
        const statements = sql
          .split(';')
          .map(stmt => stmt.trim())
          .filter(stmt => stmt.length > 0 && !stmt.startsWith('--'));

        for (const statement of statements) {
          if (statement.trim()) {
            await connection.query(statement);
          }
        }

        console.log(`✅ ${file}`);
      } catch (error) {
        // Check if it's a table already exists error (acceptable for idempotent migrations)
        if (error.code === 'ER_TABLE_EXISTS_ERROR') {
          console.log(`⏭️  ${file} (table already exists, skipping)`);
        } else {
          console.error(`❌ ${file}`);
          console.error(`   Error: ${error.message}`);
          throw error;
        }
      }
    }

    console.log('\n✅ All migrations completed successfully!\n');
  } catch (error) {
    console.error('\n❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
};

// Run migrations
runMigrations();
