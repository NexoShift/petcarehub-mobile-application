/// Consultation in progress where a veterinarian can request an exam (data from Clinical Attention).
class OpenConsultation {
  const OpenConsultation({required this.id, required this.reason, required this.createdAt});

  final int id;
  final String reason;
  final DateTime createdAt;
}
