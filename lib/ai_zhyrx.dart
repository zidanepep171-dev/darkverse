import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

// ╔══════════════════════════════════════════════════════════════════════════╗
//  ai_zhyrx.dart
//  ZhyrxAI — Full Multimodal AI Client
//  Model   : claude-sonnet-4-6
//  Fitur   : Chat · Stream · Conversation · Image Upload · PDF Upload
//            File Upload · OCR · Vision QA · Compare Images
//            CSV Analysis · Code Review · Fix Code · Explain Code
//            Summarize · Translate · Classify · Extract · Sentiment
//            Proofread · Generate · Custom Prompt
// ╚══════════════════════════════════════════════════════════════════════════╝

const String _kModel            = 'claude-sonnet-4-6';
const String _kBaseUrl          = 'https://api.anthropic.com/v1/messages';
const String _kAnthropicVersion = '2023-06-01';
const int    _kDefaultMaxTokens = 1024;

// ════════════════════════════════════════════════════════════════════════════
//  MIME HELPER
// ════════════════════════════════════════════════════════════════════════════

class _Mime {
  static const Map<String, String> _imageTypes = {
    'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
    'png': 'image/png',  'gif': 'image/gif',
    'webp': 'image/webp',
  };

  static const Set<String> _textTypes = {
    'txt', 'md', 'markdown', 'csv', 'tsv', 'log', 'yaml', 'yml',
    'json', 'xml', 'html', 'htm', 'css', 'dart', 'py', 'js', 'ts',
    'java', 'kt', 'swift', 'go', 'rs', 'c', 'cpp', 'h', 'sh', 'sql',
    'toml', 'ini', 'cfg', 'env',
  };

  static String ext(String path)     => path.split('.').last.toLowerCase().trim();
  static bool isImage(String e)      => _imageTypes.containsKey(e);
  static bool isPdf(String e)        => e == 'pdf';
  static bool isText(String e)       => _textTypes.contains(e);
  static String? imageMime(String e) => _imageTypes[e];
  static String fileName(String p)   => p.split(Platform.pathSeparator).last;
}

// ════════════════════════════════════════════════════════════════════════════
//  CONTENT BLOCKS
// ════════════════════════════════════════════════════════════════════════════

abstract class ContentBlock { Map<String, dynamic> toJson(); }

class TextBlock extends ContentBlock {
  final String text;
  TextBlock(this.text);
  @override Map<String, dynamic> toJson() => {'type': 'text', 'text': text};
}

class ImageBlock extends ContentBlock {
  final String mediaType;
  final String _data;
  final bool   _isUrl;

  ImageBlock._({required this.mediaType, required String data, required bool isUrl})
      : _data = data, _isUrl = isUrl;

  factory ImageBlock.fromFile(String path) {
    final e  = _Mime.ext(path);
    final mt = _Mime.imageMime(e);
    if (mt == null) throw ArgumentError('Unsupported image format: .$e');
    return ImageBlock._(
      mediaType: mt,
      data: base64Encode(File(path).readAsBytesSync()),
      isUrl: false,
    );
  }

  factory ImageBlock.fromBytes(Uint8List bytes, {required String mediaType}) =>
      ImageBlock._(mediaType: mediaType, data: base64Encode(bytes), isUrl: false);

  factory ImageBlock.fromUrl(String url, {String mediaType = 'image/jpeg'}) =>
      ImageBlock._(mediaType: mediaType, data: url, isUrl: true);

  @override
  Map<String, dynamic> toJson() => _isUrl
      ? {'type': 'image', 'source': {'type': 'url', 'url': _data}}
      : {'type': 'image', 'source': {'type': 'base64', 'media_type': mediaType, 'data': _data}};
}

class PdfBlock extends ContentBlock {
  final String  _data;
  final String? title;
  PdfBlock._({required String data, this.title}) : _data = data;

  factory PdfBlock.fromFile(String path) =>
      PdfBlock._(data: base64Encode(File(path).readAsBytesSync()), title: _Mime.fileName(path));

  factory PdfBlock.fromBytes(Uint8List bytes, {String? title}) =>
      PdfBlock._(data: base64Encode(bytes), title: title);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'document',
        'source': {'type': 'base64', 'media_type': 'application/pdf', 'data': _data},
        if (title != null) 'title': title,
      };
}

class FileTextBlock extends ContentBlock {
  final String fileName;
  final String content;
  FileTextBlock({required this.fileName, required this.content});

  factory FileTextBlock.fromFile(String path) => FileTextBlock(
        fileName: _Mime.fileName(path),
        content:  File(path).readAsStringSync(),
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'text': '### File: `$fileName`\n\n```\n$content\n```',
      };
}

// ════════════════════════════════════════════════════════════════════════════
//  ATTACHMENT — auto-detect file type
// ════════════════════════════════════════════════════════════════════════════

class Attachment {
  static ContentBlock fromPath(String path) {
    final e = _Mime.ext(path);
    if (_Mime.isImage(e)) return ImageBlock.fromFile(path);
    if (_Mime.isPdf(e))   return PdfBlock.fromFile(path);
    if (_Mime.isText(e))  return FileTextBlock.fromFile(path);
    try { return FileTextBlock.fromFile(path); }
    catch (_) { throw UnsupportedError('Unsupported file type: .$e'); }
  }

  static ContentBlock fromBytes(Uint8List bytes, {required String fileName}) {
    final e = _Mime.ext(fileName);
    if (_Mime.isImage(e)) return ImageBlock.fromBytes(bytes, mediaType: _Mime.imageMime(e) ?? 'image/jpeg');
    if (_Mime.isPdf(e))   return PdfBlock.fromBytes(bytes, title: fileName);
    return FileTextBlock(fileName: fileName, content: utf8.decode(bytes, allowMalformed: true));
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  MESSAGE
// ════════════════════════════════════════════════════════════════════════════

class Message {
  final String             role;
  final List<ContentBlock> blocks;

  Message.text(this.role, String text) : blocks = [TextBlock(text)];
  Message.blocks(this.role, this.blocks);

  Map<String, dynamic> toJson() => {
        'role':    role,
        'content': blocks.map((b) => b.toJson()).toList(),
      };
}

// ════════════════════════════════════════════════════════════════════════════
//  AI RESPONSE
// ════════════════════════════════════════════════════════════════════════════

class AiResponse {
  final String id, model, text, stopReason;
  final int    inputTokens, outputTokens;

  const AiResponse({
    required this.id, required this.model,    required this.text,
    required this.inputTokens, required this.outputTokens, required this.stopReason,
  });

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    final content = (json['content'] as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n');
    final usage = json['usage'] as Map<String, dynamic>? ?? {};
    return AiResponse(
      id:           json['id']          as String? ?? '',
      model:        json['model']        as String? ?? _kModel,
      text:         content,
      inputTokens:  usage['input_tokens']  as int? ?? 0,
      outputTokens: usage['output_tokens'] as int? ?? 0,
      stopReason:   json['stop_reason']  as String? ?? '',
    );
  }

  Message toMessage() => Message.text('assistant', text);

  @override
  String toString() =>
      '\u250c\u2500 ZhyrxAI [$model]  in:$inputTokens / out:$outputTokens tokens\n'
      '\u2502\n'
      '${text.split('\n').map((l) => '\u2502  $l').join('\n')}\n'
      '\u2514${'\u2500' * 60}';
}

// ════════════════════════════════════════════════════════════════════════════
//  CONVERSATION — stateful multi-turn with file support
// ════════════════════════════════════════════════════════════════════════════

class Conversation {
  final ZhyrxAI       _ai;
  final String        systemPrompt;
  final int           maxTokens;
  final List<Message> _history = [];

  Conversation(this._ai, {
    this.systemPrompt = 'You are Zhyrx, a helpful AI. You can analyze images, PDFs, and files.',
    this.maxTokens    = _kDefaultMaxTokens,
  });

  List<Message> get history   => List.unmodifiable(_history);
  int           get turnCount => _history.length ~/ 2;

  Future<AiResponse> send(
    String text, {
    List<String>       filePaths   = const [],
    List<String>       imageUrls   = const [],
    List<ContentBlock> extraBlocks = const [],
  }) async {
    final blocks = <ContentBlock>[
      ...imageUrls.map((u) => ImageBlock.fromUrl(u)),
      ...filePaths.map(Attachment.fromPath),
      ...extraBlocks,
      TextBlock(text),
    ];
    final msg = Message.blocks('user', blocks);
    _history.add(msg);
    final res = await _ai._sendRaw(messages: _history, systemPrompt: systemPrompt, maxTokens: maxTokens);
    _history.add(res.toMessage());
    return res;
  }

  void reset() { _history.clear(); print('[Conversation] Cleared.'); }

  void printHistory() {
    print('\n\u2554\u2550\u2550 Conversation History ($turnCount turns) \u2550\u2550\u2557');
    for (final m in _history) {
      final label = m.role == 'user' ? '\u{1F464} You  ' : '\u{1F916} Zhyrx';
      final t     = m.blocks.whereType<TextBlock>().lastOrNull?.text ?? '';
      final snip  = t.length > 80 ? '${t.substring(0, 80)}...' : t;
      print('  $label: $snip');
    }
    print('\u255a${'═' * 42}\u255d\n');
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  ZHYRX AI — MAIN CLIENT
// ════════════════════════════════════════════════════════════════════════════

class ZhyrxAI {
  final String     apiKey;
  final HttpClient _http = HttpClient();
  ZhyrxAI({required this.apiKey});

  Future<AiResponse> _sendRaw({
    required List<Message> messages,
    String? systemPrompt,
    int    maxTokens   = _kDefaultMaxTokens,
    double temperature = 1.0,
  }) async {
    final body = <String, dynamic>{
      'model': _kModel, 'max_tokens': maxTokens, 'temperature': temperature,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) body['system'] = systemPrompt;

    final req = await _http.postUrl(Uri.parse(_kBaseUrl));
    req.headers
      ..set('Content-Type', 'application/json')
      ..set('x-api-key', apiKey)
      ..set('anthropic-version', _kAnthropicVersion);
    req.write(jsonEncode(body));
    final res = await req.close();
    final raw = await res.transform(utf8.decoder).join();
    if (res.statusCode != 200) throw Exception('[ZhyrxAI] API Error ${res.statusCode}: $raw');
    return AiResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String> _streamRaw({
    required List<Message> messages,
    String? systemPrompt,
    int    maxTokens   = _kDefaultMaxTokens,
    double temperature = 1.0,
    required void Function(String delta) onChunk,
  }) async {
    final body = <String, dynamic>{
      'model': _kModel, 'max_tokens': maxTokens, 'temperature': temperature,
      'stream': true, 'messages': messages.map((m) => m.toJson()).toList(),
    };
    if (systemPrompt != null && systemPrompt.isNotEmpty) body['system'] = systemPrompt;

    final req = await _http.postUrl(Uri.parse(_kBaseUrl));
    req.headers
      ..set('Content-Type', 'application/json')
      ..set('x-api-key', apiKey)
      ..set('anthropic-version', _kAnthropicVersion);
    req.write(jsonEncode(body));
    final res   = await req.close();
    final lines = await res.transform(utf8.decoder).transform(const LineSplitter()).toList();

    final buffer = StringBuffer();
    for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      if (data == '[DONE]') break;
      try {
        final j = jsonDecode(data) as Map<String, dynamic>;
        if (j['type'] == 'content_block_delta') {
          final d = (j['delta'] as Map<String, dynamic>?)?['text'] as String? ?? '';
          if (d.isNotEmpty) { buffer.write(d); onChunk(d); }
        }
      } catch (_) {}
    }
    return buffer.toString();
  }

  Future<AiResponse> _quick({
    required String             systemPrompt,
    required List<ContentBlock> blocks,
    String? text,
    int    maxTokens   = _kDefaultMaxTokens,
    double temperature = 1.0,
  }) {
    final all = [...blocks, if (text != null && text.isNotEmpty) TextBlock(text)];
    return _sendRaw(systemPrompt: systemPrompt, messages: [Message.blocks('user', all)],
        maxTokens: maxTokens, temperature: temperature);
  }

  // ──────────────────── 1. CHAT ────────────────────
  Future<AiResponse> chat(
    String message, {
    List<Message> history     = const [],
    String systemPrompt       = 'You are a helpful assistant named Zhyrx.',
    int    maxTokens          = _kDefaultMaxTokens,
  }) => _sendRaw(messages: [...history, Message.text('user', message)],
        systemPrompt: systemPrompt, maxTokens: maxTokens);

  // ──────────────────── 2. STREAM CHAT ────────────────────
  Future<String> streamChat(
    String message, {
    List<Message> history     = const [],
    String systemPrompt       = 'You are a helpful assistant named Zhyrx.',
    int    maxTokens          = _kDefaultMaxTokens,
    required void Function(String token) onToken,
  }) => _streamRaw(messages: [...history, Message.text('user', message)],
        systemPrompt: systemPrompt, maxTokens: maxTokens, onChunk: onToken);

  // ──────────────────── 3. CONVERSATION ────────────────────
  Conversation startConversation({
    String systemPrompt = 'You are Zhyrx, a helpful AI. You can analyze images, PDFs, and files.',
    int maxTokens = _kDefaultMaxTokens,
  }) => Conversation(this, systemPrompt: systemPrompt, maxTokens: maxTokens);

  // ──────────────────── 4. UPLOAD & ASK ────────────────────
  Future<AiResponse> askAboutFiles(
    String question, {
    required List<String> filePaths,
    List<String> imageUrls    = const [],
    String systemPrompt       = 'Analyze the provided files carefully and answer accurately.',
    int    maxTokens          = 4096,
  }) {
    final blocks = <ContentBlock>[
      ...imageUrls.map((u) => ImageBlock.fromUrl(u)),
      ...filePaths.map(Attachment.fromPath),
    ];
    return _quick(systemPrompt: systemPrompt, blocks: blocks, text: question, maxTokens: maxTokens);
  }

  // ──────────────────── 5. DESCRIBE IMAGE ────────────────────
  Future<AiResponse> describeImage(
    String pathOrUrl, {
    String prompt    = 'Describe this image in detail. Include objects, colors, text, context, and anything notable.',
    int    maxTokens = 1024,
  }) {
    final block = pathOrUrl.startsWith('http') ? ImageBlock.fromUrl(pathOrUrl) : ImageBlock.fromFile(pathOrUrl);
    return _quick(systemPrompt: 'You are an expert visual analyst.', blocks: [block], text: prompt, maxTokens: maxTokens);
  }

  // ──────────────────── 6. COMPARE IMAGES ────────────────────
  Future<AiResponse> compareImages(
    List<String> pathsOrUrls, {
    String prompt    = 'Compare these images. List key similarities and differences.',
    int    maxTokens = 2048,
  }) {
    final blocks = pathsOrUrls.map<ContentBlock>((s) =>
        s.startsWith('http') ? ImageBlock.fromUrl(s) : ImageBlock.fromFile(s)).toList();
    return _quick(systemPrompt: 'You are a visual comparison expert.', blocks: blocks, text: prompt, maxTokens: maxTokens);
  }

  // ──────────────────── 7. OCR ────────────────────
  Future<AiResponse> ocrImage(
    String pathOrUrl, {
    String? languageHint,
    bool    preserveLayout = true,
    int     maxTokens      = 4096,
  }) {
    final block = pathOrUrl.startsWith('http') ? ImageBlock.fromUrl(pathOrUrl) : ImageBlock.fromFile(pathOrUrl);
    final layout = preserveLayout ? 'Preserve layout with line breaks.' : 'Extract in reading order.';
    final lang   = languageHint != null ? ' Language: $languageHint.' : '';
    return _quick(
      systemPrompt: 'You are a precise OCR engine. Extract ALL visible text exactly.$lang $layout No commentary.',
      blocks: [block], maxTokens: maxTokens);
  }

  // ──────────────────── 8. VISION QA ────────────────────
  Future<AiResponse> visionQA(String pathOrUrl, String question, {int maxTokens = 1024}) {
    final block = pathOrUrl.startsWith('http') ? ImageBlock.fromUrl(pathOrUrl) : ImageBlock.fromFile(pathOrUrl);
    return _quick(systemPrompt: 'Answer questions about the image accurately and concisely.',
        blocks: [block], text: question, maxTokens: maxTokens);
  }

  // ──────────────────── 9. ASK PDF ────────────────────
  Future<AiResponse> askPdf(String pdfPath, {required String question, int maxTokens = 4096}) =>
      _quick(systemPrompt: 'Answer based only on the provided PDF content.',
          blocks: [PdfBlock.fromFile(pdfPath)], text: question, maxTokens: maxTokens);

  // ──────────────────── 10. SUMMARIZE PDF ────────────────────
  Future<AiResponse> summarizePdf(String pdfPath, {String style = 'bullet', int maxTokens = 4096}) {
    final hint = {'concise': 'Write 3-5 sentences.', 'bullet': 'Use structured bullet points.',
        'detailed': 'Detailed summary with headings.', 'executive': 'Executive summary with Overview, Key Points, Conclusion.'}[style]
        ?? 'Use bullet points.';
    return _quick(systemPrompt: 'You are a professional summarizer. $hint',
        blocks: [PdfBlock.fromFile(pdfPath)], maxTokens: maxTokens);
  }

  // ──────────────────── 11. ASK FILE ────────────────────
  Future<AiResponse> askFile(String filePath, {required String question, int maxTokens = 2048}) =>
      _quick(systemPrompt: 'Analyze the provided file and answer accurately.',
          blocks: [Attachment.fromPath(filePath)], text: question, maxTokens: maxTokens);

  // ──────────────────── 12. ANALYZE CSV ────────────────────
  Future<AiResponse> analyzeCsv(String csvPath, {
    String prompt = 'Analyze this CSV. Identify statistics, patterns, outliers, and insights.',
    int maxTokens = 2048,
  }) => _quick(systemPrompt: 'You are a data analyst. Provide clear, structured insights.',
      blocks: [FileTextBlock.fromFile(csvPath)], text: prompt, maxTokens: maxTokens);

  // ──────────────────── 13. REVIEW CODE FILE ────────────────────
  Future<AiResponse> reviewCodeFile(String filePath, {
    String focus = 'all', int maxTokens = 4096,
  }) {
    final hint = {'bugs': 'Focus on bugs.', 'performance': 'Focus on performance.',
        'security': 'Focus on security.', 'style': 'Focus on style and best practices.',
        'all': 'Review bugs, performance, security, and quality.'}[focus] ?? 'Review everything.';
    return _quick(systemPrompt: 'You are a senior engineer doing code review. $hint',
        blocks: [Attachment.fromPath(filePath)], maxTokens: maxTokens);
  }

  // ──────────────────── 14. FIX CODE ────────────────────
  Future<AiResponse> fixCode(String code, {
    String language = 'dart', String? errorMessage, int maxTokens = 2048,
  }) {
    final err = errorMessage != null ? '\n\nError:\n$errorMessage' : '';
    return _quick(
      systemPrompt: 'Expert $language developer. Fix bugs. Return corrected code with brief inline comments.',
      blocks: [TextBlock('```$language\n$code\n```$err')], maxTokens: maxTokens, temperature: 0.2);
  }

  // ──────────────────── 15. EXPLAIN CODE ────────────────────
  Future<AiResponse> explainCode(String code, {
    String language = 'dart', String level = 'intermediate', int maxTokens = 1024,
  }) {
    final hint = {'beginner': 'Simple explanation, no jargon, use analogies.',
        'intermediate': 'Clear with technical terms.', 'expert': 'Deep with trade-offs.'}[level] ?? 'Clear explanation.';
    return _quick(systemPrompt: 'You are a $language expert and teacher. $hint',
        blocks: [TextBlock('```$language\n$code\n```')], text: 'Explain this code.', maxTokens: maxTokens);
  }

  // ──────────────────── 16. GENERATE ────────────────────
  Future<AiResponse> generate(String prompt, {
    String type = 'text', int maxTokens = 1024,
  }) {
    final hint = {'text': 'Plain text.', 'code': 'Code only, no explanation.',
        'json': 'Valid JSON only, no markdown fences.', 'markdown': 'Markdown format.',
        'html': 'Valid HTML5 only.'}[type] ?? '';
    return _quick(systemPrompt: 'Precise content generator. $hint',
        blocks: [TextBlock(prompt)], maxTokens: maxTokens);
  }

  // ──────────────────── 17. SUMMARIZE ────────────────────
  Future<AiResponse> summarize(String text, {String style = 'bullet', int maxTokens = 512}) {
    final hint = {'concise': '2-3 sentences.', 'bullet': 'Bullet points.', 'detailed': 'Detailed with context.'}[style]
        ?? 'Bullet points.';
    return _quick(systemPrompt: 'Professional summarizer. $hint', blocks: [TextBlock(text)], maxTokens: maxTokens);
  }

  // ──────────────────── 18. TRANSLATE ────────────────────
  Future<AiResponse> translate(String text, {
    required String targetLanguage, String? sourceLanguage, bool formalTone = false, int maxTokens = 1024,
  }) {
    final from   = sourceLanguage != null ? 'from $sourceLanguage ' : '';
    final formal = formalTone ? ' Use formal register.' : '';
    return _quick(systemPrompt: 'Translate ${from}to $targetLanguage.$formal Return translation only.',
        blocks: [TextBlock(text)], maxTokens: maxTokens);
  }

  // ──────────────────── 19. CLASSIFY ────────────────────
  Future<AiResponse> classify(String text, {
    required List<String> labels, bool returnReason = false, int maxTokens = 128,
  }) {
    final extra = returnReason ? ' Add one-sentence reason after label, separated by ": ".' : ' Label only.';
    return _quick(systemPrompt: 'Classify into one of: ${labels.join(', ')}.$extra',
        blocks: [TextBlock(text)], maxTokens: maxTokens, temperature: 0.0);
  }

  // ──────────────────── 20. EXTRACT ────────────────────
  Future<AiResponse> extract(String text, {required String schema, int maxTokens = 1024}) =>
      _quick(systemPrompt: 'Extract data per JSON schema:\n$schema\nReturn valid JSON only, no markdown.',
          blocks: [TextBlock(text)], maxTokens: maxTokens, temperature: 0.0);

  // ──────────────────── 21. SENTIMENT ────────────────────
  Future<AiResponse> analyzeSentiment(String text, {bool detailed = false, int maxTokens = 256}) {
    final d = detailed
        ? 'Return JSON: {sentiment, score(-1 to 1), emotions(array), key_phrases(array)}.'
        : 'One word: positive, negative, neutral, or mixed.';
    return _quick(systemPrompt: 'Sentiment analysis expert. $d',
        blocks: [TextBlock(text)], maxTokens: maxTokens, temperature: 0.0);
  }

  // ──────────────────── 22. PROOFREAD ────────────────────
  Future<AiResponse> proofread(String text, {bool showChanges = true, int maxTokens = 2048}) {
    final extra = showChanges ? ' After corrected text, add "Changes:" section listing every edit.' : '';
    return _quick(systemPrompt: 'Professional editor. Fix grammar, spelling, punctuation. Keep meaning.$extra',
        blocks: [TextBlock(text)], maxTokens: maxTokens, temperature: 0.1);
  }

  // ──────────────────── 23. CUSTOM ────────────────────
  Future<AiResponse> custom({
    required String             systemPrompt,
    required List<ContentBlock> blocks,
    int    maxTokens   = _kDefaultMaxTokens,
    double temperature = 1.0,
  }) => _quick(systemPrompt: systemPrompt, blocks: blocks, maxTokens: maxTokens, temperature: temperature);

  void dispose() => _http.close();
}

// ════════════════════════════════════════════════════════════════════════════
//  DEMO — main()
// ════════════════════════════════════════════════════════════════════════════

Future<void> main() async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('[ZhyrxAI] Set ANTHROPIC_API_KEY environment variable first.');
    exit(1);
  }

  final ai = ZhyrxAI(apiKey: apiKey);

  void header(int n, String title) {
    print('\n╔══════════════════════════════════════════════════════╗');
    print('  $n. $title');
    print('╚══════════════════════════════════════════════════════╝');
  }

  try {
    header(1, 'Chat (stateless)');
    print(await ai.chat('Siapa kamu dan apa yang bisa kamu bantu?',
        systemPrompt: 'Kamu asisten AI bernama Zhyrx. Jawab singkat.'));

    header(2, 'Stream Chat (real-time)');
    stdout.write('Zhyrx: ');
    await ai.streamChat('Sebutkan 3 keunggulan Flutter.', onToken: (t) => stdout.write(t));
    print('\n');

    header(3, 'Conversation (stateful, multi-turn)');
    final conv = ai.startConversation();
    print('T1: ${(await conv.send('Namaku Andi, aku suka Flutter.')).text}');
    print('T2: ${(await conv.send('Siapa namaku dan apa yang aku suka?')).text}');
    conv.printHistory();

    header(4, 'Describe Image (URL)');
    print(await ai.describeImage(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png',
      prompt: 'Apa yang ada di gambar ini?',
    ));

    header(5, 'Vision QA');
    print(await ai.visionQA(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png',
      'Apakah ada teks dalam gambar ini?',
    ));

    header(6, 'OCR — Extract text from image');
    print(await ai.ocrImage(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/PNG_transparency_demonstration_1.png/280px-PNG_transparency_demonstration_1.png',
    ));

    header(7, 'Summarize Text');
    print(await ai.summarize(
      'Dart adalah bahasa pemrograman open-source oleh Google untuk mobile, web, desktop. '
      'Digunakan Flutter. Dikompilasi ke native code.',
      style: 'bullet',
    ));

    header(8, 'Translate (formal)');
    print(await ai.translate(
      'Artificial intelligence is transforming every industry.',
      targetLanguage: 'Indonesian', formalTone: true,
    ));

    header(9, 'Fix Code');
    print(await ai.fixCode(
      'void main() {\n  int x = "hello";\n  print(x)\n}',
      language: 'dart', errorMessage: "String can't be assigned to int",
    ));

    header(10, 'Explain Code (beginner)');
    print(await ai.explainCode(
      'final nums = [3,1,4,1,5]..sort();\nprint(nums.first);',
      language: 'dart', level: 'beginner',
    ));

    header(11, 'Classify with reason');
    print(await ai.classify(
      'Laptop saya tidak menyala setelah update.',
      labels: ['teknis', 'penagihan', 'umum', 'pengiriman'], returnReason: true,
    ));

    header(12, 'Extract Structured JSON');
    print(await ai.extract(
      'Hubungi Budi di budi@zhyrx.id, +62 812-3456-7890, Jakarta.',
      schema: '{"name":"string","email":"string","phone":"string","city":"string"}',
    ));

    header(13, 'Sentiment Analysis (detailed)');
    print(await ai.analyzeSentiment(
      'Produknya luar biasa tapi pengiriman sangat lambat!', detailed: true,
    ));

    header(14, 'Proofread');
    print(await ai.proofread('saya sdh makan nasi goreng tdi pagi. rasanya enak sekal.'));

    header(15, 'Generate JSON');
    print(await ai.generate(
      'Buat data 3 produk elektronik: id, name, price (IDR), category.',
      type: 'json',
    ));

    // ── UNCOMMENT TO TEST LOCAL FILES ─────────────────────────────────
    //
    // header(16, 'Local image');
    // print(await ai.describeImage('/path/to/photo.jpg'));
    //
    // header(17, 'Ask PDF');
    // print(await ai.askPdf('/path/to/doc.pdf', question: 'Apa poin utamanya?'));
    //
    // header(18, 'Summarize PDF (executive)');
    // print(await ai.summarizePdf('/path/to/report.pdf', style: 'executive'));
    //
    // header(19, 'Review code file');
    // print(await ai.reviewCodeFile('/path/to/main.dart', focus: 'all'));
    //
    // header(20, 'Analyze CSV');
    // print(await ai.analyzeCsv('/path/to/data.csv'));
    //
    // header(21, 'Multiple files at once');
    // print(await ai.askAboutFiles('Apa perbedaan kedua file ini?',
    //     filePaths: ['/path/to/a.dart', '/path/to/b.dart']));
    //
    // header(22, 'Compare two images');
    // print(await ai.compareImages(['/path/img1.png', '/path/img2.jpg']));
    //
    // header(23, 'Conversation + image upload');
    // final c2 = ai.startConversation();
    // print((await c2.send('Apa di gambar ini?', filePaths: ['/path/photo.png'])).text);
    // print((await c2.send('Warna apa saja yang ada?')).text);

    print('\n✅  Semua demo selesai!');

  } catch (e, st) {
    stderr.writeln('[ZhyrxAI] Error: $e\n$st');
  } finally {
    ai.dispose();
  }
}
