// lib/models/routine_model.dart

class MealStatus {
  final String name;
  final String status; // 'bem', 'pouco', 'recusou'

  MealStatus({required this.name, required this.status});

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status,
      };
}

class MedicationEntry {
  final String time;
  final String dosage;
  final String administeredBy;

  MedicationEntry({
    required this.time,
    required this.dosage,
    required this.administeredBy,
  });

  Map<String, dynamic> toJson() => {
        'time': time,
        'dosage': dosage,
        'administered_by': administeredBy,
      };
}

class RoutineModel {
  final List<MealStatus> meals;
  final int evacuations;
  final String evacuationType;
  final String sleepStart; // formatted as HH:mm
  final String sleepEnd;   // formatted as HH:mm
  final List<MedicationEntry> medications;
  final String? observation;

  RoutineModel({
    required this.meals,
    required this.evacuations,
    required this.evacuationType,
    required this.sleepStart,
    required this.sleepEnd,
    required this.medications,
    this.observation,
  });

  Map<String, dynamic> toJson() => {
        'meals': meals.map((m) => m.toJson()).toList(),
        'evacuations': evacuations,
        'evacuation_type': evacuationType,
        'sleep_start': sleepStart,
        'sleep_end': sleepEnd,
        'medications': medications.map((m) => m.toJson()).toList(),
        'observation': observation,
      };
}
