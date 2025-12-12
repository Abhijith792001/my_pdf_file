import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get_storage/get_storage.dart';

class ChatController extends GetxController {
  late String filePath;
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoading = false.obs;
  final RxBool hasApiKey = false.obs;

  GenerativeModel? _model;
  ChatSession? _chat;

  // TODO: Replace with your actual Gemini API Key
  static const String _hardcodedApiKey =
      "AIzaSyDJ3dL4xKphb7yHnUv7Y9nnr4effJMqWyI";

  @override
  void onInit() {
    super.onInit();
    filePath = Get.arguments as String? ?? "";
    _checkApiKey();
  }

  void _checkApiKey() {
    // Prioritize hardcoded key if set (and not the default placeholder)
    if (_hardcodedApiKey != "YOUR_API_KEY_HERE" &&
        _hardcodedApiKey.isNotEmpty) {
      _initModel(_hardcodedApiKey);
      hasApiKey.value = true;
      return;
    }

    // Fallback to storage or dialog if hardcoded key is missing
    final key = GetStorage().read('gemini_api_key');
    if (key != null && key.toString().isNotEmpty) {
      _initModel(key);
      hasApiKey.value = true;
    } else {
      hasApiKey.value = false;
      // Prompt user for key
      Future.delayed(Duration.zero, () => _showApiKeyDialog());
    }
  }

  void _initModel(String key) {
    _model = GenerativeModel(model: 'gemini-flash-latest', apiKey: key);
  }

  void saveApiKey(String key) {
    GetStorage().write('gemini_api_key', key);
    _initModel(key);
    hasApiKey.value = true;
  }

  Future<void> _showApiKeyDialog() async {
    await Get.defaultDialog(
      title: "Gemini API Key Required",
      content: Column(
        children: [
          const Text(
            "To chat with this PDF, please enter your Google Gemini API Key.",
          ),
          const SizedBox(height: 10),
          TextField(
            controller: TextEditingController(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "API Key",
            ),
            onSubmitted: (val) {
              if (val.isNotEmpty) Get.back(result: val);
            },
          ),
        ],
      ),
      textConfirm: "Save",
      onConfirm: () {
        Get.back(result: "DIALOG_CONFIRMED");
      },
    );
  }

  Future<void> sendMessage() async {
    if (inputController.text.isEmpty || _model == null) return;

    final userText = inputController.text;
    inputController.clear();

    messages.add(ChatMessage(text: userText, isUser: true));
    isLoading.value = true;
    _scrollToBottom();

    try {
      if (_chat == null) {
        // First message: Send PDF + Prompt
        final file = File(filePath);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();

          // We can start a chat or generate content.
          // ChatSession doesn't easily support initial DataPart in history for all SDK versions?
          // Let's try to just use generateContent for first turn, or startChat.
          // gemini-1.5-flash supports PDF.

          // If we want history, we should use startChat.
          // But we need to feed the PDF as specific history or system usage.
          // Let's just send PDF with every request? No, expensive.
          // Send it once in history.

          _chat = _model!.startChat(
            history: [
              Content.multi([
                TextPart("Here is the PDF file I want to discuss."),
                DataPart('application/pdf', bytes),
              ]),
            ],
          );

          var response = await _chat!.sendMessage(Content.text(userText));
          messages.add(
            ChatMessage(text: response.text ?? "Error", isUser: false),
          );
        } else {
          messages.add(ChatMessage(text: "PDF File not found.", isUser: false));
        }
      } else {
        // Subsequent messages
        var response = await _chat!.sendMessage(Content.text(userText));
        messages.add(
          ChatMessage(text: response.text ?? "Error", isUser: false),
        );
      }
    } catch (e) {
      messages.add(ChatMessage(text: "Error: $e", isUser: false));
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}
