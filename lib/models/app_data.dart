import 'package:flutter/material.dart';

import 'customer.dart';
import 'product.dart';

/// Mock data layer. In a production deployment this would be backed by
/// a remote API + local cache; for the demo we keep static seed data so
/// the UI is fully interactive.
class AppData {
  AppData._();

  // ----- Mauritania-specific seed cities -----
  static const List<String> cities = [
    'نواكشوط',
    'نواذيبو',
    'روصو',
    'كيفه',
    'نواكشوط الشمالية',
    'أطار',
    'زويرات',
    'ألاق',
    'بوتلميت',
    'اكجوجت',
  ];

  static const List<Product> retailProducts = [
    Product(
      id: 'R-001',
      name: 'أرز بسمتي 5 كغ',
      category: ProductCategory.groceries,
      unitPrice: 320,
      stock: 48,
      icon: Icons.rice_bowl_outlined,
      color: Color(0xFFD9A24E),
    ),
    Product(
      id: 'R-002',
      name: 'سكر أبيض 1 كغ',
      category: ProductCategory.groceries,
      unitPrice: 65,
      stock: 120,
      icon: Icons.grain_outlined,
      color: Color(0xFF6FB1E0),
    ),
    Product(
      id: 'R-003',
      name: 'زيت دوار الشمس 1 لتر',
      category: ProductCategory.groceries,
      unitPrice: 180,
      stock: 32,
      lowStockThreshold: 15,
      icon: Icons.water_drop_outlined,
      color: Color(0xFFE0B144),
    ),
    Product(
      id: 'R-004',
      name: 'حليب بودرة 900غ',
      category: ProductCategory.dairy,
      unitPrice: 450,
      stock: 8,
      lowStockThreshold: 10,
      icon: Icons.icecream_outlined,
      color: Color(0xFFB8C7E0),
    ),
    Product(
      id: 'R-005',
      name: 'شاي أخضر علبة 200غ',
      category: ProductCategory.beverages,
      unitPrice: 280,
      stock: 64,
      icon: Icons.local_cafe_outlined,
      color: Color(0xFF6FAE82),
    ),
    Product(
      id: 'R-006',
      name: 'صابون غسيل 6 قطع',
      category: ProductCategory.hygiene,
      unitPrice: 220,
      stock: 28,
      icon: Icons.soap_outlined,
      color: Color(0xFF9B7FE0),
    ),
    Product(
      id: 'R-007',
      name: 'معجون أسنان 100مل',
      category: ProductCategory.hygiene,
      unitPrice: 145,
      stock: 4,
      lowStockThreshold: 10,
      icon: Icons.clean_hands_outlined,
      color: Color(0xFF4FB3D9),
    ),
    Product(
      id: 'R-008',
      name: 'ماء معدني 1.5 لتر',
      category: ProductCategory.beverages,
      unitPrice: 35,
      stock: 240,
      icon: Icons.local_drink_outlined,
      color: Color(0xFF7FB3E0),
    ),
  ];

  static const List<Product> wholesaleProducts = [
    Product(
      id: 'W-001',
      name: 'أرز بسمتي كرتون 12×5كغ',
      category: ProductCategory.groceries,
      unitPrice: 3500,
      cartonPrice: 3500,
      cartonSize: 12,
      stock: 180,
      icon: Icons.all_inbox_outlined,
      color: Color(0xFFD9A24E),
      batchNumber: 'B-2026-001',
    ),
    Product(
      id: 'W-002',
      name: 'سكر كرتون 24×1كغ',
      category: ProductCategory.groceries,
      unitPrice: 1450,
      cartonPrice: 1450,
      cartonSize: 24,
      stock: 96,
      icon: Icons.all_inbox_outlined,
      color: Color(0xFF6FB1E0),
      batchNumber: 'B-2026-014',
    ),
    Product(
      id: 'W-003',
      name: 'زيت 12×1لتر',
      category: ProductCategory.groceries,
      unitPrice: 2050,
      cartonPrice: 2050,
      cartonSize: 12,
      stock: 14,
      lowStockThreshold: 20,
      icon: Icons.all_inbox_outlined,
      color: Color(0xFFE0B144),
      batchNumber: 'B-2026-007',
    ),
    Product(
      id: 'W-004',
      name: 'حليب بودرة 8×900غ',
      category: ProductCategory.dairy,
      unitPrice: 3400,
      cartonPrice: 3400,
      cartonSize: 8,
      stock: 42,
      icon: Icons.all_inbox_outlined,
      color: Color(0xFFB8C7E0),
      batchNumber: 'B-2026-022',
    ),
  ];

  static final List<Customer> customers = [
    Customer(
      id: 'C-001',
      name: 'بقالة السلام',
      phone: '22123456',
      city: 'نواكشوط',
      outstandingDebt: 18500,
      totalPurchases: 248000,
      totalProfit: 38200,
      lastInvoiceDate: DateTime(2026, 8, 12),
    ),
    Customer(
      id: 'C-002',
      name: 'مؤسسة الفردوس التجارية',
      phone: '33876543',
      city: 'نواذيبو',
      outstandingDebt: 42300,
      totalPurchases: 612000,
      totalProfit: 95400,
      lastInvoiceDate: DateTime(2026, 8, 15),
    ),
    Customer(
      id: 'C-003',
      name: 'محل الأمل',
      phone: '44112233',
      city: 'روصو',
      outstandingDebt: 0,
      totalPurchases: 89000,
      totalProfit: 14200,
      lastInvoiceDate: DateTime(2026, 7, 28),
    ),
    Customer(
      id: 'C-004',
      name: 'سوق النعمة',
      phone: '22334455',
      city: 'كيفه',
      outstandingDebt: 12800,
      totalPurchases: 156000,
      totalProfit: 23800,
      lastInvoiceDate: DateTime(2026, 8, 10),
    ),
    Customer(
      id: 'C-005',
      name: 'متجر الريان',
      phone: '36987452',
      city: 'نواكشوط الشمالية',
      outstandingDebt: 5600,
      totalPurchases: 67000,
      totalProfit: 9100,
      lastInvoiceDate: DateTime(2026, 8, 17),
    ),
  ];

  static final List<Supplier> suppliers = [
    Supplier(
      id: 'S-001',
      name: 'شركة الإمداد الدولية',
      country: 'الصين',
      contact: 'shanghai_supply@example.com',
      payable: 285000,
      totalOrders: 1240000,
      lastOrderDate: DateTime(2026, 8, 1),
      category: 'استيراد بحري',
    ),
    Supplier(
      id: 'S-002',
      name: 'مؤسسة المغرب التجارية',
      country: 'المغرب',
      contact: '+212 6 12 34 56 78',
      payable: 94500,
      totalOrders: 460000,
      lastOrderDate: DateTime(2026, 7, 22),
      category: 'استيراد بري',
    ),
    Supplier(
      id: 'S-003',
      name: 'سوق الجملة دكار',
      country: 'السنغال',
      contact: 'dakar_bulk@example.com',
      payable: 0,
      totalOrders: 215000,
      lastOrderDate: DateTime(2026, 8, 11),
      category: 'استيراد محلي إقليمي',
    ),
    Supplier(
      id: 'S-004',
      name: 'مزارع وادي السارو',
      country: 'تركيا',
      contact: 'istanbul_agri@example.com',
      payable: 167800,
      totalOrders: 540000,
      lastOrderDate: DateTime(2026, 7, 5),
      category: 'استيراد بحري',
    ),
  ];

  static final List<Invoice> invoices = [
    Invoice(
      id: 'INV-2026-0042',
      customerId: 'C-001',
      date: DateTime(2026, 8, 12),
      total: 18500,
      paid: 0,
      items: [
        CartLine(
          product: retailProducts[0],
          quantity: 10,
        ),
        CartLine(
          product: retailProducts[4],
          quantity: 20,
        ),
      ],
    ),
    Invoice(
      id: 'INV-2026-0041',
      customerId: 'C-002',
      date: DateTime(2026, 8, 15),
      total: 42300,
      paid: 0,
      items: [
        CartLine(
          product: retailProducts[2],
          quantity: 60,
        ),
        CartLine(
          product: retailProducts[5],
          quantity: 50,
        ),
      ],
    ),
    Invoice(
      id: 'INV-2026-0040',
      customerId: 'C-004',
      date: DateTime(2026, 8, 10),
      total: 12800,
      paid: 0,
      items: [
        CartLine(
          product: retailProducts[1],
          quantity: 80,
        ),
      ],
    ),
  ];
}
