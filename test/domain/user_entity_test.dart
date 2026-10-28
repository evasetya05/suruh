import 'package:flutter_test/flutter_test.dart';
import 'package:suruh/data/models/address_model.dart';
import 'package:suruh/data/models/user_model.dart';
import 'package:suruh/domain/entities/address.dart';
import 'package:suruh/domain/entities/user.dart';

void main() {
  group('User & UserModel defaultAddress tests', () {
    test('defaultAddress works when addresses list contains AddressModel instances', () {
      final List<AddressModel> addressModels = <AddressModel>[
        const AddressModel(
          id: 'addr-1',
          label: AddressLabel.home,
          line1: 'Jl. Gajah Mada No. 10',
          city: 'Pontianak',
          postcode: '78121',
          state: 'Kalimantan Barat',
          isDefault: false,
        ),
        const AddressModel(
          id: 'addr-2',
          label: AddressLabel.work,
          line1: 'Jl. Tanjungpura No. 88',
          city: 'Pontianak',
          postcode: '78122',
          state: 'Kalimantan Barat',
          isDefault: true,
        ),
      ];

      final User user = User(
        id: 'u-1',
        name: 'Budi Santoso',
        email: 'budi@suruh.id',
        phone: '081234567890',
        role: UserRole.customer,
        addresses: addressModels,
      );

      expect(() => user.defaultAddress, returnsNormally);
      final Address? defaultAddr = user.defaultAddress;
      expect(defaultAddr, isNotNull);
      expect(defaultAddr?.id, equals('addr-2'));
      expect(defaultAddr?.label, equals(AddressLabel.work));
    });

    test('UserModel.fromJson properly provides defaultAddress without runtime type mismatch', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'id': 'u-json',
        'name': 'Siti Rahma',
        'email': 'siti@suruh.id',
        'phone': '08987654321',
        'role': 'customer',
        'addresses': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'addr-ptk-1',
            'label': 'home',
            'line1': 'Jl. Ahmad Yani',
            'city': 'Pontianak',
            'postcode': '78124',
            'state': 'Kalimantan Barat',
            'isDefault': true,
          },
        ],
      };

      final UserModel userModel = UserModel.fromJson(json);
      expect(() => userModel.defaultAddress, returnsNormally);
      expect(userModel.defaultAddress?.id, equals('addr-ptk-1'));
    });

    test('defaultAddress returns null if addresses list is empty', () {
      const User user = User(
        id: 'u-empty',
        name: 'Empty Address User',
        email: 'empty@suruh.id',
        phone: '0800000000',
        role: UserRole.customer,
        addresses: <Address>[],
      );

      expect(user.defaultAddress, isNull);
    });
  });
}
