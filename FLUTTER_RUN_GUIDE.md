# EA Shot Master — Flutter demo (ready to run)

This folder is a **complete test app** (steps 7–10 done for you).

## What it does

1. Loads **MoveNet** `.tflite` from assets.
2. Opens **front camera**, runs pose ~15 FPS.
3. **`CricketCoachEngine`** detects a swing and scores vs **`cricket_benchmarks.json`**.
4. **Test screen**: choose **Any shot** or **Practice one** (dropdown), **Start coaching**, play a swing, read **accuracy %**.

## Run on your phone
## Use Real devie
```bash
cd mobile_application_pipeline/ea_master_demo
flutter pub get
flutter devices
flutter run
```

Grant **camera** when asked.

## If you already created your own Flutter project

Copy into your project:

| From this demo | To your project |
|----------------|-----------------|
| `lib/pipeline/` | `lib/pipeline/` |
| `lib/services/` | `lib/services/` |
| `lib/screens/shot_test_screen.dart` | same path |
| `lib/main.dart` | or set `home: ShotTestScreen()` |
| `assets/models/*.tflite` | same |
| `assets/data/cricket_benchmarks.json` | same |
| `pubspec.yaml` dependencies + assets | merge into yours |
| Android camera permission + `minSdk 24` | same |
| iOS `NSCameraUsageDescription` | same |

## Files map

- `lib/services/movenet_pose_service.dart` — TF Lite pose → joint map
- `lib/services/camera_yuv_converter.dart` — camera frame → RGB
- `lib/services/coaching_bootstrap.dart` — load JSON benchmarks
- `lib/pipeline/cricket_coach_engine.dart` — start/stop + scoring
- `lib/screens/shot_test_screen.dart` — UI for testing

## Troubleshooting

- **Build fails on TFLite**: use a **physical device**; ensure `minSdk 24` on Android.
- **No green skeleton / 0 joints**: full body in frame, good light, stand 2–3 m back. Top bar should show `8/13` or more before swinging.
- **Camera lag when coaching**: pull latest code — pose now runs off the camera thread with Y-only fast input + `ResolutionPreset.low`.
- **Result slow**: app waits for swing end (~12+ frames of motion), then shows “Analyzing…”. Wrong shot often means joints were poor — fix skeleton first.
- **Wrong shot in practice mode**: `identityMismatch` — classifier saw a different shot than selected.

## API vs on-device speed

| Part | On phone (this demo) | API approach |
|------|----------------------|--------------|
| Camera preview | Smooth if pose not on camera thread | Same |
| Pose / joints | TFLite on device (main cost) | On server **only if** you send images (slow) or phone still does pose |
| Shot + % score | Fast Dart math | Fast on server if you send **joint numbers** only |
| Network | None | Adds delay only for upload |

**Lag you saw** was mostly **heavy work on the camera callback** (full RGB + TFLite), not the benchmark scorer. An API does **not** fix bad joints unless the server runs pose on uploaded video (slower than sending landmarks).
