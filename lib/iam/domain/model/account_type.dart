/// Tipo de cuenta de IAM. Los nombres coinciden con el enum AccountType del backend.
enum AccountType {
  petOwner('PET_OWNER'),
  clinic('CLINIC');

  const AccountType(this.apiValue);

  final String apiValue;

  static AccountType fromApi(String value) =>
      AccountType.values.firstWhere((type) => type.apiValue == value);
}
