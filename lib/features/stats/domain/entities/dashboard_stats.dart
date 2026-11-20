import 'package:equatable/equatable.dart';

class SpecialtyMetric extends Equatable {
  const SpecialtyMetric({
    required this.name,
    required this.count,
    required this.fraction,
  });

  final String name;
  final int count;
  final double fraction;

  @override
  List<Object?> get props => [name, count, fraction];
}

class HourlyFlowPoint extends Equatable {
  const HourlyFlowPoint({required this.hour, required this.count});

  final String hour;
  final int count;

  @override
  List<Object?> get props => [hour, count];
}

/// Métricas consolidadas de `/api/stats/dashboard` e `/api/stats/reports`.
class DashboardStats extends Equatable {
  const DashboardStats({
    this.waitingCount = 0,
    this.inProgressCount = 0,
    this.finishedCount = 0,
    this.absentCount = 0,
    this.averageWaitTimeMinutes = 0,
    this.withinSusGoalPercentage = 0,
    this.byPriority = const <String, int>{},
    this.bySpecialty = const <SpecialtyMetric>[],
    this.hourlyFlow = const <HourlyFlowPoint>[],
  });

  final int waitingCount;
  final int inProgressCount;
  final int finishedCount;
  final int absentCount;
  final double averageWaitTimeMinutes;
  final double withinSusGoalPercentage;
  final Map<String, int> byPriority;
  final List<SpecialtyMetric> bySpecialty;
  final List<HourlyFlowPoint> hourlyFlow;

  int get activeNowCount => waitingCount + inProgressCount;

  double get absenceRatePercentage {
    final total = finishedCount + absentCount;
    if (total <= 0) return 0;
    return (absentCount / total) * 100;
  }

  factory DashboardStats.fromApi({
    required Map<String, dynamic> dashboardJson,
    Map<String, dynamic>? reportJson,
  }) {
    final r = reportJson ?? const <String, dynamic>{};

    final waiting = (dashboardJson['waitingCount'] as num?)?.toInt() ?? 0;
    final inProgress = (dashboardJson['inProgressCount'] as num?)?.toInt() ?? 0;
    final finished =
        (r['totalServed'] as num?)?.toInt() ??
        (r['finishedCount'] as num?)?.toInt() ??
        (r['totalFinished'] as num?)?.toInt() ??
        (dashboardJson['finishedTodayCount'] as num?)?.toInt() ??
        0;
    final absent =
        (r['absentCount'] as num?)?.toInt() ??
        (dashboardJson['absentCount'] as num?)?.toInt() ??
        0;
    final avgWait =
        (r['averageWaitTimeMinutes'] as num?)?.toDouble() ??
        (dashboardJson['averageWaitTimeMinutes'] as num?)?.toDouble() ??
        0;
    final susGoal =
        (r['withinSusGoalPercentage'] as num?)?.toDouble() ??
        (dashboardJson['withinSusGoalPercentage'] as num?)?.toDouble() ??
        0;

    final rawByPriority =
        r['byPriority'] ?? dashboardJson['byPriority'] ?? const <String, dynamic>{};
    final byPriority = <String, int>{};
    if (rawByPriority is Map) {
      for (final entry in rawByPriority.entries) {
        final v = entry.value;
        if (v is num) {
          byPriority[entry.key.toString()] = v.toInt();
        }
      }
    }

    final bySpecialty = _parseSpecialties(
      r['bySpecialty'] ?? dashboardJson['bySpecialty'],
    );
    final hourlyFlow = _parseHourly(
      r['hourlyFlow'] ?? r['byHour'] ?? dashboardJson['hourlyFlow'],
    );

    return DashboardStats(
      waitingCount: waiting,
      inProgressCount: inProgress,
      finishedCount: finished,
      absentCount: absent,
      averageWaitTimeMinutes: avgWait,
      withinSusGoalPercentage: susGoal,
      byPriority: byPriority,
      bySpecialty: bySpecialty,
      hourlyFlow: hourlyFlow,
    );
  }

  static List<SpecialtyMetric> _parseSpecialties(dynamic raw) {
    final counts = <String, int>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is num) {
          counts[entry.key.toString()] = (entry.value as num).toInt();
        }
      }
    } else if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final name =
            (item['specialty'] ?? item['name'] ?? '').toString().trim();
        final count = (item['count'] ?? item['total'] ?? 0) as num;
        if (name.isNotEmpty) {
          counts[name] = count.toInt();
        }
      }
    }
    if (counts.isEmpty) return const <SpecialtyMetric>[];
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map(
          (e) => SpecialtyMetric(
            name: e.key,
            count: e.value,
            fraction: total > 0 ? e.value / total : 0,
          ),
        )
        .toList();
  }

  static List<HourlyFlowPoint> _parseHourly(dynamic raw) {
    final points = <HourlyFlowPoint>[];
    if (raw is Map) {
      for (final entry in raw.entries) {
        if (entry.value is num) {
          points.add(
            HourlyFlowPoint(
              hour: entry.key.toString(),
              count: (entry.value as num).toInt(),
            ),
          );
        }
      }
    } else if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final hour = (item['hour'] ?? item['label'] ?? '').toString();
        final count = (item['count'] ?? item['total'] ?? 0) as num;
        if (hour.isNotEmpty) {
          points.add(HourlyFlowPoint(hour: hour, count: count.toInt()));
        }
      }
    }
    return points;
  }

  static const DashboardStats mockDefault = DashboardStats(
    waitingCount: 5,
    inProgressCount: 2,
    finishedCount: 18,
    absentCount: 1,
    averageWaitTimeMinutes: 14.5,
    withinSusGoalPercentage: 92.5,
    byPriority: <String, int>{
      'NORMAL': 8,
      'PREFERENCIAL_60': 5,
      'PREFERENCIAL_80': 3,
      'GESTANTE': 2,
      'URGENCIA_MANCHESTER': 1,
    },
    bySpecialty: <SpecialtyMetric>[
      SpecialtyMetric(name: 'Clínica Geral', count: 8, fraction: 0.44),
      SpecialtyMetric(name: 'Pediatria', count: 5, fraction: 0.28),
      SpecialtyMetric(name: 'Odontologia', count: 3, fraction: 0.17),
      SpecialtyMetric(name: 'Ginecologia', count: 2, fraction: 0.11),
    ],
    hourlyFlow: <HourlyFlowPoint>[
      HourlyFlowPoint(hour: '07h', count: 3),
      HourlyFlowPoint(hour: '08h', count: 6),
      HourlyFlowPoint(hour: '09h', count: 5),
      HourlyFlowPoint(hour: '10h', count: 4),
      HourlyFlowPoint(hour: '11h', count: 2),
      HourlyFlowPoint(hour: '14h', count: 4),
      HourlyFlowPoint(hour: '15h', count: 2),
    ],
  );

  @override
  List<Object?> get props => [
    waitingCount,
    inProgressCount,
    finishedCount,
    absentCount,
    averageWaitTimeMinutes,
    withinSusGoalPercentage,
    byPriority,
    bySpecialty,
    hourlyFlow,
  ];
}

