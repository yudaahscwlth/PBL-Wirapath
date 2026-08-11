import 'dart:convert';

class ChatMessage {
  final String id;
  final String sender; // 'user' or 'ai'
  final String text;
  final String? audioUrl;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.audioUrl,
    required this.timestamp,
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? sender,
    String? text,
    String? audioUrl,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      audioUrl: audioUrl ?? this.audioUrl,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
      'audioUrl': audioUrl,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      sender: map['sender'] ?? 'user',
      text: map['text'] ?? '',
      audioUrl: map['audioUrl'],
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source), '');
}
