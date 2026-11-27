/// Quién y dónde se atendió, con nombres en vez de ids (ver ExternalProfilesService).
/// Cada dato es opcional: si Profiles no responde, la consulta igual se muestra.
class AttendingStaff {
  const AttendingStaff({
    this.veterinarianName,
    this.licenseNumber,
    this.clinicName,
    this.ownerName,
    this.consultingRoomName,
  });

  final String? veterinarianName;

  /// Colegiatura CMVP.
  final String? licenseNumber;
  final String? clinicName;
  final String? ownerName;
  final String? consultingRoomName;

  bool get isEmpty =>
      veterinarianName == null &&
      clinicName == null &&
      ownerName == null &&
      consultingRoomName == null;
}
