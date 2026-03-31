// Firebase Cloud Messaging Configuration
// Handles push notifications for real-time updates
// Requires Firebase Admin SDK initialization

let admin = null;
let messaging = null;

// Initialize Firebase Admin SDK only if credentials are available
try {
    const firebaseConfigPath = process.env.FIREBASE_CONFIG_PATH || './serviceAccountKey.json';
    const fs = require('fs');
    
    if (fs.existsSync(firebaseConfigPath)) {
        admin = require('firebase-admin');
        const serviceAccount = require(firebaseConfigPath);
        
        if (!admin.apps.length) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccount),
            });
            messaging = admin.messaging();
            console.log('✅ Firebase Cloud Messaging configured');
        }
    } else {
        console.warn('⚠️  Firebase service account key not found. Push notifications disabled.');
        console.warn('   To enable, add FIREBASE_CONFIG_PATH to .env pointing to serviceAccountKey.json');
    }
} catch (error) {
    console.warn('⚠️  Firebase Cloud Messaging not configured:', error.message);
    console.warn('   Push notifications disabled. Set up Firebase to enable.');
}

/**
 * Send push notification to a device
 * @param {string} deviceToken - FCM device token
 * @param {object} notification - Notification data
 * @returns {Promise}
 */
const sendNotification = async (deviceToken, notification) => {
    if (!messaging) {
        console.log('⚠️  FCM not configured, notification not sent');
        return null;
    }

    try {
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data || {},
            token: deviceToken,
        };

        const response = await messaging.send(message);
        console.log('✅ Notification sent:', response);
        return response;
    } catch (error) {
        console.error('❌ Error sending notification:', error.message);
        throw error;
    }
};

/**
 * Send multi-cast notifications to multiple devices
 * @param {array} deviceTokens - Array of FCM device tokens
 * @param {object} notification - Notification data
 * @returns {Promise}
 */
const sendMulticastNotification = async (deviceTokens, notification) => {
    if (!messaging) {
        console.log('⚠️  FCM not configured, notifications not sent');
        return null;
    }

    try {
        const message = {
            notification: {
                title: notification.title,
                body: notification.body,
            },
            data: notification.data || {},
        };

        const response = await messaging.sendMulticast({
            ...message,
            tokens: deviceTokens,
        });

        console.log('✅ Multicast notification sent to', response.successCount, 'devices');
        return response;
    } catch (error) {
        console.error('❌ Error sending multicast notification:', error.message);
        throw error;
    }
};

module.exports = {
    admin,
    messaging,
    sendNotification,
    sendMulticastNotification,
};
