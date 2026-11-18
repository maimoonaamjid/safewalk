/// A trusted person who receives the emergency alert.
class EmergencyContact {
  EmergencyContact({
    this.id,
    required this.name,
    required this.phone,
    this.priority = 0,
  });

  final int? id;
  final String name;
  final String phone;

  /// 1 = priority (starred) contact, 0 = normal.
  final int priority;

  bool get isPrimary => priority == 1;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'priority': priority,
      };

  factory EmergencyContact.fromMap(Map<String, Object?> m) => EmergencyContact(
        id: m['id'] as int?,
        name: m['name'] as String,
        phone: m['phone'] as String,
        priority: (m['priority'] as int?) ?? 0,
      );
}
