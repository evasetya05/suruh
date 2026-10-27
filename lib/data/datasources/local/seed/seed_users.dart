import '../../../../domain/entities/address.dart';
import '../../../../domain/entities/user.dart';
import '../../../models/address_model.dart';
import '../../../models/user_model.dart';

/// Password accepted for every seeded demo account.
const String kDemoPassword = 'demo1234';

const AddressModel kHomeAddress = AddressModel(
  id: 'addr-home',
  label: AddressLabel.home,
  line1: 'Unit 12-3, Residensi Suasana',
  line2: 'Jalan Hang Tuah',
  city: 'Kuala Lumpur',
  postcode: '55100',
  state: 'WP Kuala Lumpur',
  latitude: 3.1421,
  longitude: 101.7060,
  notes: 'Guard house will call before entry',
  isDefault: true,
);

const AddressModel kWorkAddress = AddressModel(
  id: 'addr-work',
  label: AddressLabel.work,
  line1: 'Level 21, Menara Binjai',
  line2: '2 Jalan Binjai',
  city: 'Kuala Lumpur',
  postcode: '50450',
  state: 'WP Kuala Lumpur',
  latitude: 3.1592,
  longitude: 101.7148,
  notes: 'Leave at the reception desk',
);

const AddressModel kParentsAddress = AddressModel(
  id: 'addr-parents',
  label: AddressLabel.other,
  line1: '8 Jalan SS2/24',
  line2: 'SS2, Petaling Jaya',
  city: 'Petaling Jaya',
  postcode: '47300',
  state: 'Selangor',
  latitude: 3.1176,
  longitude: 101.6231,
);

/// The three personas the login screen can switch between.
final List<UserModel> kSeedUsers = <UserModel>[
  UserModel(
    id: 'u-customer',
    name: 'Aisyah Rahman',
    email: 'customer@msdevbuild.com',
    phone: '012-345 6789',
    role: UserRole.customer,
    avatarEmoji: '👩🏻',
    addresses: const <Address>[kHomeAddress, kWorkAddress, kParentsAddress],
    favouriteRestaurantIds: const <String>{'r-01', 'r-08', 'r-15'},
    loyaltyPoints: 2480,
    memberTier: 'Gold',
    createdAt: DateTime(2024, 3, 18),
  ),
  UserModel(
    id: 'u-partner',
    name: 'Lim Wei Jian',
    email: 'partner@msdevbuild.com',
    phone: '016-228 4410',
    role: UserRole.restaurantPartner,
    avatarEmoji: '👨🏻‍🍳',
    addresses: const <Address>[kWorkAddress],
    loyaltyPoints: 0,
    memberTier: 'Merchant',
    createdAt: DateTime(2023, 11, 2),
    managedRestaurantId: 'r-06',
  ),
  UserModel(
    id: 'u-rider',
    name: 'Muthu Selvam',
    email: 'rider@msdevbuild.com',
    phone: '019-770 1123',
    role: UserRole.deliveryPartner,
    avatarEmoji: '🧑🏽',
    addresses: const <Address>[kHomeAddress],
    loyaltyPoints: 0,
    memberTier: 'Rider',
    createdAt: DateTime(2024, 1, 9),
  ),
];

/// Reviewer identities used when generating the seeded review corpus.
const List<(String, String, String)> kReviewerPool =
    <(String, String, String)>[
  ('rv-01', 'Nurul Izzati', '👩🏻‍🦰'),
  ('rv-02', 'Tan Chee Meng', '🧑🏻'),
  ('rv-03', 'Priya Suresh', '👩🏽'),
  ('rv-04', 'Ahmad Faizal', '🧔🏽'),
  ('rv-05', 'Wong Li Ping', '👩🏻'),
  ('rv-06', 'Daniel Yap', '🧑🏻‍💼'),
  ('rv-07', 'Siti Nabilah', '🧕🏻'),
  ('rv-08', 'Ravi Kumaran', '👨🏽'),
  ('rv-09', 'Chloe Teoh', '👩🏻‍💻'),
  ('rv-10', 'Hafiz Zainal', '🧑🏽‍🦱'),
  ('rv-11', 'Melissa Chin', '👩🏻‍🎨'),
  ('rv-12', 'Arjun Menon', '🧑🏾'),
  ('rv-13', 'Farah Adilah', '🧕🏽'),
  ('rv-14', 'Kevin Lau', '👨🏻'),
  ('rv-15', 'Jasmine Ooi', '👩🏻‍🍳'),
];

/// Riders that can be assigned to an order by the demo backend.
const List<(String, String, String, String, double)> kRiderPool =
    <(String, String, String, String, double)>[
  ('rd-01', 'Muthu Selvam', 'Honda EX5', 'WVX 4471', 4.9),
  ('rd-02', 'Azman Yusof', 'Yamaha Y15', 'BQC 8823', 4.8),
  ('rd-03', 'Chong Kah Wai', 'Honda RS150', 'VGT 2210', 4.7),
  ('rd-04', 'Suresh Nair', 'Yamaha LC135', 'WPK 6635', 4.9),
];
