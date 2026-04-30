/// Lightweight read-only catalog of subject + topic IDs and Arabic
/// titles so the teachers app can show meaningful labels in rosters and
/// per-student progress without depending on the student app's full
/// curriculum module.
///
/// Keep this in sync with `lib/core/constants/curriculum.dart` in the
/// student app whenever IDs change.
class TopicCatalog {
  TopicCatalog._();

  static const String physicsId = 'physics';
  static const String chemistryId = 'chemistry';

  static const Map<String, String> subjectTitles = <String, String>{
    physicsId: 'الفيزياء',
    chemistryId: 'الكيمياء',
  };

  static const Map<String, String> topicTitles = <String, String>{
    'phy-current': 'التيار الكهربائي',
    'phy-motion': 'قوانين الحركة',
    'phy-energy': 'الطاقة والعمل',
    'chem-rate': 'سرعة التفاعل الكيميائي',
    'chem-equilibrium': 'التوازن الكيميائي',
    'chem-organic': 'الكيمياء العضوية الأساسية',
  };

  static String subjectTitle(String id) => subjectTitles[id] ?? id;
  static String topicTitle(String id) => topicTitles[id] ?? id;
}
