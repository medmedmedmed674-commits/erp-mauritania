import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Supported app languages.
enum AppLanguage {
  /// Arabic — Right-to-Left layout.
  arabic('العربية', 'ar'),

  /// French — Left-to-Right layout (Mauritania's other official
  /// business language).
  french('Français', 'fr');

  const AppLanguage(this.displayName, this.code);

  /// User-facing name in the language itself (used by the
  /// LanguageSwitcher dropdown).
  final String displayName;

  /// ISO 639-1 code (used by MaterialApp.locale + Material localizations).
  final String code;
}

/// Centralized runtime language manager.
///
/// Listens to changes via [notifyListeners] so any widget built with
/// `context.watch<LocaleProvider>()` rebuilds when the user toggles
/// between Arabic and French.
///
/// ## Usage
/// Wrap the root [MaterialApp] in a [ChangeNotifierProvider] of this
/// type, then:
///   - Read the active [AppLanguage] via `context.watch<LocaleProvider>().language`.
///   - Read the active [TextDirection] via `context.watch<LocaleProvider>().textDirection`.
///   - Read translated strings via `context.watch<LocaleProvider>().t(key)`.
///   - Switch languages via `context.read<LocaleProvider>().setLanguage(...)`.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider({AppLanguage initial = AppLanguage.arabic})
      : _language = initial;

  AppLanguage _language;

  /// The currently active language.
  AppLanguage get language => _language;

  /// The active [Locale] (used by MaterialApp.locale).
  Locale get locale => Locale(_language.code);

  /// Whether the layout should be right-to-left.
  bool get isRtl => _language == AppLanguage.arabic;

  /// The active [TextDirection].
  TextDirection get textDirection =>
      _language == AppLanguage.arabic ? TextDirection.rtl : TextDirection.ltr;

  /// Switches the active language. Notifies all listeners so the
  /// whole app rebuilds with the new direction + strings.
  void setLanguage(AppLanguage next) {
    if (_language == next) return;
    _language = next;
    notifyListeners();
  }

  /// Convenience toggle: Arabic → French → Arabic.
  void toggle() {
    setLanguage(
      _language == AppLanguage.arabic ? AppLanguage.french : AppLanguage.arabic,
    );
  }

  /// Translation entry point. Falls back to the key itself if no
  /// translation is registered — that way missing keys are immediately
  /// visible during development but never crash the app.
  String t(String key) {
    final map = _strings[_language] ?? const <String, String>{};
    return map[key] ?? _strings[AppLanguage.arabic]?[key] ?? key;
  }

  /// All app strings, keyed by language.
  ///
  /// Add new keys here as features are added. Always provide an Arabic
  /// entry first (it's the fallback).
  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.arabic: {
      // App-level
      'app.title': 'نظام ERP موريتانيا',
      'app.security': 'نظام آمن ومشفّر بالكامل لحماية بياناتك المالية',

      // Welcome screen
      'welcome.greeting': 'أهلاً وسهلاً بك',
      'welcome.subtitle': 'في نظام الإدارة المتكامل لمؤسستك',
      'welcome.choose_role': 'اختر نوع نشاطك التجاري',
      'welcome.choose_role.subtitle':
          'سيتم توجيهك تلقائياً إلى لوحة التحكم المناسبة لنشاطك',
      'welcome.retail.title': 'مجمع / متجر تجاري',
      'welcome.retail.hint': 'Retail & Supermarket',
      'welcome.retail.desc':
          'نقطة بيع سريعة، إدارة مخزون وزبناء ومشتريات، مناسب للمتاجر الصغيرة والمتوسطة والمجمعات التجارية.',
      'welcome.retail.cta': 'ادخل كتاجر تجزئة',
      'welcome.wholesale.title': 'تاجر جملة / مستودعات وتوزيع',
      'welcome.wholesale.hint': 'Wholesale & Distribution',
      'welcome.wholesale.desc':
          'بيع بالجملة، إدارة مخازن متعددة، استيراد وموردين، وتحليلات تنفيذية لمؤسسات التوزيع الكبرى.',
      'welcome.wholesale.cta': 'ادخل كتاجر جملة',

      // Common
      'common.cancel': 'إلغاء',
      'common.save': 'حفظ',
      'common.delete': 'حذف',
      'common.edit': 'تعديل',
      'common.close': 'إغلاق',
      'common.confirm': 'تأكيد',
      'common.search': 'بحث',
      'common.add': 'إضافة',
      'common.loading': 'جاري التحميل…',
      'common.saving': 'جاري الحفظ…',

      // Auth
      'auth.login': 'تسجيل الدخول',
      'auth.register': 'إنشاء حساب جديد',
      'auth.phone': 'رقم الهاتف أو البريد الإلكتروني',
      'auth.password': 'كلمة المرور',
      'auth.remember_me': 'تذكّرني',
      'auth.forgot_password': 'نسيت كلمة المرور؟',
      'auth.business_name': 'اسم المؤسسة / المتجر',
      'auth.owner_name': 'اسم المالك',
      'auth.phone_label': 'رقم الهاتف الموريتاني (8 أرقام)',
      'auth.city': 'المدينة / المنطقة',
      'auth.email_optional': 'البريد الإلكتروني (اختياري)',
      'auth.confirm_password': 'تأكيد كلمة المرور',
      'auth.login_button': 'دخول',
      'auth.register_button': 'إنشاء الحساب',

      // Retail tabs
      'retail.tab.pos': 'نقطة البيع',
      'retail.tab.customers': 'الزبناء والديون',
      'retail.tab.inventory': 'المخزن والمخزون',
      'retail.tab.purchases': 'إدارة المشتريات',
      'retail.tab.expenses': 'إدارة المصروفات',
      'retail.tab.analytics': 'التحليلات',

      // POS
      'pos.products': 'المنتجات',
      'pos.cart': 'السلة الحالية',
      'pos.empty_cart': 'السلة فارغة',
      'pos.checkout': 'إتمام الدفع وإصدار الفاتورة',
      'pos.invoice.success': 'تمت عملية البيع بنجاح',

      // Customers
      'customers.title': 'إدارة الزبناء والديون',
      'customers.subtitle':
          'سجل العملاء، الأرصدة المستحقة، وهامش الربح لكل زبون',
      'customers.add': 'إضافة زبون جديد',
      'customers.search': 'ابحث بالاسم أو رقم الهاتف…',
      'customers.empty': 'لا يوجد زبناء مطابقون',
      'customers.pay': 'تسديد',
      'customers.settled': 'خالص',
      'customers.add_dialog.title': 'إضافة زبون جديد',
      'customers.add_dialog.name': 'اسم الزبون',
      'customers.add_dialog.phone': 'رقم الهاتف الموريتاني (8 أرقام)',
      'customers.add_dialog.city': 'المدينة',
      'customers.add_dialog.email': 'البريد الإلكتروني (اختياري)',
      'customers.add_dialog.opening_debt': 'رصيد افتتاحي للدين (اختياري)',
      'customers.add_dialog.save': 'حفظ الزبون',
      'customers.delete.confirm.title': 'تأكيد حذف الزبون',
      'customers.delete.success': 'تم حذف الزبون',
      'customers.payment.title': 'تسديد الدين',
      'customers.payment.amount': 'مبلغ الدفعة (أوقية)',
      'customers.payment.confirm': 'تأكيد الدفعة',
      'customers.payment.success': 'تم تسجيل الدفعة بنجاح',
      'customers.payment.error_amount': 'أدخل مبلغاً صحيحاً',
      'customers.payment.error_exceeds': 'المبلغ أكبر من الدين الحالي',
      'customers.details.total_purchases': 'إجمالي الشراء',
      'customers.details.net_profit': 'صافي الربح',
      'customers.details.current_debt': 'الدين الحالي',
      'customers.details.invoices': 'الفواتير',
      'customers.details.invoices_count': 'فاتورة',
      'customers.details.show_all': 'عرض كافة الفواتير',
      'customers.details.show_less': 'عرض أقل',
      'customers.details.delete_customer': 'حذف الزبون',
      'customers.details.invoice_search': 'ابحث برقم الفاتورة أو المبلغ…',
      'customers.details.empty_invoices': 'لا توجد فواتير مطابقة',
      'customers.details.no_invoices': 'لا توجد فواتير سابقة',
      'customers.details.balance_due': 'متبقي',

      // Inventory
      'inventory.title': 'المخزن والمخزون',
      'inventory.subtitle':
          'اضغط على ⋮ للتعديل أو الحذف — اضغط مطولاً للتحديد المتعدد',
      'inventory.add': 'إضافة منتج جديد',
      'inventory.search': 'ابحث عن صنف…',
      'inventory.empty': 'لا توجد أصناف مطابقة',
      'inventory.empty_subtitle': 'جرّب تعديل البحث أو الفلاتر',
      'inventory.add_dialog.title': 'إضافة منتج جديد',
      'inventory.edit_dialog.title': 'تعديل المنتج',
      'inventory.add_dialog.name': 'اسم المنتج',
      'inventory.add_dialog.retail_price': 'سعر البيع (أوقية)',
      'inventory.add_dialog.wholesale_cost': 'تكلفة الجملة',
      'inventory.add_dialog.stock': 'الكمية في المخزون',
      'inventory.add_dialog.category': 'الفئة',
      'inventory.add_dialog.save': 'حفظ المنتج',
      'inventory.add_dialog.save_edit': 'حفظ التعديلات',
      'inventory.add_dialog.pick_image': 'إضافة صورة المنتج',
      'inventory.add_dialog.image_hint': 'PNG / JPG — اختياري',
      'inventory.delete.confirm.title': 'تأكيد حذف المنتج',
      'inventory.delete.success': 'تم حذف المنتج',
      'inventory.menu.edit': 'تعديل المنتج',
      'inventory.menu.delete': 'حذف المنتج',
      'inventory.bulk.confirm.title': 'تأكيد حذف المنتجات',
      'inventory.bulk.delete': 'حذف المحدد',
      'inventory.bulk.select_all': 'تحديد الكل',
      'inventory.bulk.selected': 'محدد',
      'inventory.save.success': 'تمت إضافة المنتج بنجاح',
      'inventory.save.edit_success': 'تم تحديث المنتج بنجاح',
      'inventory.save.fail': 'فشل الحفظ',

      // Purchases
      'purchases.title': 'إدارة المشتريات',
      'purchases.subtitle':
          'كتالوج السوق مشتق من مخزونك — اضغط "تعديل السعر" لتحديث الأسعار حسب المورد',
      'purchases.catalog.title': 'كتالوج سوق الجملة',
      'purchases.catalog.subtitle': 'مزامنة تلقائية مع مخزونك الحالي',
      'purchases.supplier.name': 'اسم المورد',
      'purchases.supplier.phone': 'رقم واتساب للمورد (8 أرقام)',
      'purchases.total': 'إجمالي الطلب',
      'purchases.empty_cart': 'لم تختر أي صنف بعد',
      'purchases.empty_cart.subtitle': 'حدد الكميات من الكتالوج',
      'purchases.send_whatsapp': 'إرسال الطلب للمورد عبر واتساب',
      'purchases.edit_price': 'تعديل سعر الكرتون',
      'purchases.edit_price.hint':
          'السعر الحالي مستمد من التكلفة. أدخل السعر الجديد للمورد الحالي:',
      'purchases.edit_price.label': 'سعر الكرتون (أوقية)',
      'purchases.edit_price.save': 'حفظ السعر',
      'purchases.edit_price.reset': 'استعادة السعر الافتراضي',
      'purchases.price_custom': 'سعر مخصص',
      'purchases.remove_item': 'حذف من الطلب',
      'purchases.empty_catalog': 'لا توجد منتجات في المخزون',
      'purchases.empty_catalog.subtitle': 'أضف منتجات أولاً من تبويب المخزون لتظهر هنا',

      // Expenses
      'expenses.title': 'إدارة المصروفات',
      'expenses.subtitle':
          'المصاريف التشغيلية: إيجار، صيانات، فواتير، رواتب',
      'expenses.add': 'إضافة مصروف جديد',
      'expenses.add_dialog.title': 'إضافة مصروف جديد',
      'expenses.add_dialog.category': 'نوع المصروف',
      'expenses.add_dialog.amount': 'المبلغ (أوقية)',
      'expenses.add_dialog.date': 'التاريخ',
      'expenses.add_dialog.note': 'ملاحظات (اختياري)',
      'expenses.add_dialog.save': 'حفظ المصروف',
      'expenses.delete.title': 'حذف المصروف',
      'expenses.delete.success': 'تم حذف المصروف',
      'expenses.empty': 'لا توجد مصروفات مسجلة',
      'expenses.by_category': 'حسب الفئة',

      // Analytics
      'analytics.title': 'التحليلات اليومية',
      'analytics.subtitle': 'اختر يوماً لعرض مبيعاته وأرباحه وفواتيره',
      'analytics.today': 'اليوم',
      'analytics.selected_date': 'التاريخ المحدد',
      'analytics.change': 'تغيير',
      'analytics.total_sales': 'إجمالي المبيعات',
      'analytics.net_profit': 'صافي الربح',
      'analytics.invoice_count': 'عدد الفواتير',
      'analytics.avg_invoice': 'متوسط الفاتورة',
      'analytics.invoices_today': 'فواتير هذا اليوم',
      'analytics.tap_hint': 'اضغط على أي فاتورة لعرضها وطباعتها',
      'analytics.empty': 'لا توجد فواتير في هذا اليوم',
      'analytics.empty.subtitle': 'اختر يوماً آخر أو سجّل مبيعات جديدة من نقطة البيع',
    },
    AppLanguage.french: {
      // App-level
      'app.title': 'ERP Mauritanie',
      'app.security':
          'Système sécurisé et entièrement chiffré pour protéger vos données financières',

      // Welcome screen
      'welcome.greeting': 'Bienvenue',
      'welcome.subtitle': 'Dans le système de gestion intégré de votre entreprise',
      'welcome.choose_role': 'Choisissez votre type d\'activité',
      'welcome.choose_role.subtitle':
          'Vous serez automatiquement dirigé vers le tableau de bord adapté à votre activité',
      'welcome.retail.title': 'Magasin / Commerce de détail',
      'welcome.retail.hint': 'Retail & Supermarket',
      'welcome.retail.desc':
          'Point de vente rapide, gestion des stocks, clients et achats. Convient aux petits et moyens commerces.',
      'welcome.retail.cta': 'Entrer comme détaillant',
      'welcome.wholesale.title': 'Grossiste / Entrepôts et distribution',
      'welcome.wholesale.hint': 'Wholesale & Distribution',
      'welcome.wholesale.desc':
          'Vente en gros, gestion multi-entrepôts, importation et fournisseurs, analytique exécutive.',
      'welcome.wholesale.cta': 'Entrer comme grossiste',

      // Common
      'common.cancel': 'Annuler',
      'common.save': 'Enregistrer',
      'common.delete': 'Supprimer',
      'common.edit': 'Modifier',
      'common.close': 'Fermer',
      'common.confirm': 'Confirmer',
      'common.search': 'Rechercher',
      'common.add': 'Ajouter',
      'common.loading': 'Chargement…',
      'common.saving': 'Enregistrement…',

      // Auth
      'auth.login': 'Connexion',
      'auth.register': 'Créer un compte',
      'auth.phone': 'Téléphone ou e-mail',
      'auth.password': 'Mot de passe',
      'auth.remember_me': 'Se souvenir de moi',
      'auth.forgot_password': 'Mot de passe oublié ?',
      'auth.business_name': 'Nom de l\'entreprise / magasin',
      'auth.owner_name': 'Nom du propriétaire',
      'auth.phone_label': 'Téléphone mauritanien (8 chiffres)',
      'auth.city': 'Ville / Région',
      'auth.email_optional': 'E-mail (facultatif)',
      'auth.confirm_password': 'Confirmer le mot de passe',
      'auth.login_button': 'Connexion',
      'auth.register_button': 'Créer le compte',

      // Retail tabs
      'retail.tab.pos': 'Point de vente',
      'retail.tab.customers': 'Clients & Dettes',
      'retail.tab.inventory': 'Stock & Inventaire',
      'retail.tab.purchases': 'Achats',
      'retail.tab.expenses': 'Dépenses',
      'retail.tab.analytics': 'Analytique',

      // POS
      'pos.products': 'Produits',
      'pos.cart': 'Panier',
      'pos.empty_cart': 'Panier vide',
      'pos.checkout': 'Paiement & Facture',
      'pos.invoice.success': 'Vente effectuée avec succès',

      // Customers
      'customers.title': 'Gestion des clients & dettes',
      'customers.subtitle':
          'Registre des clients, soldes dus et marge bénéficiaire par client',
      'customers.add': 'Ajouter un client',
      'customers.search': 'Rechercher par nom ou téléphone…',
      'customers.empty': 'Aucun client correspondant',
      'customers.pay': 'Payer',
      'customers.settled': 'Soldé',
      'customers.add_dialog.title': 'Ajouter un nouveau client',
      'customers.add_dialog.name': 'Nom du client',
      'customers.add_dialog.phone': 'Téléphone mauritanien (8 chiffres)',
      'customers.add_dialog.city': 'Ville',
      'customers.add_dialog.email': 'E-mail (facultatif)',
      'customers.add_dialog.opening_debt': 'Solde d\'ouverture de dette (facultatif)',
      'customers.add_dialog.save': 'Enregistrer le client',
      'customers.delete.confirm.title': 'Confirmer la suppression du client',
      'customers.delete.success': 'Client supprimé',
      'customers.payment.title': 'Payer la dette',
      'customers.payment.amount': 'Montant du paiement (ouguiya)',
      'customers.payment.confirm': 'Confirmer le paiement',
      'customers.payment.success': 'Paiement enregistré avec succès',
      'customers.payment.error_amount': 'Entrez un montant valide',
      'customers.payment.error_exceeds': 'Le montant dépasse la dette actuelle',
      'customers.details.total_purchases': 'Total achats',
      'customers.details.net_profit': 'Bénéfice net',
      'customers.details.current_debt': 'Dette actuelle',
      'customers.details.invoices': 'Factures',
      'customers.details.invoices_count': 'factures',
      'customers.details.show_all': 'Voir toutes les factures',
      'customers.details.show_less': 'Voir moins',
      'customers.details.delete_customer': 'Supprimer le client',
      'customers.details.invoice_search': 'Rechercher par n° de facture ou montant…',
      'customers.details.empty_invoices': 'Aucune facture correspondante',
      'customers.details.no_invoices': 'Aucune facture antérieure',
      'customers.details.balance_due': 'Reste dû',

      // Inventory
      'inventory.title': 'Stock & Inventaire',
      'inventory.subtitle':
          'Appuyez sur ⋮ pour modifier ou supprimer — appui long pour la sélection multiple',
      'inventory.add': 'Ajouter un produit',
      'inventory.search': 'Rechercher un article…',
      'inventory.empty': 'Aucun article correspondant',
      'inventory.empty_subtitle': 'Modifiez la recherche ou les filtres',
      'inventory.add_dialog.title': 'Ajouter un nouveau produit',
      'inventory.edit_dialog.title': 'Modifier le produit',
      'inventory.add_dialog.name': 'Nom du produit',
      'inventory.add_dialog.retail_price': 'Prix de vente (ouguiya)',
      'inventory.add_dialog.wholesale_cost': 'Coût de gros',
      'inventory.add_dialog.stock': 'Quantité en stock',
      'inventory.add_dialog.category': 'Catégorie',
      'inventory.add_dialog.save': 'Enregistrer le produit',
      'inventory.add_dialog.save_edit': 'Enregistrer les modifications',
      'inventory.add_dialog.pick_image': 'Ajouter une image',
      'inventory.add_dialog.image_hint': 'PNG / JPG — facultatif',
      'inventory.delete.confirm.title': 'Confirmer la suppression du produit',
      'inventory.delete.success': 'Produit supprimé',
      'inventory.menu.edit': 'Modifier le produit',
      'inventory.menu.delete': 'Supprimer le produit',
      'inventory.bulk.confirm.title': 'Confirmer la suppression des produits',
      'inventory.bulk.delete': 'Supprimer la sélection',
      'inventory.bulk.select_all': 'Tout sélectionner',
      'inventory.bulk.selected': 'sélectionné(s)',
      'inventory.save.success': 'Produit ajouté avec succès',
      'inventory.save.edit_success': 'Produit mis à jour avec succès',
      'inventory.save.fail': 'Échec de l\'enregistrement',

      // Purchases
      'purchases.title': 'Gestion des achats',
      'purchases.subtitle':
          'Le catalogue est dérivé de votre stock — appuyez sur "Modifier le prix" pour ajuster les prix par fournisseur',
      'purchases.catalog.title': 'Catalogue de gros',
      'purchases.catalog.subtitle': 'Synchronisé automatiquement avec votre stock',
      'purchases.supplier.name': 'Nom du fournisseur',
      'purchases.supplier.phone': 'WhatsApp du fournisseur (8 chiffres)',
      'purchases.total': 'Total de la commande',
      'purchases.empty_cart': 'Aucun article sélectionné',
      'purchases.empty_cart.subtitle': 'Sélectionnez les quantités dans le catalogue',
      'purchases.send_whatsapp': 'Envoyer la commande au fournisseur via WhatsApp',
      'purchases.edit_price': 'Modifier le prix du carton',
      'purchases.edit_price.hint':
          'Le prix actuel est dérivé du coût. Entrez le nouveau prix pour ce fournisseur :',
      'purchases.edit_price.label': 'Prix du carton (ouguiya)',
      'purchases.edit_price.save': 'Enregistrer le prix',
      'purchases.edit_price.reset': 'Restaurer le prix par défaut',
      'purchases.price_custom': 'Prix personnalisé',
      'purchases.remove_item': 'Retirer de la commande',
      'purchases.empty_catalog': 'Aucun produit en stock',
      'purchases.empty_catalog.subtitle': 'Ajoutez des produits depuis l\'onglet Stock pour les voir ici',

      // Expenses
      'expenses.title': 'Gestion des dépenses',
      'expenses.subtitle':
          'Dépenses opérationnelles : loyer, maintenance, factures, salaires',
      'expenses.add': 'Ajouter une dépense',
      'expenses.add_dialog.title': 'Ajouter une nouvelle dépense',
      'expenses.add_dialog.category': 'Type de dépense',
      'expenses.add_dialog.amount': 'Montant (ouguiya)',
      'expenses.add_dialog.date': 'Date',
      'expenses.add_dialog.note': 'Notes (facultatif)',
      'expenses.add_dialog.save': 'Enregistrer la dépense',
      'expenses.delete.title': 'Supprimer la dépense',
      'expenses.delete.success': 'Dépense supprimée',
      'expenses.empty': 'Aucune dépense enregistrée',
      'expenses.by_category': 'Par catégorie',

      // Analytics
      'analytics.title': 'Analytique quotidienne',
      'analytics.subtitle': 'Choisissez un jour pour voir les ventes, profits et factures',
      'analytics.today': 'Aujourd\'hui',
      'analytics.selected_date': 'Date sélectionnée',
      'analytics.change': 'Changer',
      'analytics.total_sales': 'Total des ventes',
      'analytics.net_profit': 'Bénéfice net',
      'analytics.invoice_count': 'Nombre de factures',
      'analytics.avg_invoice': 'Facture moyenne',
      'analytics.invoices_today': 'Factures de ce jour',
      'analytics.tap_hint': 'Appuyez sur une facture pour l\'afficher et l\'imprimer',
      'analytics.empty': 'Aucune facture ce jour',
      'analytics.empty.subtitle': 'Choisissez un autre jour ou enregistrez de nouvelles ventes',
    },
  };
}

/// Convenience extension on [BuildContext] for quick access to the
/// active [LocaleProvider] and its translation function.
extension LocaleContext on BuildContext {
  /// The active [LocaleProvider]. Throws if no provider is in scope.
  LocaleProvider get locale => watch<LocaleProvider>();

  /// Shorthand for `read<LocaleProvider>().t(key)`.
  String tr(String key) => read<LocaleProvider>().t(key);
}
