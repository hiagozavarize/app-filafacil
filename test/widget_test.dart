import 'package:filafacil_ubs/features/auth/data/repositories/auth_repository.dart';
import 'package:filafacil_ubs/features/auth/domain/entities/health_agent.dart';
import 'package:filafacil_ubs/features/history/data/repositories/history_repository.dart';
import 'package:filafacil_ubs/features/history/presentation/providers/history_provider.dart';
import 'package:filafacil_ubs/features/queue/data/repositories/queue_repository.dart';
import 'package:filafacil_ubs/features/queue/domain/entities/queue_ticket.dart';
import 'package:filafacil_ubs/features/queue/presentation/providers/queue_provider.dart';
import 'package:filafacil_ubs/features/stats/data/repositories/stats_repository.dart';
import 'package:filafacil_ubs/features/stats/domain/entities/dashboard_stats.dart';
import 'package:filafacil_ubs/features/stats/presentation/providers/stats_provider.dart';
import 'package:filafacil_ubs/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'FilaFacilApp renderiza Tela Inicial (Splash) única e navega ao Login',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
            queueRepositoryProvider.overrideWithValue(MockQueueRepository()),
          ],
          child: const FilaFacilApp(),
        ),
      );

      expect(find.byKey(const Key('splash_logo_image')), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Fazer Login'), findsOneWidget);
      expect(find.text('CPF ou E-mail:'), findsOneWidget);
      expect(find.text('Senha:'), findsOneWidget);
    },
  );

  test(
    'QueueNotifier carrega fila, emite senha prioritária e conclui atendimento',
    () async {
      final container = ProviderContainer(
        overrides: [
          queueRepositoryProvider.overrideWithValue(MockQueueRepository()),
        ],
      );
      addTearDown(container.dispose);

      await container.read(queueProvider.notifier).loadQueue();
      expect(container.read(queueProvider).activeFilteredTickets.length, 4);

      final created = await container
          .read(queueProvider.notifier)
          .addPatientToQueue(
            patientName: 'Benedita Souza Costa',
            cpf: '389.220.198-10',
            susCard: '892441029810001',
            birthDate: '12/03/1940',
            specialty: 'Pediatria',
            ubsName: 'UBS Centro',
            scheduledDate: '20 Nov 2026',
            scheduledTime: '09:00',
            priority: TicketPriority.preferencial80,
          );

      expect(created, isNotNull);
      expect(created!.patientName, 'Benedita Souza Costa');
      expect(created.priority, TicketPriority.preferencial80);
      expect(created.room, 'Consultorio 04');
      expect(container.read(queueProvider).activeFilteredTickets.length, 5);

      final called = await container
          .read(queueProvider.notifier)
          .callTicket(
            ticketId: created.id,
            roomName: 'Consultorio 04',
            doctorName: 'Dra. Helena',
          );
      expect(called?.status, QueueStatus.called);

      final started = await container
          .read(queueProvider.notifier)
          .startAttendance(created.id);
      expect(started, isTrue);

      final finished = await container
          .read(queueProvider.notifier)
          .finishAttendance(
            ticketId: created.id,
            cid10: 'I10',
            notes: 'Paciente medicada e orientada.',
          );
      expect(finished, isTrue);
      expect(container.read(queueProvider).activeFilteredTickets.length, 4);
    },
  );

  test(
    'Schemas da API backend-filafacil são deserializados corretamente',
    () {
      final agent = HealthAgent.fromJson(const <String, dynamic>{
        'id': 'c1a2b3c4',
        'name': 'Dra. Juliana Mendes',
        'email': 'juliana.mendes@ubs.saude.gov.br',
        'cpf': '512.774.920-33',
        'phone': '(98) 98877-6655',
        'role': 'MEDICO',
        'cns': '712982311020049',
        'unitName': 'UBS Vila Esperança',
        'registration': 'CRM-MA 12345',
      });

      expect(agent.assignedUbs, 'UBS Vila Esperança');
      expect(agent.roleDisplayLabel, 'Médico(a)');
      expect(agent.toProfileUpdateJson()['unitName'], 'UBS Vila Esperança');

      final ticket = QueueTicket.fromJson(const <String, dynamic>{
        'id': 't1a2b3c4',
        'code': 'PRE-001',
        'patientName': 'Benedita Souza Costa',
        'cpf': '389.220.198-10',
        'cartaoSus': '892441029810001',
        'priority': 'PREFERENCIAL_80',
        'status': 'IN_PROGRESS',
        'specialty': 'Clinica Geral',
        'roomName': 'Consultorio 01',
        'doctorName': 'Dra. Juliana Mendes',
        'waitTimeMinutes': 14,
        'serviceDurationMinutes': 18,
        'cid10': 'I10',
        'notes': 'Consulta de rotina realizada.',
        'createdAt': '2026-11-20T12:30:00.000Z',
      });

      expect(ticket.ticketCode, 'PRE-001');
      expect(ticket.priority, TicketPriority.preferencial80);
      expect(ticket.status, QueueStatus.inAttendance);
      expect(ticket.room, 'Consultorio 01');
      expect(ticket.toCreateTicketPayload()['priority'], 'PREFERENCIAL_80');
      expect(ticket.toCreateTicketPayload()['cartaoSus'], '892441029810001');

      final stats = DashboardStats.fromApi(
        dashboardJson: const <String, dynamic>{
          'waitingCount': 5,
          'inProgressCount': 2,
          'finishedTodayCount': 18,
          'absentCount': 1,
          'averageWaitTimeMinutes': 14.5,
          'withinSusGoalPercentage': 92.5,
          'byPriority': <String, dynamic>{
            'NORMAL': 2,
            'PREFERENCIAL_80': 1,
          },
        },
      );

      expect(stats.activeNowCount, 7);
      expect(stats.finishedCount, 18);
      expect(stats.withinSusGoalPercentage, 92.5);
      expect(stats.byPriority['PREFERENCIAL_80'], 1);
    },
  );

  test('StatsNotifier e HistoryNotifier carregam dados da API', () async {
    final container = ProviderContainer(
      overrides: [
        statsRepositoryProvider.overrideWithValue(MockStatsRepository()),
        historyRepositoryProvider.overrideWithValue(MockHistoryRepository()),
      ],
    );
    addTearDown(container.dispose);

    await container.read(statsProvider.notifier).loadStats();
    expect(container.read(statsProvider).stats.finishedCount, 18);

    await container.read(historyProvider.notifier).loadHistory();
    expect(container.read(historyProvider).filteredRecords.length, 3);
  });
}
