import '../../../../domain/entities/address.dart';
import '../../../../domain/entities/user.dart';
import '../../../models/address_model.dart';
import '../../../models/user_model.dart';

/// Password accepted for every seeded demo account.
const String kDemoPassword = 'demo1234';

const AddressModel kHomeAddress = AddressModel(
  id: 'addr-home',
  label: AddressLabel.home,
  line1: 'Jl. Gajah Mada No. 45',
  line2: 'Benua Melayu Darat, Pontianak Selatan',
  city: 'Pontianak',
  postcode: '78122',
  state: 'Kalimantan Barat',
  latitude: -0.0381,
  longitude: 109.3415,
  notes: 'Pagar hitam samping minimarket',
  isDefault: true,
);

const AddressModel kWorkAddress = AddressModel(
  id: 'addr-work',
  label: AddressLabel.work,
  line1: 'Jl. Jenderal Ahmad Yani No. 1',
  line2: 'Kawasan Ayani Mega Mall, Pontianak Selatan',
  city: 'Pontianak',
  postcode: '78121',
  state: 'Kalimantan Barat',
  latitude: -0.0522,
  longitude: 109.3498,
  notes: 'Titip di lobby resepsionis',
);

const AddressModel kParentsAddress = AddressModel(
  id: 'addr-parents',
  label: AddressLabel.other,
  line1: 'Jl. Tanjungpura No. 88',
  line2: 'Benua Melayu Laut, Pontianak Kota',
  city: 'Pontianak',
  postcode: '78123',
  state: 'Kalimantan Barat',
  latitude: -0.0275,
  longitude: 109.3360,
);

/// The three personas the login screen can switch between.
final List<UserModel> kSeedUsers = <UserModel>[
  UserModel(
    id: 'u-customer',
    name: 'Aisyah Putri',
    email: 'customer@suruh.app',
    phone: '0812-3456-7890',
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
    name: 'Budi Santoso',
    email: 'partner@suruh.app',
    phone: '0816-2284-4410',
    role: UserRole.restaurantPartner,
    avatarEmoji: '👨🏻‍🔧',
    addresses: const <Address>[kWorkAddress],
    loyaltyPoints: 0,
    memberTier: 'Mitra',
    createdAt: DateTime(2023, 11, 2),
    managedRestaurantId: 'r-06',
  ),
  UserModel(
    id: 'u-rider',
    name: 'Agus Pratama',
    email: 'rider@suruh.app',
    phone: '0819-7701-1123',
    role: UserRole.deliveryPartner,
    avatarEmoji: '🧑🏽',
    addresses: const <Address>[kHomeAddress],
    loyaltyPoints: 0,
    memberTier: 'Mitra Kurir',
    createdAt: DateTime(2024, 1, 9),
  ),
];

/// Reviewer identities used when generating the seeded review corpus.
const List<(String, String, String)> kReviewerPool =
    <(String, String, String)>[
  ('rv-01', 'Nurul Izzati', '👩🏻‍🦰'),
  ('rv-02', 'Tan Chee Meng', '🧑🏻'),
  ('rv-03', 'Rian Saputra', '👨🏽'),
  ('rv-04', 'Ahmad Faizal', '🧔🏽'),
  ('rv-05', 'Dewi Lestari', '👩🏻'),
  ('rv-06', 'Deni Prasetyo', '🧑🏻‍💼'),
  ('rv-07', 'Siti Nabilah', '🧕🏻'),
  ('rv-08', 'Rizal Kurniawan', '👨🏽'),
  ('rv-09', 'Chloe Tan', '👩🏻‍💻'),
  ('rv-10', 'Hafiz Pratama', '🧑🏽‍🦱'),
  ('rv-11', 'Melisa Chen', '👩🏻‍🎨'),
  ('rv-12', 'Fajar Ramadhan', '🧑🏾'),
  ('rv-13', 'Farah Maulida', '🧕🏽'),
  ('rv-14', 'Kevin Wijaya', '👨🏻'),
  ('rv-15', 'Jasmine Surya', '👩🏻‍🍳'),
];

/// Mitra Pelaksana that can be assigned to an order by the demo backend (Plat KB Pontianak).
const List<(String, String, String, String, double)> kRiderPool =
    <(String, String, String, String, double)>[
  ('rd-01', 'Agus Pratama', 'Honda Vario 160', 'KB 4471 AA', 4.9),
  ('rd-02', 'Bambang Irawan', 'Yamaha NMAX', 'KB 8823 QP', 4.8),
  ('rd-03', 'Hendra Wijaya', 'Honda Beat', 'KB 2210 TT', 4.9),
  ('rd-04', 'Rizky Fadillah', 'Yamaha Aerox', 'KB 6635 WX', 4.9),
];
