class LeaveBalance {
  final String id;
  final String userId;
  final double totalLeaves;
  final double usedLeaves;

  LeaveBalance({
    required this.id,
    required this.userId,
    required this.totalLeaves,
    required this.usedLeaves,
  });

  double get remainingLeaves => totalLeaves - usedLeaves;

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    return LeaveBalance(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      totalLeaves: (json['total_leaves'] as num).toDouble(),
      usedLeaves: (json['used_leaves'] as num).toDouble(),
    );
  }

  LeaveBalance copyWith({
    String? id,
    String? userId,
    double? totalLeaves,
    double? usedLeaves,
  }) {
    return LeaveBalance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      totalLeaves: totalLeaves ?? this.totalLeaves,
      usedLeaves: usedLeaves ?? this.usedLeaves,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LeaveBalance &&
        other.id == id &&
        other.userId == userId &&
        other.totalLeaves == totalLeaves &&
        other.usedLeaves == usedLeaves;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      totalLeaves.hashCode ^
      usedLeaves.hashCode;

  @override
  String toString() {
    return 'LeaveBalance(id: $id, userId: $userId, totalLeaves: $totalLeaves, usedLeaves: $usedLeaves)';
  }
}
