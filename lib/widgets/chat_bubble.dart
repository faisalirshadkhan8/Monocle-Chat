// ignore_for_file: deprecated_member_use

import 'package:cached_network_image/cached_network_image.dart'; // For displaying network images
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // For video playback

class ChatBubble extends StatefulWidget {
  final String message;
  final String timestamp;
  final bool isSeen;
  final bool isSent;
  final String? mediaUrl;
  final String messageType; // 'text', 'image', or 'video'

  const ChatBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isSeen,
    required this.isSent,
    this.mediaUrl,
    required this.messageType,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.messageType == 'video' && widget.mediaUrl != null) {
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.mediaUrl!),
        )
        ..initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _isVideoInitialized = true;
                });
              }
            })
            .catchError((error) {
              print("Error initializing video player: $error");
              if (mounted) {
                setState(() {
                  _isVideoInitialized =
                      false; // Ensure UI can reflect error state
                });
              }
            });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        widget.isSent ? const Color(0xFFE1F5FE) : const Color(0xFFF0F0F0);
    final textColor = widget.isSent ? Colors.black87 : Colors.black87;
    final alignment =
        widget.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final tickColor = widget.isSeen ? Colors.blueAccent : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              widget.isSent
                  ? const Radius.circular(16)
                  : const Radius.circular(0),
          bottomRight:
              widget.isSent
                  ? const Radius.circular(0)
                  : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.messageType == 'image' && widget.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: CachedNetworkImage(
                  imageUrl: widget.mediaUrl!,
                  placeholder:
                      (context, url) => const Center(
                        child: CupertinoActivityIndicator(),
                      ), // Changed to Cupertino
                  errorWidget:
                      (context, url, error) =>
                          const Icon(Icons.error, color: Colors.red),
                  fit: BoxFit.cover,
                  maxHeightDiskCache: 200, // Example: limit cache size
                ),
              ),
            ),
          if (widget.messageType == 'video' && widget.mediaUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child:
                  _isVideoInitialized &&
                          _videoController != null &&
                          _videoController!.value.isInitialized
                      ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: <Widget>[
                            VideoPlayer(_videoController!),
                            _ControlsOverlay(controller: _videoController!),
                          ],
                        ),
                      )
                      : Container(
                        height: 150, // Placeholder height
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const Center(
                          child:
                              CupertinoActivityIndicator(), // Changed to Cupertino
                        ),
                      ),
            ),
          if (widget.message.isNotEmpty || widget.messageType == 'text')
            Text(
              widget.message,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.timestamp,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              if (widget.isSent) ...[
                const SizedBox(width: 5),
                Icon(Icons.done_all, size: 16, color: tickColor),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// Simple overlay for video controls (play/pause)
class _ControlsOverlay extends StatefulWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child:
              widget.controller.value.isPlaying
                  ? const SizedBox.shrink()
                  : Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.play_arrow_solid, // Changed to Cupertino
                        color: Colors.white,
                        size: 50.0,
                        semanticLabel: 'Play',
                      ),
                    ),
                  ),
        ),
        GestureDetector(
          onTap: () {
            if (widget.controller.value.isPlaying) {
              widget.controller.pause();
            } else {
              widget.controller.play();
            }
            setState(() {}); // Rebuild to update play/pause icon
          },
        ),
      ],
    );
  }
}
