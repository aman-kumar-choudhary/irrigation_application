class ChatMessage {
  final String id;
  final String role; // 'user' or 'bot'
  final String content;
  final DateTime time;
  final List<String>? sources;
  final Map<String, dynamic>? liveData;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.time,
    this.sources,
    this.liveData,
  });
}