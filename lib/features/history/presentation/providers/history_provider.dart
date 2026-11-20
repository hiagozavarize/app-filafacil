import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../queue/domain/entities/queue_ticket.dart';
import '../../data/repositories/history_repository.dart';

class HistoryState {
  const HistoryState({
    this.records = const <QueueTicket>[],
    this.selectedFilter = 'Todos',
    this.searchQuery = '',
    this.isLoading = false,
    this.isExporting = false,
    this.errorMessage,
  });

  final List<QueueTicket> records;
  final String selectedFilter;
  final String searchQuery;
  final bool isLoading;
  final bool isExporting;
  final String? errorMessage;

  List<QueueTicket> get filteredRecords {
    final q = searchQuery.trim().toLowerCase();
    return records.where((t) {
      final matchFilter = switch (selectedFilter) {
        'Concluídos' => t.status == QueueStatus.completed,
        'Ausentes' =>
          t.status == QueueStatus.absent || t.status == QueueStatus.cancelled,
        _ => true,
      };
      final matchQuery =
          q.isEmpty ||
          t.patientName.toLowerCase().contains(q) ||
          t.cpf.toLowerCase().contains(q) ||
          t.protocol.toLowerCase().contains(q) ||
          t.ticketCode.toLowerCase().contains(q);
      return matchFilter && matchQuery;
    }).toList();
  }

  HistoryState copyWith({
    List<QueueTicket>? records,
    String? selectedFilter,
    String? searchQuery,
    bool? isLoading,
    bool? isExporting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HistoryState(
      records: records ?? this.records,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() => const HistoryState();

  IHistoryRepository get _repository => ref.read(historyRepositoryProvider);

  Future<void> loadHistory({String? filter, String? search}) async {
    final nextFilter = filter ?? state.selectedFilter;
    final nextSearch = search ?? state.searchQuery;
    final apiStatus = switch (nextFilter) {
      'Concluídos' => 'FINISHED',
      'Ausentes' => 'ABSENT',
      _ => null,
    };

    state = state.copyWith(
      selectedFilter: nextFilter,
      searchQuery: nextSearch,
      isLoading: true,
      clearError: true,
    );

    try {
      final items = await _repository.getHistory(
        status: apiStatus,
        search: nextSearch.trim().isEmpty ? null : nextSearch.trim(),
      );
      state = state.copyWith(
        records: items,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isLoading: false, errorMessage: msg);
    }
  }

  void setFilter(String filter) {
    loadHistory(filter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<QueueTicket?> fetchAuditDetail(String id) async {
    try {
      return await _repository.getHistoryAuditById(id);
    } catch (_) {
      return null;
    }
  }

  Future<String?> exportCsv() async {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final csv = await _repository.exportHistoryCsv();
      state = state.copyWith(isExporting: false);
      return csv;
    } catch (e) {
      final msg = e is AppException ? e.message : e.toString();
      state = state.copyWith(isExporting: false, errorMessage: msg);
      return null;
    }
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);

