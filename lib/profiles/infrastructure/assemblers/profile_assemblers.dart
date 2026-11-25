import '../../domain/model/clinic.dart';
import '../../domain/model/person_sex.dart';
import '../../domain/model/pet.dart';
import '../../domain/model/pet_owner.dart';
import '../../domain/model/pet_sex.dart';
import '../../domain/model/species.dart';
import '../../domain/model/veterinarian.dart';

/// Convierten los recursos JSON de Profiles en modelos de dominio.
/// El dominio no sabe nada de JSON: todo el mapeo vive aquí.
class ProfileAssemblers {
  const ProfileAssemblers._();

  static int _id(dynamic value) => (value as num).toInt();

  static PetOwner petOwner(Map<String, dynamic> json) => PetOwner(
        id: _id(json['id']),
        userId: _id(json['userId']),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        sex: PersonSex.fromApi(json['sex'] as String?),
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  static Clinic clinic(Map<String, dynamic> json) => Clinic(
        id: _id(json['id']),
        accountId: _id(json['accountId']),
        name: json['name'] as String? ?? '',
        ruc: json['ruc'] as String?,
        address: json['address'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        description: json['description'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  static Veterinarian veterinarian(Map<String, dynamic> json) => Veterinarian(
        id: _id(json['id']),
        userId: _id(json['userId']),
        clinicId: _id(json['clinicId']),
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        sex: PersonSex.fromApi(json['sex'] as String?),
        licenseNumber: json['licenseNumber'] as String?,
        specialty: json['specialty'] as String?,
        profileImageUrl: json['profileImageUrl'] as String?,
      );

  /// PetResource (completo) o PetSearchResource (búsqueda por código, sin ownerId).
  static Pet pet(Map<String, dynamic> json) {
    final birthDate = json['birthDate'] as String?;
    return Pet(
      id: _id(json['id']),
      ownerId: json['ownerId'] == null ? 0 : _id(json['ownerId']),
      petCode: json['petCode'] as String? ?? '',
      name: json['name'] as String? ?? '',
      species: Species.fromApi(json['species'] as String?),
      breed: json['breed'] as String?,
      birthDate: birthDate == null ? null : DateTime.tryParse(birthDate),
      sex: PetSex.fromApi(json['sex'] as String?),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  static List<T> list<T>(dynamic json, T Function(Map<String, dynamic>) map) =>
      [for (final item in (json as List? ?? const [])) map(item as Map<String, dynamic>)];
}
