import 'person_sex.dart';

/// Perfil del dueño (PetOwnerResource).
class PetOwner {
  const PetOwner({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.sex,
    this.profileImageUrl,
  });

  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final PersonSex? sex;
  final String? profileImageUrl;

  String get fullName => '$firstName $lastName'.trim();
}
