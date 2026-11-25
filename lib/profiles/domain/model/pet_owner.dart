/// Perfil del dueño (PetOwnerResource). Por ahora solo lo que usa la app.
class PetOwner {
  const PetOwner({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
  });

  final int id;
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;

  factory PetOwner.fromJson(Map<String, dynamic> json) => PetOwner(
    id: (json['id'] as num).toInt(),
    userId: (json['userId'] as num).toInt(),
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phoneNumber: json['phoneNumber'] as String?,
    profileImageUrl: json['profileImageUrl'] as String?,
  );
}
