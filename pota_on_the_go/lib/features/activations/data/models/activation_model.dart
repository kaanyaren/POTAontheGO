class ActivationModel {
  final String activator;
  final String reference;
  final String qsos;
  final String date;

  ActivationModel({
    required this.activator,
    required this.reference,
    required this.qsos,
    required this.date,
  });

  factory ActivationModel.fromJson(Map<String, dynamic> json) {
    return ActivationModel(
      activator: json['activator'] ?? '',
      reference: json['reference'] ?? '',
      qsos: json['qsos']?.toString() ?? '0',
      date: json['date'] ?? '',
    );
  }
}
