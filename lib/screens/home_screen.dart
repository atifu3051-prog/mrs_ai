import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/assistant_provider.dart';
import '../widgets/ai_orb_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktopOrTablet = size.width > 680;

    return Scaffold(
      backgroundColor: const Color(0xFF06060A), // Deep black-navy space
      body: SafeArea(
        child: Stack(
          children: [
            // Sci-fi Neon Background Blur Blobs
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00FFF0).withOpacity(0.04),
                  // Background glowing aura
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: Container(
                width: 350,
                height: 350,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFBF5AF2).withOpacity(0.03),
                ),
              ),
            ),

            // Main UI Layout Wrapper
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 12.0),
                  Expanded(
                    child: isDesktopOrTablet
                        ? _buildDesktopLayout(context)
                        : _buildMobileLayout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HEADER BANNER ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "MRS AI",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              "// COGNITIVE HUB v4.0",
              style: GoogleFonts.shareTechMono(
                color: const Color(0xFF00FFF0).withOpacity(0.6),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            context.read<AssistantProvider>().clearChat();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Chat buffer flushed. Core re-aligned."),
                backgroundColor: Color(0xFF0A0A14),
              ),
            );
          },
          icon: const Icon(Icons.refresh, color: Colors.white70),
          tooltip: "Re-initialize links",
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.04),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
      ],
    );
  }

  // --- RESPONSIVE DESKTOP LAYOUT (2 Columns) ---
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Column: Interactive Orb Panel
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.only(right: 16.0),
            decoration: _buildGlassBoxDecoration(),
            child: _buildOrbControlPanel(context),
          ),
        ),
        // Right Column: Chat History and Console Console
        Expanded(
          flex: 6,
          child: Container(
            decoration: _buildGlassBoxDecoration(),
            child: Column(
              children: [
                Expanded(child: _buildChatList(context)),
                _buildConsoleInput(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- RESPONSIVE MOBILE LAYOUT (Stacked) ---
  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Upper section: Orb Interface
        _buildOrbControlPanel(context),
        const SizedBox(height: 12.0),
        // Lower Section: Chat panel
        Expanded(
          child: Container(
            decoration: _buildGlassBoxDecoration(),
            child: Column(
              children: [
                Expanded(child: _buildChatList(context)),
                _buildConsoleInput(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- COMMON ORB INTERFACE CONTROL ---
  Widget _buildOrbControlPanel(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        AiOrbWidget(
          state: provider.state,
          onTap: () {
            if (provider.state == AssistantState.idle) {
              provider.startListening();
            } else if (provider.state == AssistantState.listening) {
              provider.stopListeningAndProcess("perform diagnostics scan");
            }
          },
        ),
        const SizedBox(height: 16.0),
        Text(
          _getStateLabel(provider.state),
          style: GoogleFonts.shareTechMono(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          _getStateDescription(provider.state),
          style: GoogleFonts.outfit(
            color: Colors.white38,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // --- CHAT MESSAGES PANEL ---
  Widget _buildChatList(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    _scrollToBottom();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: provider.messages.length,
      itemBuilder: (context, index) {
        final message = provider.messages[index];
        return _buildChatBubble(message);
      },
    );
  }

  Widget _buildChatBubble(dynamic message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: Radius.circular(isUser ? 16.0 : 4.0),
            bottomRight: Radius.circular(isUser ? 4.0 : 16.0),
          ),
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF00FFF0), Color(0xFF007AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white.withOpacity(0.04),
          border: isUser
              ? null
              : Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Text(
                "MRS AI",
                style: GoogleFonts.shareTechMono(
                  color: const Color(0xFFBF5AF2),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4.0),
            ],
            Text(
              message.text,
              style: GoogleFonts.outfit(
                color: isUser ? Colors.black : Colors.whitee8,
                fontSize: 14,
                fontWeight: isUser ? FontWeight.w500 : FontWeight.w400,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CONSOLE TEXT INPUT BAR ---
  Widget _buildConsoleInput(BuildContext context) {
    final provider = context.watch<AssistantProvider>();
    final isProcessing = provider.state == AssistantState.thinking || 
                         provider.state == AssistantState.speaking;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF08080C),
        border: Border.top(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: isProcessing ? "Core is busy..." : "Enter system command...",
                  hintStyle: GoogleFonts.outfit(color: Colors.white30, fontSize: 13),
                  border: InputBorder.none,
                ),
                enabled: !isProcessing && provider.state != AssistantState.listening,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Voice Actions Button (Supports Tap and Push-To-Talk)
          GestureDetector(
            onLongPressStart: (_) {
              if (provider.state == AssistantState.idle) {
                provider.startListening();
              }
            },
            onLongPressEnd: (_) {
              if (provider.state == AssistantState.listening) {
                provider.stopListening();
              }
            },
            onTap: () {
              if (provider.state == AssistantState.idle) {
                provider.startListening();
              } else if (provider.state == AssistantState.listening) {
                provider.stopListening();
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: provider.state == AssistantState.listening
                    ? const Color(0xFF00FF9D).withOpacity(0.15)
                    : Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: provider.state == AssistantState.listening
                      ? const Color(0xFF00FF9D)
                      : Colors.white.withOpacity(0.06),
                ),
                boxShadow: provider.state == AssistantState.listening
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00FF9D).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Icon(
                provider.state == AssistantState.listening ? Icons.mic : Icons.mic_none,
                color: provider.state == AssistantState.listening
                    ? const Color(0xFF00FF9D)
                    : Colors.white70,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          GestureDetector(
            onTap: isProcessing ? null : () => _handleMessageSend(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isProcessing
                      ? [Colors.white24, Colors.white10]
                      : [const Color(0xFF00FFF0), const Color(0xFF007AFF)],
                ),
                boxShadow: isProcessing
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF00FFF0).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMessageSend(BuildContext context) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    context.read<AssistantProvider>().submitCommand(text);
  }

  // --- UTILS ---
  BoxDecoration _buildGlassBoxDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.02),
      borderRadius: BorderRadius.circular(20.0),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  String _getStateLabel(AssistantState state) {
    switch (state) {
      case AssistantState.listening:
        return "VOCAL INTAKE ACTIVE";
      case AssistantState.thinking:
        return "PROCESSING PROTOCOLS";
      case AssistantState.speaking:
        return "TRANSMITTING SIGNALS";
      case AssistantState.executing:
        return "EXECUTING SYSTEM COMMANDS";
      case AssistantState.idle:
      default:
        return "REACTOR IDLE";
    }
  }

  String _getStateDescription(AssistantState state) {
    switch (state) {
      case AssistantState.listening:
        return "Listening to vocal signatures. Tap orb to execute.";
      case AssistantState.thinking:
        return "Scanning neural indexes. Compiling responses...";
      case AssistantState.speaking:
        return "Broadcasting verbal audio. Modulating frequencies...";
      case AssistantState.executing:
        return "Establishing platform links. Deploying requested applications...";
      case AssistantState.idle:
      default:
        return "Linked and secure. Tap orb to establish vocal pathways.";
    }
  }
}

// Extension to clean text styler font errors
extension TextExtension on TextStyle {
  TextStyle get whitee8 => copyWith(color: Colors.white.withOpacity(0.85));
}
