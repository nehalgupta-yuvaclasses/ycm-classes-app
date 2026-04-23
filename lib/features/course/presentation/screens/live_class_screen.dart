import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/models/course_model.dart';

class LiveClassArgs {
  final String courseTitle;
  final LessonModel lesson;

  const LiveClassArgs({
    required this.courseTitle,
    required this.lesson,
  });
}

class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key, required this.args});

  final LiveClassArgs args;

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    final playbackUrl = widget.args.lesson.effectivePlaybackUrl;
    if (playbackUrl?.isNotEmpty == true) {
      _controller.loadHtmlString(_buildPlayerHtml(playbackUrl!));
    }
  }

  String _buildPlayerHtml(String rawUrl) {
    final embedUrl = widget.args.lesson.canJoin
        ? _resolveYoutubeEmbedUrl(widget.args.lesson.youtubeLiveUrl ?? widget.args.lesson.liveUrl ?? rawUrl)
        : _resolveYoutubeEmbedUrl(widget.args.lesson.youtubeRecordingUrl ?? widget.args.lesson.videoUrl ?? rawUrl);

    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
    <style>
      html, body { margin: 0; padding: 0; width: 100%; height: 100%; background: #000; overflow: hidden; }
      .wrap { position: fixed; inset: 0; }
      iframe { position: absolute; inset: 0; width: 100%; height: 100%; border: 0; }
    </style>
  </head>
  <body>
    <div class="wrap">
      <iframe src="$embedUrl" allow="autoplay; encrypted-media; picture-in-picture; web-share" allowfullscreen></iframe>
    </div>
  </body>
</html>
''';
  }

  String _resolveYoutubeEmbedUrl(String rawUrl) {
    try {
      final uri = Uri.parse(rawUrl);
      final host = uri.host.replaceFirst(RegExp(r'^www\.'), '');

      if (host == 'youtu.be') {
        final segments = uri.pathSegments.where((segment) => segment.isNotEmpty).toList(growable: false);
        if (segments.isNotEmpty) {
          return 'https://www.youtube.com/embed/${segments.first}?rel=0&modestbranding=1';
        }
      }

      if (host.endsWith('youtube.com')) {
        final embedMatch = RegExp(r'/embed/([^/?]+)').firstMatch(uri.path);
        if (embedMatch != null) {
          return 'https://www.youtube.com/embed/${embedMatch.group(1)}?rel=0&modestbranding=1';
        }

        final videoId = uri.queryParameters['v'];
        if (videoId != null && videoId.isNotEmpty) {
          return 'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1';
        }

        final liveMatch = RegExp(r'/live/([^/?]+)').firstMatch(uri.path);
        if (liveMatch != null) {
          return 'https://www.youtube.com/embed/${liveMatch.group(1)}?rel=0&modestbranding=1';
        }
      }
    } catch (_) {
      return rawUrl;
    }

    return rawUrl;
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.args.lesson;
    final playbackUrl = lesson.effectivePlaybackUrl;
    final statusLabel = lesson.canJoin
      ? 'LIVE NOW'
      : lesson.hasPlayback
        ? 'RECORDED READY'
        : 'UNAVAILABLE';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Live Class'),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(widget.args.courseTitle, style: AppTextStyles.heading3.copyWith(color: Colors.white)),
                  SizedBox(height: 8.h),
                  Text(lesson.title, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9))),
                  SizedBox(height: 14.h),
                  Text(
                    lesson.scheduledAt?.isNotEmpty == true
                      ? 'Scheduled: ${lesson.scheduledAt}'
                      : lesson.canJoin
                        ? 'Live stream embedded below.'
                        : lesson.hasPlayback
                          ? 'Recorded playback embedded below.'
                          : 'No embedded playback URL is available for this lesson.',
                    style: AppTextStyles.bodySm.copyWith(color: Colors.white.withValues(alpha: 0.82)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: playbackUrl?.isNotEmpty == true
                    ? WebViewWidget(controller: _controller)
                    : Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.ondemand_video_outlined, size: 44.sp, color: AppColors.textTertiary),
                              SizedBox(height: 12.h),
                              Text('No embedded playback URL is available for this lesson.', style: AppTextStyles.bodySm),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}