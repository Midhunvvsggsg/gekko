class Contact {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool notifyOnStart;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.notifyOnStart = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'notifyOnStart': notifyOnStart,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String? ?? 'Emergency Contact',
      phone: json['phone'] as String? ?? '+1 555-0199',
      relationship: json['relationship'] as String? ?? 'Family',
      notifyOnStart: json['notifyOnStart'] as bool? ?? true,
    );
  }
}
