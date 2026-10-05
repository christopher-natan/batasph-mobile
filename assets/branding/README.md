# BatasPH — 03 / A clearer balance

The selected identity combines balanced scales, an open law book, and a small amber sun. Forest green and warm ivory match the call-screen design. The wordmark uses Poppins, with **Batas** bold and **PH** regular.

## Production assets

- `batasph_balance_mark_master.png`: original transparent green emblem.
- `batasph_balance_icon_master.png`: original ivory emblem on forest green.
- `batasph_logo_mark_1024.png`: transparent 1024 px mark.
- `batasph_app_icon_1024.png`: opaque 1024 px square icon.
- `batasph_play_store_512.png`: 512 px store icon; also in `docs/play-store/app-icon-512.png`.
- `assets/images/logo.png`: runtime mark used by `BrandLogoComponent` on home and splash.

The previous public asset filenames remain available with the selected artwork. Masters are raster artwork, not editable vectors. The light and inverse masters are separately generated treatments of the same concept.

## Colors

- UI forest: `#1F4D3F`
- Launcher forest: `#224F44` (sampled from the generated opaque master to match its edges)
- Ivory: `#F5F1EA`
- Amber sun: artwork accent

## Platform coverage

Android includes legacy icons, adaptive icons, Android 13 monochrome themed icons, and native splash images for light/dark modes and Android 12+. iOS includes the existing complete AppIcon catalog with no alpha channel and native launch images. Web includes standard/maskable PWA icons, favicon, and splash images. Square icon masters have no baked-in rounded corners.

Adaptive artwork is padded inside the central safe area; launcher masks are applied by the OS. See [Android adaptive icon guidance](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive) and [Google Play icon specifications](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).

## Re-export

From the repository root on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File tools/export_branding.ps1
```

The script only resizes and packages the approved masters; it does not generate new artwork. `exports.json` records every output and expected size. The Android XML and web background colors are maintained alongside these assets. Do not run an unrelated icon generator over them: it can discard adaptive padding or monochrome configuration.

Actual Flutter previews are in `docs/design-previews/00-splash.png` and `01-home.png`. The original comparison board in `docs/batasph-logo-concepts.png` is historical design exploration.
