import 'person_sex.dart';

/// Perfil del médico veterinario (VeterinarianResource). Lo registra la clínica.
class Veterinarian {
  const Veterinarian({
    required this.id,
    required this.userId,
    required this.clinicId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.sex,
    this.licenseNumber,
    this.specialty,
    this.profileImageUrl,
  });

  final int id;
  final int userId;
  final int clinicId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final PersonSex? sex;

  /// Colegiatura CMVP.
  final String? licenseNumber;
  final String? specialty;
  final String? profileImageUrl;

  String get fullName => '$firstName $lastName'.trim();
}
