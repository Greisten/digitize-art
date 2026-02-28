# 💡 AI-Powered Lighting Analysis System

## Overview

The **Lighting Analysis System** provides real-time feedback on lighting quality, camera positioning, and potential issues during artwork capture. It runs continuously alongside edge detection to help users capture the best possible images.

## Features

### 🌟 Live Quality Scoring

Real-time overall quality score (0-100%) that combines:
- Exposure levels
- Color temperature
- Positioning accuracy
- Motion blur detection
- Glare/reflection detection
- Shadow detection

### 💡 Exposure Analysis

**Histogram-based exposure evaluation:**
- Detects underexposed images (too dark)
- Detects overexposed images (too bright)
- Identifies perfect exposure range (100-155 mean brightness)
- Provides scores: Perfect (1.0), Slight deviation (0.7), Poor (0.3)

**User feedback:**
- "Too dark - add light"
- "Too bright - reduce light"
- "Perfect exposure"

### 🌡️ Color Temperature Detection

**White balance analysis targeting 4000-6000K range:**
- Estimates color temperature using R/B ratio
- Detects warm lighting (< 4000K) - incandescent, tungsten
- Detects cool lighting (> 6000K) - shade, overcast
- Perfect range: 4000-6000K (daylight, neutral lighting)

**User feedback:**
- "Lighting too warm (yellow)" - add cooler light sources
- "Lighting too cool (blue)" - add warmer light or avoid harsh daylight
- "Perfect color temperature"

**Technical note:** This is an approximation based on RGB analysis. Professional color temperature measurement requires calibrated sensors.

### 📍 Smart Positioning Guide

**Center-of-mass analysis:**
- Calculates brightness-weighted center of the frame
- Compares against ideal center position
- Provides directional hints

**Live arrows display:**
- ⬆️ Move Up
- ⬇️ Move Down
- ⬅️ Move Left
- ➡️ Move Right
- ✅ Centered (when within 10% tolerance)

**Position score:** 0.0 (far off-center) → 1.0 (perfectly centered)

### ⚠️ Quality Warnings

**1. Motion Blur Detection**
- Uses Laplacian variance (edge sharpness metric)
- Low variance = blurry/motion
- Threshold: variance < 100
- **Feedback:** "Hold camera steady"

**2. Glare/Reflection Detection**
- Counts pixels with brightness > 240
- Threshold: > 5% of image area
- **Feedback:** "Glare detected - adjust angle"

**3. Harsh Shadow Detection**
- Identifies dark regions (< 40 brightness) with high contrast edges
- Threshold: > 10% dark pixels with avg contrast > 50
- **Feedback:** "Harsh shadows - adjust lighting"

## User Interface

### Top Status Bar
```
┌──────────────────────────────────────┐
│ ✓ Artwork detected                   │
│   5200K • 85% quality                │
└──────────────────────────────────────┘
```

### Quality Indicator
```
┌──────────────────────────────────────┐
│ ✅ Excellent - Ready to capture!     │
│ ████████████████░░░░ 85%             │
└──────────────────────────────────────┘
```

**Quality ratings:**
- 🟢 **Excellent (80-100%)**: Perfect, ready to capture
- 🟡 **Good (60-79%)**: Acceptable quality
- 🟠 **Fair (40-59%)**: Adjustments recommended
- 🔴 **Poor (0-39%)**: Please adjust before capturing

### Position Arrows

Dynamically displayed when off-center:
```
         ⬆️ Move Up
         
   ⬅️           ➡️
Move Left    Move Right

         ⬇️ Move Down
```

### Info Panel (Bottom)

**Primary issue (if any):**
```
┌──────────────────────────────────────┐
│ ⚠️  Too dark - add light             │
└──────────────────────────────────────┘
```

**Detailed analysis:**
```
┌──────────────────────────────────────┐
│ Lighting Analysis                    │
│ 💡 Exposure: Perfect                 │
│ ✅ Color: 5200K                      │
│ 📷 Motion detected                   │
└──────────────────────────────────────┘
```

## Technical Implementation

### Architecture

```
CameraScreen
    ├── EdgeDetectionService (artwork boundary)
    ├── LightingAnalysisService (quality analysis)
    └── UI Overlays
         ├── AROverlay (edge visualization)
         └── LightingGuidanceOverlay (guidance display)
```

### Performance

**Frame processing rate:** ~5 FPS (200ms per frame)
- Parallel execution of edge detection + lighting analysis
- YUV420 → RGB conversion (once per frame)
- Multiple analysis passes:
  - Histogram calculation
  - Color temperature estimation
  - Position center-of-mass
  - Blur detection (Laplacian)
  - Glare detection (bright pixel count)
  - Shadow detection (dark regions + contrast)

**Optimization strategies:**
- Downsampled processing (every 3-4 pixels in some analyses)
- Center-region sampling for color temperature
- Short-circuit evaluation (skip analysis if previous score was perfect)

### Capture Button Logic

Capture is **enabled** only when:
```dart
(_lastDetection?.hasDetection ?? false) &&  // Artwork found
(_lastLightingAnalysis?.overallScore ?? 0) >= 0.4  // Fair quality or better
```

This ensures users can't accidentally capture poor-quality images.

## Algorithm Details

### Exposure Analysis

1. Build 256-bin brightness histogram
2. Calculate mean brightness
3. Count underexposed pixels (0-29) and overexposed pixels (226-255)
4. Classify:
   - Too Dark: > 30% underexposed
   - Too Light: > 30% overexposed
   - Perfect: mean in 100-155 range
   - Slight variations: score 0.7

### Color Temperature Estimation

1. Sample center 50% of frame (assume artwork is centered)
2. Calculate average R, G, B values
3. Compute R/B ratio
4. Map ratio to estimated Kelvin:
   - R/B < 0.8: ~3000K (warm)
   - R/B 0.8-1.0: ~4000K
   - R/B 1.0-1.2: ~5000K (neutral)
   - R/B 1.2-1.4: ~6000K
   - R/B > 1.4: ~7000K (cool)

**Note:** This is a rough approximation. Professional color meters use spectral analysis.

### Motion Blur (Laplacian Variance)

1. Sample center 40% of frame
2. For each pixel, calculate Laplacian (edge strength):
   ```
   L = 4*center - (top + bottom + left + right)
   ```
3. Calculate variance of Laplacian values
4. Low variance → blurry (edges are weak)
5. Threshold: variance < 100 → motion blur detected

### Glare Detection

1. Scan entire frame
2. Count pixels with brightness > 240
3. Calculate ratio: glare_pixels / total_pixels
4. Threshold: ratio > 0.05 (5%) → glare detected

### Shadow Detection

1. Scan entire frame
2. Identify dark pixels (brightness < 40)
3. For each dark pixel, measure contrast with neighbors
4. High contrast + many dark pixels → harsh shadows
5. Thresholds:
   - > 10% dark pixels
   - Average contrast > 50

## Best Practices for Users

### Optimal Lighting Setup

✅ **Do:**
- Use natural daylight (overcast is best)
- Use 4000-6000K LED lights (neutral white)
- Position lights at 45° angles (avoid direct overhead)
- Use diffusers to soften light
- Aim for even lighting across artwork

❌ **Avoid:**
- Direct sunlight (causes glare and harsh shadows)
- Incandescent bulbs (too warm, yellow cast)
- Fluorescent tubes (flicker, uneven color)
- Mixed light sources (creates color inconsistency)
- Single-point lighting (causes dramatic shadows)

### Camera Technique

✅ **Do:**
- Hold camera steady (use tripod or brace against wall)
- Position artwork flat and parallel to camera
- Frame artwork in center of screen
- Wait for quality score to reach 80%+
- Capture multiple shots for backup

❌ **Avoid:**
- Shooting through glass or plastic
- Shooting at extreme angles
- Moving while capturing
- Rushing the shot
- Ignoring quality warnings

## Future Enhancements

### Planned Features

1. **Distance Guidance**
   - "Too close" / "Too far" detection
   - Optimal distance calculation based on artwork size

2. **Angle Detection**
   - Perspective distortion analysis
   - "Rotate camera clockwise/counterclockwise"

3. **Focus Quality**
   - Sharpness analysis
   - "Out of focus" warnings

4. **HDR Recommendation**
   - High dynamic range scenes
   - "Use HDR mode" suggestion

5. **AI Enhancement Preview**
   - Show predicted enhancement results
   - Before/after comparison

6. **Learning Mode**
   - Tutorial overlays
   - Progressive disclosure of features
   - Tips based on common mistakes

### Technical Improvements

- **GPU acceleration** for real-time processing at 30 FPS
- **Machine learning models** for more accurate quality prediction
- **Calibrated color profiles** for professional color accuracy
- **Historical analysis** to track improvement over time
- **Smart presets** based on artwork type (painting/drawing/sculpture)

## Troubleshooting

### "Too dark" persists even in bright room
- Check if camera is in auto-exposure mode
- Clean camera lens
- Increase ambient lighting
- Move closer to light source
- Tap screen to adjust exposure point

### "Glare detected" won't go away
- Adjust lighting angle (move lights to sides)
- Use diffuser or bounce light off ceiling/wall
- Reduce light intensity
- Check for reflective artwork surface (varnish, glass)
- Try polarizing filter (advanced)

### "Motion blur" warning
- Hold camera with both hands
- Brace against wall or furniture
- Use burst mode (capture multiple frames)
- Increase lighting (allows faster shutter speed)
- Use tripod or phone stand

### Color temperature always outside range
- Check room lighting type (replace bulbs if needed)
- Close curtains to avoid mixed daylight + artificial light
- Use dedicated photo lighting (4000-6000K)
- Shoot during cloudy day for natural neutral light

## Resources

- [White Balance Guide](https://en.wikipedia.org/wiki/Color_temperature)
- [Histogram Interpretation](https://photographylife.com/understanding-histograms-in-photography)
- [Laplacian Blur Detection](https://www.pyimagesearch.com/2015/09/07/blur-detection-with-opencv/)
- [Professional Art Photography Tips](https://www.artworkarchive.com/blog/how-to-photograph-your-artwork)

## Credits

Developed for **digitize.art** by Gizmo Agent
Algorithm implementations inspired by OpenCV and computer vision research

---

**Version:** 1.0.0  
**Last Updated:** February 28, 2026  
**Status:** Production-ready ✅
