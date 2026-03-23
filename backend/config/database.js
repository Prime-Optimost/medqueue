// Database Configuration
// MySQL connection setup with connection pooling for production readiness
// Handles database connections, migrations, and error handling

const mysql = require('mysql2/promise');

// Database configuration from environment variables
const dbConfig = {
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
  reconnect: true,
};

// Create connection pool
const pool = mysql.createPool(dbConfig);

// Test database connection
const testConnection = async () => {
  try {
    const connection = await pool.getConnection();
    console.log('✅ Database connected successfully');
    connection.release();
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    return false;
  }
};

// Execute query with error handling
const executeQuery = async (query, params = []) => {
  try {
    const [rows] = await pool.execute(query, params);
    return rows;
  } catch (error) {
    console.error('Database query error:', error);
    throw new Error(`Database operation failed: ${error.message}`);
  }
};

// Get single row
const getRow = async (query, params = []) => {
  const rows = await executeQuery(query, params);
  return rows.length > 0 ? rows[0] : null;
};

// Get multiple rows
const getRows = async (query, params = []) => {
  return await executeQuery(query, params);
};

// Insert and return insert ID
const insert = async (query, params = []) => {
  const result = await executeQuery(query, params);
  return result.insertId;
};

// Update and return affected rows
const update = async (query, params = []) => {
  const result = await executeQuery(query, params);
  return result.affectedRows;
};

// Delete and return affected rows
const deleteRows = async (query, params = []) => {
  const result = await executeQuery(query, params);
  return result.affectedRows;
};

// Transaction wrapper
const transaction = async (callback) => {
  const connection = await pool.getConnection();
  await connection.beginTransaction();

  try {
    const result = await callback(connection);
    await connection.commit();
    return result;
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
};

// Health check
const healthCheck = async () => {
  try {
    await pool.execute('SELECT 1');
    return { status: 'healthy', timestamp: new Date().toISOString() };
  } catch (error) {
    return {
      status: 'unhealthy',
      error: error.message,
      timestamp: new Date().toISOString()
    };
  }
};

// Graceful shutdown
const close = async () => {
  console.log('Closing database connections...');
  await pool.end();
  console.log('Database connections closed');
};

// Handle process termination
process.on('SIGINT', async () => {
  await close();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await close();
  process.exit(0);
});

module.exports = {
  pool,
  testConnection,
  executeQuery,
  getRow,
  getRows,
  insert,
  update,
  deleteRows,
  transaction,
  healthCheck,
  close,
};

// Comments for academic documentation:
// - MySQL connection pool for production scalability
// - Environment-based configuration for different deployments
// - Comprehensive error handling and logging
// - Transaction support for data consistency
// - Health check endpoint for monitoring
// - Graceful shutdown handling for clean exits