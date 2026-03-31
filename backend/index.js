const functions = require('firebase-functions');
const app = require('./server');

// Export Express app as Firebase Function
exports.api = functions.https.onRequest(app);
