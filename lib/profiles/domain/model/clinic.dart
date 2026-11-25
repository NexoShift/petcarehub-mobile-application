/// Perfil de la clínica (ClinicResource).
class Clinic {
  const Clinic({
    required this.id,
    required this.accountId,
    required this.name,
    this.ruc,
    this.address,
    this.phoneNumber,
    this.description,
    this.profileImageUrl,
  });

  final int id;
  final int accountId;
  final String name;
  final String? ruc;
  final String? address;
  final String? phoneNumber;
  final String? description;
  final String? profileImageUrl;
}
