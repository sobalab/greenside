# Fonts

The Greenside Figma design uses two **Google Fonts** (Open Font License, free to bundle):

| Role     | Family         | Weights used                     |
|----------|----------------|----------------------------------|
| Headings | Funnel Display | Medium, SemiBold, Bold           |
| UI/body  | Funnel Sans    | Regular, Medium, SemiBold, Bold  |

## Status

Not yet bundled. `Theme.Typography` falls back to the **system font** at the matching
weight until the `.ttf` files are added here, so the app builds and runs today.

## To enable the real fonts

1. Download the families from Google Fonts:
   - https://fonts.google.com/specimen/Funnel+Display
   - https://fonts.google.com/specimen/Funnel+Sans
2. Drop these files into this folder (exact names matter — they must match
   `Theme.FontName`):
   - `FunnelDisplay-Medium.ttf`, `FunnelDisplay-SemiBold.ttf`, `FunnelDisplay-Bold.ttf`
   - `FunnelSans-Regular.ttf`, `FunnelSans-Medium.ttf`, `FunnelSans-SemiBold.ttf`, `FunnelSans-Bold.ttf`
3. Register them with the app by adding a `UIAppFonts` array to Info.plist. Because
   the project uses `GENERATE_INFOPLIST_FILE`, the simplest path is to add a custom
   `Info.plist` and set `INFOPLIST_FILE`, or add the `UIAppFonts` keys via an
   `.xcconfig`. (Note: the PostScript name inside the `.ttf` must equal the filename
   without extension for `Theme.FontName` to resolve — verify with Font Book.)

No code changes are needed once registered — `FontAvailability` detects them at runtime.
