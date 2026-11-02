# OnAir brand files

The official logo SVGs. They are the source for every icon and logo in the app,
and are not bundled into the app itself.

| File | Use |
| --- | --- |
| `onair_app_icon*.svg` | App icon: brand blue, dark, rounded |
| `onair_logo*.svg` | Mark + name (English / Arabic, colour / white) |
| `onair_mark*.svg` | Mark alone; `_small` is the cut for 32 px and below |
| `store/` | Ready-made store icons (Google Play 512, App Store 1024) |

## What uses them

- **iOS**: `AppIcon` and `AppIcon-Staging` hold light, dark and tinted
  versions (iOS 18+ switches them with the Home Screen appearance and the
  colour the user picks). The launch screen shows the white mark.
- **Android**: adaptive icon (8+), themed monochrome icon (13+, follows
  the wallpaper colours), legacy PNGs for Android 7, the Android 12+ splash
  icon, the launch screen mark and the push notification icon.
- **Flutter**: `OnAirLogo` (`lib/design_system/brand/`) draws the mark,
  the name and the lockup as vectors. Its colour follows the theme.

## Changing the logo

Replace the SVGs here, then run:

```bash
npm i --no-save @resvg/resvg-js@2.6.2 opentype.js@1.3.4 pngjs@7.0.0
node tool/brand/generate_brand_assets.cjs
flutter test --update-goldens --tags golden
```
