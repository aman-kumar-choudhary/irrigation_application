import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> messages = [];
  bool isThinking = false;
  String? error;
  int _msgId = 0;

  static const List<_LiveMetric> _liveMetrics = [
    _LiveMetric('savi', 'Crop health', ''),
    _LiveMetric('kc', 'Growth', ''),
    _LiveMetric('etc', 'Water use', 'mm/d'),
    _LiveMetric('cwr', 'Crop water', 'mm/d'),
    _LiveMetric('iwr', 'Irrigation water', 'mm/d'),
  ];

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || isThinking) return;

    setState(() {
      messages.add(ChatMessage(
        id: '${_msgId++}',
        role: 'user',
        content: text.trim(),
        time: DateTime.now(),
      ));
      isThinking = true;
      error = null;
    });

    _scrollToBottom();
    _controller.clear();

    try {
      final history = messages
          .takeLast(6)
          .map((m) => {
                'role': m.role,
                'content': m.content,
              })
          .toList();

      final res = await ApiService().sendChat(text.trim(), history);

      setState(() {
        messages.add(ChatMessage(
          id: '${_msgId++}',
          role: 'bot',
          content: res['answer'] ?? 'No response',
          time: DateTime.now(),
          sources: List<String>.from(res['sources'] ?? []),
          liveData: res['live_data'],
        ));
        isThinking = false;
      });
    } catch (e) {
      setState(() {
        error = 'I am having trouble checking the data right now.';
        isThinking = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDark;

    return Scaffold(
      body: Container(
        color: isDark ? const Color(0xFF06101C) : const Color(0xFFF8FAFC),
        child: SafeArea(
          child: Column(
            children: [
              _chatHeader(provider, isDark),
              _metaStrip(isDark),
              if (messages.isEmpty) _promptDock(isDark),
              Expanded(
                child: messages.isEmpty
                    ? _welcome(isDark)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return _messageBubble(msg, isDark);
                        },
                      ),
              ),
              if (isThinking) _typingBubble(isDark),
              if (error != null) _errorBar(isDark),
              _inputRow(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chatHeader(AppProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1D30) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'A',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JalDrishtiBot',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isThinking
                            ? const Color(0xFFF59E0B)
                            : AppTheme.brandTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isThinking
                          ? 'Checking your field'
                          : 'Ready to help with irrigation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.darkTextMuted
                            : AppTheme.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: provider.toggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaStrip(bool isDark) {
    final chips = [
      isThinking ? 'Preparing answer' : 'Assistant ready',
      'Field guide ready',
      'Live raster aware',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color:
            isDark ? const Color(0xCC0C192A) : Colors.white.withOpacity(0.82),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final chip in chips) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.04)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  Widget _promptDock(bool isDark) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x990C192A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: Constants.suggestedQuestions.map((q) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(q, style: const TextStyle(fontSize: 12)),
              onPressed: () => _sendMessage(q),
              backgroundColor:
                  isDark ? AppTheme.darkSurface2 : const Color(0xFFF8FAFC),
              side: BorderSide(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _welcome(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface2 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'JalDrishti Assistant',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ask for irrigation advice, crop health, field values, or forecast help.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                height: 1.35,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messageBubble(ChatMessage msg, bool isDark) {
    final isUser = msg.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.86,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
                      )
                    : null,
                color: isUser
                    ? null
                    : isDark
                        ? const Color(0xFF0F1D30)
                        : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 14),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color:
                            isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser
                          ? Colors.white
                          : isDark
                              ? AppTheme.darkTextSoft
                              : AppTheme.lightTextSoft,
                    ),
                  ),
                  if (_hasLiveData(msg.liveData)) ...[
                    const SizedBox(height: 12),
                    _liveDataGrid(msg.liveData!, isDark),
                  ],
                  if (msg.sources != null && msg.sources!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.sources!.map((source) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandAccent.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _sourceLabel(source),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFF60A5FA)
                                  : AppTheme.brandAccent,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('hh:mm a').format(msg.time),
              style: TextStyle(
                fontSize: 10,
                color:
                    isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveDataGrid(Map<String, dynamic> data, bool isDark) {
    final metrics = _liveMetrics
        .map((metric) => (metric, _metricValue(data, metric.key)))
        .where((entry) => entry.$2 != null)
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics.map((entry) {
        final metric = entry.$1;
        final value = entry.$2;
        return Container(
          width: 118,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withOpacity(0.04)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatMetric(value, metric.unit),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppTheme.brandTeal : AppTheme.brandPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _typingBubble(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F1D30) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [_dot(0), _dot(1), _dot(2)],
          ),
        ),
      ),
    );
  }

  Widget _errorBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.20)),
        ),
        child: Text(
          error!,
          style: TextStyle(color: Colors.red.shade300, fontSize: 12),
        ),
      ),
    );
  }

  Widget _inputRow(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1D30) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              maxLength: 600,
              decoration: InputDecoration(
                counterText: '',
                hintText:
                    'Ask about irrigation, crop health, water need, or a clicked field...',
                hintStyle: TextStyle(
                  color:
                      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0C192A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.brandTeal),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: TextStyle(
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: isThinking ? null : () => _sendMessage(_controller.text),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              disabledBackgroundColor: AppTheme.brandPrimary.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(48, 48),
            ),
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  bool _hasLiveData(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return false;
    return _liveMetrics.any((metric) => _metricValue(data, metric.key) != null);
  }

  dynamic _metricValue(Map<String, dynamic> data, String key) {
    final pointKey = 'point_$key';
    final value = data[pointKey] ?? data[key];
    if (value == null || value == '') return null;
    return value;
  }

  String _formatMetric(dynamic value, String unit) {
    final number = value is num ? value : num.tryParse(value.toString());
    final formatted = number == null
        ? value.toString()
        : number.abs() < 2
            ? number.toStringAsFixed(3)
            : number.toStringAsFixed(2);
    return unit.isEmpty ? formatted : '$formatted $unit';
  }

  String _sourceLabel(String source) {
    const labels = {
      'live_raster': 'Field data',
      'structured_data': 'Field check',
      'alert_engine': 'Water advice',
      'forecast_model': 'Forecast',
      'history_rasters': 'History',
    };
    return labels[source] ?? source.replaceAll(RegExp(r'[_-]+'), ' ');
  }

  Widget _dot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: AppTheme.brandTeal.withOpacity(0.45 + (index * 0.18)),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _LiveMetric {
  final String key;
  final String label;
  final String unit;

  const _LiveMetric(this.key, this.label, this.unit);
}

extension on List<ChatMessage> {
  List<ChatMessage> takeLast(int n) {
    if (length <= n) return this;
    return sublist(length - n);
  }
}
