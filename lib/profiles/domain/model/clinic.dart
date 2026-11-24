/// Perfil de la clínica (ClinicResource). Por ahora solo lo que usa la app.
class Clinic {
  const Clinic({required this.id, required this.accountId, required this.name});

  final int id;
  final int accountId;
  final String name;

  factory Clinic.fromJson(Map<String, dynamic> json) => Clinic(
    id: (json['id'] as num).toInt(),
    accountId: (json['accountId'] as num).toInt(),
    name: json['name'] as String? ?? '',
  );
}
