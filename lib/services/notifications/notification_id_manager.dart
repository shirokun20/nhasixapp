/// Manager for notification IDs
class NotificationIdManager {
  /// Get notification ID from content ID
  /// Uses hashCode to ensure consistent ID for same content
  int getNotificationId(String contentId) {
    return contentId.hashCode.abs() % 2147483647; // Max int32 value
  }
}
