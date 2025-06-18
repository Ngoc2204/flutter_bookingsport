// functions/src/index.ts
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

// Gửi thông báo khi đơn đặt được xác nhận
export const onBookingConfirmed = functions.firestore
    .document("bookings/{bookingId}")
    .onUpdate(async (change, context) => {
        const newValue = change.after.data();
        const previousValue = change.before.data();

        if (newValue.status === "confirmed" && previousValue.status !== "confirmed") {
            const userId = newValue.userId;
            const userSnap = await admin.firestore().collection("users").doc(userId).get();
            const user = userSnap.data();

            if (user && user.fcmToken) {
                const message = {
                    notification: {
                        title: "Đơn đặt sân đã được xác nhận!",
                        body: `Đơn đặt sân ${newValue.fieldName} của bạn đã được xác nhận.`,
                    },
                    token: user.fcmToken,
                    data: { // Dữ liệu payload để xử lý khi nhấn vào thông báo
                        screen: "booking_details",
                        bookingId: context.params.bookingId,
                    },
                };
                try {
                    await admin.messaging().send(message);
                    console.log("Notification sent successfully for booking:", context.params.bookingId);
                } catch (error) {
                    console.error("Error sending notification:", error);
                }
            }
        }
        return null;
    });

// Gửi thông báo nhắc lịch (ví dụ: chạy hàng giờ bằng Scheduled Function)
export const sendBookingReminders = functions.pubsub
    .schedule("every 60 minutes") // Chạy mỗi 60 phút
    .onRun(async (context) => {
        const now = admin.firestore.Timestamp.now();
        const oneHourLater = admin.firestore.Timestamp.fromMillis(now.toMillis() + 60 * 60 * 1000);
        const twoHoursLater = admin.firestore.Timestamp.fromMillis(now.toMillis() + 2 * 60 * 60 * 1000);

        // Tìm các booking sắp bắt đầu trong khoảng 1-2 tiếng nữa và chưa gửi nhắc
        const bookingsToRemindSnap = await admin.firestore().collection("bookings")
            .where("startTime", ">=", oneHourLater)
            .where("startTime", "<", twoHoursLater)
            .where("status", "==", "confirmed") // Chỉ nhắc đơn đã xác nhận
            // .where("isReminderSent", "==", false) // Thêm cờ này nếu muốn tránh gửi nhắc nhiều lần
            .get();

        for (const doc of bookingsToRemindSnap.docs) {
            const booking = doc.data();
            const userSnap = await admin.firestore().collection("users").doc(booking.userId).get();
            const user = userSnap.data();

            if (user && user.fcmToken) {
                const startTimeFormatted = booking.startTime.toDate().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
                const message = {
                    notification: {
                        title: "Nhắc lịch chơi thể thao!",
                        body: `Bạn có lịch chơi tại sân ${booking.fieldName} vào lúc ${startTimeFormatted} hôm nay.`,
                    },
                    token: user.fcmToken,
                    data: {
                        screen: "booking_details",
                        bookingId: doc.id,
                    }
                };
                try {
                    await admin.messaging().send(message);
                    console.log("Reminder sent for booking:", doc.id);
                    // await admin.firestore().collection("bookings").doc(doc.id).update({ isReminderSent: true });
                } catch (error) {
                    console.error("Error sending reminder for booking:", doc.id, error);
                }
            }
        }
        return null;
    });