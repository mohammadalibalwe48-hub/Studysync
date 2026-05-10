import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:studysync_syria/app/theme.dart';
import 'package:studysync_syria/core/widgets/ambient_background.dart';
import 'package:studysync_syria/core/widgets/animations.dart';
import 'package:studysync_syria/core/widgets/section_header.dart';

/// One element in the periodic table.
class _Element {
  const _Element({
    required this.z,
    required this.symbol,
    required this.name,
    required this.arabicName,
    required this.group,
    required this.period,
    required this.category,
  });

  final int z;
  final String symbol;
  final String name;
  final String arabicName;
  final int group; // 1..18 (we use 19 for lanthanides, 20 for actinides)
  final int period; // 1..7 (we use 8/9 for lanthanide/actinide rows)
  final _Category category;
}

enum _Category {
  alkaliMetal,
  alkalineEarth,
  transition,
  postTransition,
  metalloid,
  nonmetal,
  halogen,
  nobleGas,
  lanthanide,
  actinide,
  unknown,
}

const Map<_Category, ({Color color, String label})> _categoryStyle =
    <_Category, ({Color color, String label})>{
  _Category.alkaliMetal: (color: Color(0xFFE2862F), label: 'فلزات قلوية'),
  _Category.alkalineEarth: (color: Color(0xFFD68A1A), label: 'فلزات قلوية ترابية'),
  _Category.transition: (color: Color(0xFFC9602B), label: 'انتقالية'),
  _Category.postTransition: (color: Color(0xFFB8732A), label: 'ما بعد انتقالية'),
  _Category.metalloid: (color: Color(0xFF8C5A38), label: 'أشباه فلزات'),
  _Category.nonmetal: (color: Color(0xFFA0683C), label: 'لافلزات'),
  _Category.halogen: (color: Color(0xFFEF8E2A), label: 'هالوجينات'),
  _Category.nobleGas: (color: Color(0xFF7A6754), label: 'غازات نبيلة'),
  _Category.lanthanide: (color: Color(0xFFD9A678), label: 'لانثانيدات'),
  _Category.actinide: (color: Color(0xFFB8884F), label: 'أكتينيدات'),
  _Category.unknown: (color: Color(0xFFC4AE8E), label: 'غير معروف'),
};

const List<_Element> _elements = <_Element>[
  _Element(z: 1, symbol: 'H', name: 'Hydrogen', arabicName: 'هيدروجين', group: 1, period: 1, category: _Category.nonmetal),
  _Element(z: 2, symbol: 'He', name: 'Helium', arabicName: 'هيليوم', group: 18, period: 1, category: _Category.nobleGas),
  _Element(z: 3, symbol: 'Li', name: 'Lithium', arabicName: 'ليثيوم', group: 1, period: 2, category: _Category.alkaliMetal),
  _Element(z: 4, symbol: 'Be', name: 'Beryllium', arabicName: 'بيريليوم', group: 2, period: 2, category: _Category.alkalineEarth),
  _Element(z: 5, symbol: 'B', name: 'Boron', arabicName: 'بورون', group: 13, period: 2, category: _Category.metalloid),
  _Element(z: 6, symbol: 'C', name: 'Carbon', arabicName: 'كربون', group: 14, period: 2, category: _Category.nonmetal),
  _Element(z: 7, symbol: 'N', name: 'Nitrogen', arabicName: 'نيتروجين', group: 15, period: 2, category: _Category.nonmetal),
  _Element(z: 8, symbol: 'O', name: 'Oxygen', arabicName: 'أكسجين', group: 16, period: 2, category: _Category.nonmetal),
  _Element(z: 9, symbol: 'F', name: 'Fluorine', arabicName: 'فلور', group: 17, period: 2, category: _Category.halogen),
  _Element(z: 10, symbol: 'Ne', name: 'Neon', arabicName: 'نيون', group: 18, period: 2, category: _Category.nobleGas),
  _Element(z: 11, symbol: 'Na', name: 'Sodium', arabicName: 'صوديوم', group: 1, period: 3, category: _Category.alkaliMetal),
  _Element(z: 12, symbol: 'Mg', name: 'Magnesium', arabicName: 'مغنيسيوم', group: 2, period: 3, category: _Category.alkalineEarth),
  _Element(z: 13, symbol: 'Al', name: 'Aluminium', arabicName: 'ألمنيوم', group: 13, period: 3, category: _Category.postTransition),
  _Element(z: 14, symbol: 'Si', name: 'Silicon', arabicName: 'سيليكون', group: 14, period: 3, category: _Category.metalloid),
  _Element(z: 15, symbol: 'P', name: 'Phosphorus', arabicName: 'فوسفور', group: 15, period: 3, category: _Category.nonmetal),
  _Element(z: 16, symbol: 'S', name: 'Sulfur', arabicName: 'كبريت', group: 16, period: 3, category: _Category.nonmetal),
  _Element(z: 17, symbol: 'Cl', name: 'Chlorine', arabicName: 'كلور', group: 17, period: 3, category: _Category.halogen),
  _Element(z: 18, symbol: 'Ar', name: 'Argon', arabicName: 'أرغون', group: 18, period: 3, category: _Category.nobleGas),
  _Element(z: 19, symbol: 'K', name: 'Potassium', arabicName: 'بوتاسيوم', group: 1, period: 4, category: _Category.alkaliMetal),
  _Element(z: 20, symbol: 'Ca', name: 'Calcium', arabicName: 'كالسيوم', group: 2, period: 4, category: _Category.alkalineEarth),
  _Element(z: 21, symbol: 'Sc', name: 'Scandium', arabicName: 'سكانديوم', group: 3, period: 4, category: _Category.transition),
  _Element(z: 22, symbol: 'Ti', name: 'Titanium', arabicName: 'تيتانيوم', group: 4, period: 4, category: _Category.transition),
  _Element(z: 23, symbol: 'V', name: 'Vanadium', arabicName: 'فاناديوم', group: 5, period: 4, category: _Category.transition),
  _Element(z: 24, symbol: 'Cr', name: 'Chromium', arabicName: 'كروم', group: 6, period: 4, category: _Category.transition),
  _Element(z: 25, symbol: 'Mn', name: 'Manganese', arabicName: 'منغنيز', group: 7, period: 4, category: _Category.transition),
  _Element(z: 26, symbol: 'Fe', name: 'Iron', arabicName: 'حديد', group: 8, period: 4, category: _Category.transition),
  _Element(z: 27, symbol: 'Co', name: 'Cobalt', arabicName: 'كوبالت', group: 9, period: 4, category: _Category.transition),
  _Element(z: 28, symbol: 'Ni', name: 'Nickel', arabicName: 'نيكل', group: 10, period: 4, category: _Category.transition),
  _Element(z: 29, symbol: 'Cu', name: 'Copper', arabicName: 'نحاس', group: 11, period: 4, category: _Category.transition),
  _Element(z: 30, symbol: 'Zn', name: 'Zinc', arabicName: 'زنك', group: 12, period: 4, category: _Category.transition),
  _Element(z: 31, symbol: 'Ga', name: 'Gallium', arabicName: 'غاليوم', group: 13, period: 4, category: _Category.postTransition),
  _Element(z: 32, symbol: 'Ge', name: 'Germanium', arabicName: 'جرمانيوم', group: 14, period: 4, category: _Category.metalloid),
  _Element(z: 33, symbol: 'As', name: 'Arsenic', arabicName: 'زرنيخ', group: 15, period: 4, category: _Category.metalloid),
  _Element(z: 34, symbol: 'Se', name: 'Selenium', arabicName: 'سيلينيوم', group: 16, period: 4, category: _Category.nonmetal),
  _Element(z: 35, symbol: 'Br', name: 'Bromine', arabicName: 'بروم', group: 17, period: 4, category: _Category.halogen),
  _Element(z: 36, symbol: 'Kr', name: 'Krypton', arabicName: 'كريبتون', group: 18, period: 4, category: _Category.nobleGas),
  _Element(z: 37, symbol: 'Rb', name: 'Rubidium', arabicName: 'روبيديوم', group: 1, period: 5, category: _Category.alkaliMetal),
  _Element(z: 38, symbol: 'Sr', name: 'Strontium', arabicName: 'سترانشيوم', group: 2, period: 5, category: _Category.alkalineEarth),
  _Element(z: 39, symbol: 'Y', name: 'Yttrium', arabicName: 'إتريوم', group: 3, period: 5, category: _Category.transition),
  _Element(z: 40, symbol: 'Zr', name: 'Zirconium', arabicName: 'زركونيوم', group: 4, period: 5, category: _Category.transition),
  _Element(z: 41, symbol: 'Nb', name: 'Niobium', arabicName: 'نيوبيوم', group: 5, period: 5, category: _Category.transition),
  _Element(z: 42, symbol: 'Mo', name: 'Molybdenum', arabicName: 'موليبدنوم', group: 6, period: 5, category: _Category.transition),
  _Element(z: 43, symbol: 'Tc', name: 'Technetium', arabicName: 'تكنيشيوم', group: 7, period: 5, category: _Category.transition),
  _Element(z: 44, symbol: 'Ru', name: 'Ruthenium', arabicName: 'روثينيوم', group: 8, period: 5, category: _Category.transition),
  _Element(z: 45, symbol: 'Rh', name: 'Rhodium', arabicName: 'روديوم', group: 9, period: 5, category: _Category.transition),
  _Element(z: 46, symbol: 'Pd', name: 'Palladium', arabicName: 'بلاديوم', group: 10, period: 5, category: _Category.transition),
  _Element(z: 47, symbol: 'Ag', name: 'Silver', arabicName: 'فضة', group: 11, period: 5, category: _Category.transition),
  _Element(z: 48, symbol: 'Cd', name: 'Cadmium', arabicName: 'كادميوم', group: 12, period: 5, category: _Category.transition),
  _Element(z: 49, symbol: 'In', name: 'Indium', arabicName: 'إنديوم', group: 13, period: 5, category: _Category.postTransition),
  _Element(z: 50, symbol: 'Sn', name: 'Tin', arabicName: 'قصدير', group: 14, period: 5, category: _Category.postTransition),
  _Element(z: 51, symbol: 'Sb', name: 'Antimony', arabicName: 'إثمد', group: 15, period: 5, category: _Category.metalloid),
  _Element(z: 52, symbol: 'Te', name: 'Tellurium', arabicName: 'تيلوريوم', group: 16, period: 5, category: _Category.metalloid),
  _Element(z: 53, symbol: 'I', name: 'Iodine', arabicName: 'يود', group: 17, period: 5, category: _Category.halogen),
  _Element(z: 54, symbol: 'Xe', name: 'Xenon', arabicName: 'زينون', group: 18, period: 5, category: _Category.nobleGas),
  _Element(z: 55, symbol: 'Cs', name: 'Caesium', arabicName: 'سيزيوم', group: 1, period: 6, category: _Category.alkaliMetal),
  _Element(z: 56, symbol: 'Ba', name: 'Barium', arabicName: 'باريوم', group: 2, period: 6, category: _Category.alkalineEarth),
  // Lanthanides 57-71 (drawn in their own band).
  _Element(z: 57, symbol: 'La', name: 'Lanthanum', arabicName: 'لانثانوم', group: 3, period: 8, category: _Category.lanthanide),
  _Element(z: 58, symbol: 'Ce', name: 'Cerium', arabicName: 'سيريوم', group: 4, period: 8, category: _Category.lanthanide),
  _Element(z: 59, symbol: 'Pr', name: 'Praseodymium', arabicName: 'برازيوديميوم', group: 5, period: 8, category: _Category.lanthanide),
  _Element(z: 60, symbol: 'Nd', name: 'Neodymium', arabicName: 'نيوديميوم', group: 6, period: 8, category: _Category.lanthanide),
  _Element(z: 61, symbol: 'Pm', name: 'Promethium', arabicName: 'بروميثيوم', group: 7, period: 8, category: _Category.lanthanide),
  _Element(z: 62, symbol: 'Sm', name: 'Samarium', arabicName: 'ساماريوم', group: 8, period: 8, category: _Category.lanthanide),
  _Element(z: 63, symbol: 'Eu', name: 'Europium', arabicName: 'يوروبيوم', group: 9, period: 8, category: _Category.lanthanide),
  _Element(z: 64, symbol: 'Gd', name: 'Gadolinium', arabicName: 'غادولينيوم', group: 10, period: 8, category: _Category.lanthanide),
  _Element(z: 65, symbol: 'Tb', name: 'Terbium', arabicName: 'تربيوم', group: 11, period: 8, category: _Category.lanthanide),
  _Element(z: 66, symbol: 'Dy', name: 'Dysprosium', arabicName: 'ديسبروزيوم', group: 12, period: 8, category: _Category.lanthanide),
  _Element(z: 67, symbol: 'Ho', name: 'Holmium', arabicName: 'هولميوم', group: 13, period: 8, category: _Category.lanthanide),
  _Element(z: 68, symbol: 'Er', name: 'Erbium', arabicName: 'إربيوم', group: 14, period: 8, category: _Category.lanthanide),
  _Element(z: 69, symbol: 'Tm', name: 'Thulium', arabicName: 'ثوليوم', group: 15, period: 8, category: _Category.lanthanide),
  _Element(z: 70, symbol: 'Yb', name: 'Ytterbium', arabicName: 'إتربيوم', group: 16, period: 8, category: _Category.lanthanide),
  _Element(z: 71, symbol: 'Lu', name: 'Lutetium', arabicName: 'لوتيتيوم', group: 17, period: 8, category: _Category.lanthanide),
  // Period 6 main.
  _Element(z: 72, symbol: 'Hf', name: 'Hafnium', arabicName: 'هافنيوم', group: 4, period: 6, category: _Category.transition),
  _Element(z: 73, symbol: 'Ta', name: 'Tantalum', arabicName: 'تانتالوم', group: 5, period: 6, category: _Category.transition),
  _Element(z: 74, symbol: 'W', name: 'Tungsten', arabicName: 'تنغستن', group: 6, period: 6, category: _Category.transition),
  _Element(z: 75, symbol: 'Re', name: 'Rhenium', arabicName: 'رينيوم', group: 7, period: 6, category: _Category.transition),
  _Element(z: 76, symbol: 'Os', name: 'Osmium', arabicName: 'أوزميوم', group: 8, period: 6, category: _Category.transition),
  _Element(z: 77, symbol: 'Ir', name: 'Iridium', arabicName: 'إريديوم', group: 9, period: 6, category: _Category.transition),
  _Element(z: 78, symbol: 'Pt', name: 'Platinum', arabicName: 'بلاتين', group: 10, period: 6, category: _Category.transition),
  _Element(z: 79, symbol: 'Au', name: 'Gold', arabicName: 'ذهب', group: 11, period: 6, category: _Category.transition),
  _Element(z: 80, symbol: 'Hg', name: 'Mercury', arabicName: 'زئبق', group: 12, period: 6, category: _Category.transition),
  _Element(z: 81, symbol: 'Tl', name: 'Thallium', arabicName: 'ثاليوم', group: 13, period: 6, category: _Category.postTransition),
  _Element(z: 82, symbol: 'Pb', name: 'Lead', arabicName: 'رصاص', group: 14, period: 6, category: _Category.postTransition),
  _Element(z: 83, symbol: 'Bi', name: 'Bismuth', arabicName: 'بزموت', group: 15, period: 6, category: _Category.postTransition),
  _Element(z: 84, symbol: 'Po', name: 'Polonium', arabicName: 'بولونيوم', group: 16, period: 6, category: _Category.metalloid),
  _Element(z: 85, symbol: 'At', name: 'Astatine', arabicName: 'أستاتين', group: 17, period: 6, category: _Category.halogen),
  _Element(z: 86, symbol: 'Rn', name: 'Radon', arabicName: 'رادون', group: 18, period: 6, category: _Category.nobleGas),
  _Element(z: 87, symbol: 'Fr', name: 'Francium', arabicName: 'فرانسيوم', group: 1, period: 7, category: _Category.alkaliMetal),
  _Element(z: 88, symbol: 'Ra', name: 'Radium', arabicName: 'راديوم', group: 2, period: 7, category: _Category.alkalineEarth),
  // Actinides 89-103.
  _Element(z: 89, symbol: 'Ac', name: 'Actinium', arabicName: 'أكتينيوم', group: 3, period: 9, category: _Category.actinide),
  _Element(z: 90, symbol: 'Th', name: 'Thorium', arabicName: 'ثوريوم', group: 4, period: 9, category: _Category.actinide),
  _Element(z: 91, symbol: 'Pa', name: 'Protactinium', arabicName: 'بروتكتينيوم', group: 5, period: 9, category: _Category.actinide),
  _Element(z: 92, symbol: 'U', name: 'Uranium', arabicName: 'يورانيوم', group: 6, period: 9, category: _Category.actinide),
  _Element(z: 93, symbol: 'Np', name: 'Neptunium', arabicName: 'نبتونيوم', group: 7, period: 9, category: _Category.actinide),
  _Element(z: 94, symbol: 'Pu', name: 'Plutonium', arabicName: 'بلوتونيوم', group: 8, period: 9, category: _Category.actinide),
  _Element(z: 95, symbol: 'Am', name: 'Americium', arabicName: 'أمريسيوم', group: 9, period: 9, category: _Category.actinide),
  _Element(z: 96, symbol: 'Cm', name: 'Curium', arabicName: 'كوريوم', group: 10, period: 9, category: _Category.actinide),
  _Element(z: 97, symbol: 'Bk', name: 'Berkelium', arabicName: 'بركيليوم', group: 11, period: 9, category: _Category.actinide),
  _Element(z: 98, symbol: 'Cf', name: 'Californium', arabicName: 'كاليفورنيوم', group: 12, period: 9, category: _Category.actinide),
  _Element(z: 99, symbol: 'Es', name: 'Einsteinium', arabicName: 'أينشتاينيوم', group: 13, period: 9, category: _Category.actinide),
  _Element(z: 100, symbol: 'Fm', name: 'Fermium', arabicName: 'فيرميوم', group: 14, period: 9, category: _Category.actinide),
  _Element(z: 101, symbol: 'Md', name: 'Mendelevium', arabicName: 'مندليفيوم', group: 15, period: 9, category: _Category.actinide),
  _Element(z: 102, symbol: 'No', name: 'Nobelium', arabicName: 'نوبليوم', group: 16, period: 9, category: _Category.actinide),
  _Element(z: 103, symbol: 'Lr', name: 'Lawrencium', arabicName: 'لورنسيوم', group: 17, period: 9, category: _Category.actinide),
  // Period 7 main.
  _Element(z: 104, symbol: 'Rf', name: 'Rutherfordium', arabicName: 'رذرفورديوم', group: 4, period: 7, category: _Category.transition),
  _Element(z: 105, symbol: 'Db', name: 'Dubnium', arabicName: 'دبنيوم', group: 5, period: 7, category: _Category.transition),
  _Element(z: 106, symbol: 'Sg', name: 'Seaborgium', arabicName: 'سيبورجيوم', group: 6, period: 7, category: _Category.transition),
  _Element(z: 107, symbol: 'Bh', name: 'Bohrium', arabicName: 'بوريوم', group: 7, period: 7, category: _Category.transition),
  _Element(z: 108, symbol: 'Hs', name: 'Hassium', arabicName: 'هاسيوم', group: 8, period: 7, category: _Category.transition),
  _Element(z: 109, symbol: 'Mt', name: 'Meitnerium', arabicName: 'مايتنريوم', group: 9, period: 7, category: _Category.unknown),
  _Element(z: 110, symbol: 'Ds', name: 'Darmstadtium', arabicName: 'دارمشتاتيوم', group: 10, period: 7, category: _Category.unknown),
  _Element(z: 111, symbol: 'Rg', name: 'Roentgenium', arabicName: 'رونتجينيوم', group: 11, period: 7, category: _Category.unknown),
  _Element(z: 112, symbol: 'Cn', name: 'Copernicium', arabicName: 'كوبرنيكيوم', group: 12, period: 7, category: _Category.transition),
  _Element(z: 113, symbol: 'Nh', name: 'Nihonium', arabicName: 'نيهونيوم', group: 13, period: 7, category: _Category.unknown),
  _Element(z: 114, symbol: 'Fl', name: 'Flerovium', arabicName: 'فليروفيوم', group: 14, period: 7, category: _Category.unknown),
  _Element(z: 115, symbol: 'Mc', name: 'Moscovium', arabicName: 'موسكوفيوم', group: 15, period: 7, category: _Category.unknown),
  _Element(z: 116, symbol: 'Lv', name: 'Livermorium', arabicName: 'ليفرموريوم', group: 16, period: 7, category: _Category.unknown),
  _Element(z: 117, symbol: 'Ts', name: 'Tennessine', arabicName: 'تينيسين', group: 17, period: 7, category: _Category.unknown),
  _Element(z: 118, symbol: 'Og', name: 'Oganesson', arabicName: 'أوغانيسون', group: 18, period: 7, category: _Category.nobleGas),
];

class PeriodicTableScreen extends StatefulWidget {
  const PeriodicTableScreen({super.key});

  @override
  State<PeriodicTableScreen> createState() => _PeriodicTableScreenState();
}

class _PeriodicTableScreenState extends State<PeriodicTableScreen> {
  _Category? _filter;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              BackBar(
                title: 'الجدول الدوري',
                subtitle: '118 عنصرًا · اضغط على أي عنصر لمزيد من التفاصيل',
                onBack: () => context.go('/library'),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: <Widget>[
                    _FilterChip(
                      label: 'الكل',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                      tone: scheme.primary,
                    ),
                    for (final _Category cat in _Category.values)
                      _FilterChip(
                        label: _categoryStyle[cat]!.label,
                        selected: _filter == cat,
                        onTap: () => setState(() => _filter = cat),
                        tone: _categoryStyle[cat]!.color,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: FadeSlideIn(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          color: palette.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: palette.outline, width: 1),
                          boxShadow: palette.cardShadow,
                        ),
                        child: InteractiveViewer(
                          minScale: 0.7,
                          maxScale: 3.5,
                          boundaryMargin: const EdgeInsets.all(60),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: _Grid(filter: _filter),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.tone,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final AppPalette palette = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? tone.withOpacity(0.18) : palette.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? tone : palette.outline,
              width: selected ? 1.4 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tone,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? tone : palette.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({this.filter});

  final _Category? filter;

  @override
  Widget build(BuildContext context) {
    const int cols = 18;
    const int rows = 9; // 7 + lanthanides + actinides
    const double cell = 38;
    const double gap = 3;
    final double width = cols * cell + (cols - 1) * gap;
    final double height = rows * cell + (rows - 1) * gap;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: <Widget>[
          for (final _Element e in _elements)
            Positioned(
              left: (e.group - 1) * (cell + gap),
              top: (e.period - 1) * (cell + gap),
              width: cell,
              height: cell,
              child: _ElementCell(
                element: e,
                dimmed: filter != null && e.category != filter,
                onTap: () => _show(context, e),
              ),
            ),
        ],
      ),
    );
  }

  void _show(BuildContext context, _Element e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext _) => _ElementSheet(element: e),
    );
  }
}

class _ElementCell extends StatelessWidget {
  const _ElementCell({
    required this.element,
    required this.dimmed,
    required this.onTap,
  });

  final _Element element;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tone = _categoryStyle[element.category]!.color;
    return Opacity(
      opacity: dimmed ? 0.18 : 1.0,
      child: PressableScale(
        onTap: onTap,
        pressedScale: 0.92,
        child: Container(
          decoration: BoxDecoration(
            color: tone.withOpacity(0.16),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tone.withOpacity(0.55), width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${element.z}',
                style: TextStyle(
                  fontSize: 8,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: tone,
                ),
              ),
              Center(
                child: Text(
                  element.symbol,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: tone,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElementSheet extends StatelessWidget {
  const _ElementSheet({required this.element});

  final _Element element;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    final ({Color color, String label}) style =
        _categoryStyle[element.category]!;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: palette.outline,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: style.color, width: 1.4),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${element.z}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: style.color,
                    ),
                  ),
                  Text(
                    element.symbol,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: style.color,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              element.arabicName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              element.name,
              style: TextStyle(
                fontSize: 13,
                color: palette.muted,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: style.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: style.color, width: 1),
              ),
              child: Text(
                style.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: style.color,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Stat(
                    label: 'العمود',
                    value: '${element.group}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'الدورة',
                    value: element.period <= 7
                        ? '${element.period}'
                        : (element.period == 8 ? 'لانثانيد' : 'أكتينيد'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    label: 'العدد الذري',
                    value: 'Z=${element.z}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppPalette palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: palette.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
