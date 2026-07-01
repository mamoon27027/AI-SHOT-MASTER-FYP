import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:video_player/video_player.dart';
import 'package:ea_master_demo/const/appTheme.dart';
import 'train_models.dart';
import 'train_camera_screen.dart';

class TrainDemoScreen extends StatefulWidget {
  final TrainingShot shot;

  const TrainDemoScreen({super.key, required this.shot});

  @override
  State<TrainDemoScreen> createState() => _TrainDemoScreenState();
}

class _TrainDemoScreenState extends State<TrainDemoScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.shot.demoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.asset(widget.shot.demoUrl)
        ..initialize().then((_) {
          setState(() {
            _isVideoInitialized = true;
          });
          // Autoplay the video
          _videoController?.play();
          _videoController?.setLooping(true);
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: AppColors.accent, size: 16),
                label: const Text('Back', style: TextStyle(color: AppColors.accent)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${widget.shot.name} Demo', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Watch professional technique before training', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    const SizedBox(height: 24),

                    // Video Player or Fallback
                    AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            children: [
                              if (_isVideoInitialized && _videoController != null)
                                Positioned.fill(
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _videoController!.value.size.width,
                                      height: _videoController!.value.size.height,
                                      child: VideoPlayer(_videoController!),
                                    ),
                                  ),
                                )
                              else
                                Positioned.fill(
                                  child: Image.network(
                                    widget.shot.imageUrl,
                                    fit: BoxFit.cover,
                                    color: Colors.black.withOpacity(0.4),
                                    colorBlendMode: BlendMode.darken,
                                  ),
                                ),
                              
                              // Play/Pause Overlay
                              if (_isVideoInitialized)
                                Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      });
                                    },
                                    child: AnimatedOpacity(
                                      opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                                      duration: const Duration(milliseconds: 300),
                                      child: Container(
                                        width: 80, height: 80,
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGreen.withOpacity(0.8),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow, color: Color(0xFF0F172A), size: 40),
                                      ),
                                    ),
                                  ),
                                )
                              else
                                const Center(
                                  child: CircularProgressIndicator(color: AppColors.accentGreen),
                                ),

                              Positioned(
                                top: 16, left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.videocam, color: AppColors.accent, size: 16),
                                      SizedBox(width: 8),
                                      Text('Expert Demo', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  )
                                )
                              ),
                              Positioned(
                                bottom: 16, left: 16, right: 16,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Key Focus Points:', style: TextStyle(color: Colors.white, fontSize: 14)),
                                      const SizedBox(height: 8),
                                      ...widget.shot.focusPoints.take(3).map((pt) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Text('• $pt', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                                      )).toList()
                                    ],
                                  )
                                )
                              )
                            ],
                          ),
                        )
                      )
                    ),
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Note: Use off so that Back button inside camera goes back to detail screen, not demo
                          Get.off(() => TrainCameraScreen(shot: widget.shot));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          )
                        ),
                        icon: const Icon(Icons.play_arrow, color: Color(0xFF0F172A)),
                        label: const Text('Start Training Now', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
                      )
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_isVideoInitialized && _videoController != null) {
                            _videoController!.seekTo(Duration.zero);
                            _videoController!.play();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: AppColors.accent.withOpacity(0.2)),
                          )
                        ),
                        child: const Text('Watch Again', style: TextStyle(color: Colors.white, fontSize: 16)),
                      )
                    )
                  ],
                )
              )
            ]
          )
        )
      )
    );
  }
}
