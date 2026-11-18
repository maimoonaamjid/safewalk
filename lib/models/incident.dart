/// One row of alert history.
class Incident {
  Incident({
    this.id,
    required this.time,
    this.latitude,
    this.longitude,
    required this.triggerType,
    required this.status,
  });

  final int? id;
  final DateTime time;
  final double? latitude;
  final double? longitude;

  /// 'SOS', 'Shake', 'Check-in' or 'Test'.
  final String triggerType;

  /// 'sent' or 'cancelled'.
  final String status;

  bool get wasSent => status == 'sent';
  bool get hasLocation => latitude != null && longitude != null;

  Map<String, Object?> toMap() => {
        'id': id,
        'timestamp': time.millisecondsSinceEpoch,
        'latitude': latitude,
        'longitude': longitude,
        'trigger_type': triggerType,
        'status': status,
      };

  factory Incident.fromMap(Map<String, Object?> m) => Incident(
        id: m['id'] as int?,
        time: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
        latitude: (m['latitude'] as num?)?.toDouble(),
        longitude: (m['longitude'] as num?)?.toDouble(),
        triggerType: m['trigger_type'] as String,
        status: m['status'] as String,
      );
}
