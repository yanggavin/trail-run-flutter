/// Privacy level for activity sharing
enum PrivacyLevel {
  /// Only visible to the user
  private,
  
  /// Visible to friends/followers
  friends,
  
  /// Publicly visible to everyone
  public,
}

extension PrivacyLevelExtension on PrivacyLevel {
  /// Human-readable name for the privacy level
  String get displayName {
    switch (this) {
      case PrivacyLevel.private:
        return 'Private';
      case PrivacyLevel.friends:
        return 'Friends';
      case PrivacyLevel.public:
        return 'Public';
    }
  }
  
  /// Icon representation for the privacy level
  String get icon {
    switch (this) {
      case PrivacyLevel.private:
        return '🔒';
      case PrivacyLevel.friends:
        return '👥';
      case PrivacyLevel.public:
        return '🌍';
    }
  }
  
  /// Whether this privacy level allows public sharing
  bool get isPublic => this == PrivacyLevel.public;
  
  /// Whether this privacy level is restricted
  bool get isRestricted => this != PrivacyLevel.public;
}