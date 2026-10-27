import 'package:food_delivery_app/domain/entities/address.dart';
import 'package:food_delivery_app/domain/entities/user.dart';

/// Fixtures shared across test files.
const Address testAddress = Address(
  id: 'addr-test',
  label: AddressLabel.home,
  line1: 'Unit 1-1, Test Residency',
  line2: 'Jalan Test',
  city: 'Kuala Lumpur',
  postcode: '50000',
  state: 'WP Kuala Lumpur',
  isDefault: true,
);

const User testCustomer = User(
  id: 'u-test',
  name: 'Test Customer',
  email: 'test@msdevbuild.com',
  phone: '012-000 0000',
  role: UserRole.customer,
  addresses: <Address>[testAddress],
);
