const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

setGlobalOptions({maxInstances: 10});

/**
 * Send notification to a user by their nickname
 * POST body: {
 *   partnerNickname: string,
 *   senderNickname: string,
 *   signalType: "thinkingOfYou" | "virtualHug"
 * }
 */
exports.sendLoveSignal = onRequest(async (request, response) => {
  // Enable CORS
  response.set("Access-Control-Allow-Origin", "*");

  if (request.method === "OPTIONS") {
    response.set("Access-Control-Allow-Methods", "POST");
    response.set("Access-Control-Allow-Headers", "Content-Type");
    response.status(204).send("");
    return;
  }

  try {
    const {partnerNickname, senderNickname, signalType} = request.body;

    // Validate input
    if (!partnerNickname || !senderNickname || !signalType) {
      response.status(400).json({
        success: false,
        error: "Missing required fields: " +
          "partnerNickname, senderNickname, signalType",
      });
      return;
    }

    // Get partner's FCM token from Firebase Realtime Database
    const lowercaseNickname = partnerNickname.toLowerCase();
    const tokenSnapshot = await admin.database()
        .ref(`notification_tokens/${lowercaseNickname}`)
        .once("value");

    if (!tokenSnapshot.exists()) {
      logger.warn(`No FCM token found for: ${lowercaseNickname}`);
      response.status(404).json({
        success: false,
        error: `No notification token found for ${partnerNickname}`,
      });
      return;
    }

    const tokenData = tokenSnapshot.val();
    const fcmToken = tokenData.token;

    if (!fcmToken) {
      response.status(404).json({
        success: false,
        error: "Token exists but is empty",
      });
      return;
    }

    // Prepare notification message
    const isThinking = signalType === "thinkingOfYou";
    const title = "Love Letters 💕";
    const body = isThinking ?
      `${senderNickname} is thinking of you right now 💭✨` :
      `${senderNickname} sent you a warm hug & kisses! 🤗💕`;

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        signalType: signalType,
        senderNickname: senderNickname,
        timestamp: Date.now().toString(),
      },
      token: fcmToken,
    };

    // Send notification
    const result = await admin.messaging().send(message);

    logger.info("✅ Notification sent successfully", {
      to: partnerNickname,
      from: senderNickname,
      type: signalType,
      messageId: result,
    });

    response.json({
      success: true,
      messageId: result,
      message: `Notification sent to ${partnerNickname}`,
    });
  } catch (error) {
    logger.error("❌ Error sending notification:", error);
    response.status(500).json({
      success: false,
      error: error.message,
    });
  }
});
