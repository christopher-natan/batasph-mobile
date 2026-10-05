# BatasPH Google Play listing assets

The items requested in `assets.txt` are ready for the main Play Store listing:

| Play Console field | File or action |
| --- | --- |
| App name, short description, full description | Copy from `listing-copy.md` |
| App icon | Upload `app-icon-512.png` (512 × 512, 32-bit RGBA PNG) |
| Feature graphic | Upload `feature-graphic.png` (1024 × 500, opaque RGB PNG) |
| Phone screenshots | Upload the four numbered images in `phone/` |
| Preview video | Optional for apps; leave blank unless you publish an actual preview video on YouTube |

The editable feature-graphic layout is `feature-graphic.html`. The Play-upload icon is an RGBA copy of `assets/branding/batasph_play_store_512.png`; the visual design is unchanged. Google's [preview-asset specifications](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-GB) currently specify a 512px RGBA icon, a 1024 × 500 opaque feature graphic, and optional video for apps.

## Phone screenshots

Upload the numbered PNGs in `phone/` in order. Each is a 1080 × 1920, opaque RGB PNG. The screenshots use real UI captured from the connected Android device on 2026-09-21; the status and navigation bars were cropped before the branded framing was added. The editable layout is `screenshots.html`, and the cropped source captures are in `source/`.

| File | Screen | Suggested alt text |
| --- | --- | --- |
| `phone/01-law-made-clear.png` | Home | BatasPH home screen offering plain-language answers about Philippine law. |
| `phone/02-ask-by-voice.png` | Voice landing | Voice-first screen with a large microphone to start a legal question. |
| `phone/03-talk-with-luna.png` | Live voice | Live voice conversation with Luna and visible spoken reply. |
| `phone/04-type-a-question.png` | Text chat | Text chat explaining the Data Privacy Act and showing RA 10173 as its legal basis. |

Visual reference: [Recito on Google Play](https://play.google.com/store/apps/details?id=com.vxtory.recito). The shared aesthetic is a dark editorial backdrop, large concise headlines, and prominent app UI; the colors and visuals are BatasPH-specific.

Google's [preview-asset guidance](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-GB) recommends at least four 1080 × 1920 portrait screenshots for apps and requires screenshots to reflect the actual in-app experience.

Before upload, review every screen against the final release build. The text-chat route has a known intermittent `ChatController not found` failure after ending a voice call; that release issue still needs fixing and retesting. The current AAB is debug-signed and must not be uploaded as a production release.
