import 'package:filafacil_ubs/features/queue/domain/entities/queue_ticket.dart';
import 'package:filafacil_ubs/features/queue/presentation/providers/queue_provider.dart';
import 'package:filafacil_ubs/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FilaFacilApp renderiza Tela Inicial (Splash) e navega ao Login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FilaFacilApp()));

    expect(find.text('FilaFácil'), findsOneWidget);
    expect(find.text('UBS'), findsOneWidget);
    expect(find.text('Gestão Inteligente de Filas nas UBS'), findsOneWidget);

    // Avança o timer da Splash Screen para ir ao Login
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Fazer Login'), findsOneWidget);
    expect(find.text('CPF:'), findsOneWidget);
    expect(find.text('Senha:'), findsOneWidget);
  });

  test('QueueNotifier gerencia adição de paciente e mudança de status', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final initialState = container.read(queueProvider);
    expect(initialState.activeFilteredTickets.length, 4);

    final created = await container
        .read(queueProvider.notifier)
        .addPatientToQueue(
          patientName: 'Paciente Teste SUS',
          cpf: '111.222.333-44',
          birthDate: '01/01/1990',
          specialty: 'Pediatra',
          ubsName: 'UBS Centro',
          scheduledDate: '19 Nov 2026',
          scheduledTime: '09:00',
        );

    expect(created.patientName, 'Paciente Teste SUS');
    expect(created.room, 'Sala 04');
    expect(
      container.read(queueProvider).activeFilteredTickets.length,
      5,
    );

    await container
        .read(queueProvider.notifier)
        .updateStatus(created.id, QueueStatus.completed);

    expect(
      container.read(queueProvider).activeFilteredTickets.length,
      4,
    );
    expect(
      container
          .read(queueProvider)
          .historyFilteredTickets
          .any((t) => t.id == created.id),
      isTrue,
    );
  });
}

