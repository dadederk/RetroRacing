# App Store creative assets

Local, upload-sized concepts for the iOS App Store product page. **None has been uploaded, previewed in App Store Connect, or approved.** The generated localized set is prepared for review and Helm validation, not yet selected for submission.

| File | Placement | Pixels | Status |
|---|---|---:|---|
| `product-page-header-coastal.png` | Product page header | 3840 × 1646 | Provisional lead. The approved wordmark survives the center-crop check recorded in `../product-page-header-concepts/README.md`. |
| `localizations/<locale>/search-results.png` | Search results | 1920 × 1280 | Generated upload candidate for all 20 storefront locales. Uses canonical Screenshot Studio opening copy and each locale's Game Center friend-marker capture. The minimum accepted 3:2 resolution avoids App Store Connect processing failures seen with the otherwise-valid 3840 × 2560 source. |
| `helm-creative-assets.json` | Helm upload manifest | — | One header and one search-results placement per locale, including current localization review status. The same language-neutral header file is intentionally reused. |
| `review/search-results-localizations-contact.jpg` | Review sheet | 1920 × 1160 | All localized search images at search-result scale for comparative visual review. |
| `product-page-header-lcd.png` | Product page header | 3840 × 1646 | Existing lead concept, retained for comparison. Its wordmark and foreground car disappear in that center crop, so use only if App Store Connect's actual preview is acceptable. |
| `search-results-controller-v2-en-US.png` | Search results | 3840 × 2560 | English lead candidate: a larger wordmark, the localized slide-1 hook without supporting copy, an evenly inset phone with Dynamic Island, and the real Game Center friend-marker capture on the right. Reads clearly at 480 × 320. |
| `search-results-controller-v1-en-US.png` | Search results | 3840 × 2560 | Earlier controller candidate with smaller branding, supporting copy, and a larger phone. Retained for comparison. |
| `search-results-xabia-gameplay-v4-en-US.png` | Search results | 3840 × 2560 | Current English review candidate: one racer on the left, the existing “Race through endless traffic” copy, and a framed real gameplay capture on the right. The Xàbia skyline remains visible. Reads clearly at 480 × 320. |
| `search-results-xabia-v2.png` | Search results | 3840 × 2560 | Revised Xàbia concept for review: photo-informed Montgó, port, and Cap de Sant Antoni in the existing pixel-art racing style. Brand mark and car remain legible at 480 × 320. No copy to localize. |
| `search-results-xabia-en-US.png` | Search results | 3840 × 2560 | Rejected first Xàbia attempt. The geography and white sail-like Loreto building are inaccurate, and its phone overlay breaks the visual style. Do not submit. |
| `search-results-pixel-en-US.png` | Search results | 3840 × 2560 | New English design candidate: a short racing headline, Miami-style pixel art, and a real LCD gameplay capture in a phone frame. Reads clearly at 480 × 320. |
| `search-results-playfield.png` | Search results | 3840 × 2560 | Exploratory direct gameplay layout. It reads like an expanded screenshot and lacks a clear benefit message. |
| `search-results-gameplay.png` | Search results | 3840 × 2560 | Exploratory wordmark and gameplay layout. The large empty field does not explain the game. |
| `search-results-lcd.png` | Search results | 3840 × 2560 | Earlier illustrated console draft. It resembles the header and does not show a direct gameplay capture. |

All files are opaque RGB PNG images. The two headers are exact copies of the existing files in `../product-page-header-concepts/`. The English search candidates use the approved `../product-page-header-concepts/sources/retrorapid-title-cartridge.png` wordmark. The controller v2 lead uses the English screenshot title “Race Through Endless Traffic” and the Game Center friend-marker capture from `../RetroRapid.screenshotstudio/iphone/images/en-US_5.jpeg`; v1 and the older phone concepts use `en-US_0.jpeg`. Check the chosen capture against the selected release build before submission. Both controller candidates share the text-free generated source `sources/search-results-controller-background-v1.png`; its controller is an original generic design, not a replica of branded hardware. The text-free `sources/search-results-pixel-background.png` was created from the earlier Miami social/event style and the 2.0 event card. The first `sources/search-results-xabia-background.png` is rejected with its composite.

The revised `sources/search-results-xabia-v2-background.png` uses the [Cap and port view](https://commons.wikimedia.org/wiki/File:Vista_cap_al_port_i_el_cap_de_sant_Antoni_des_del_Rebald%C3%AD,_X%C3%A0bia.JPG), [Montgó view](https://commons.wikimedia.org/wiki/File:Vista_cap_al_segon_Muntanyar,_X%C3%A0bia_i_el_Montg%C3%B3.JPG), and [old-town view](https://commons.wikimedia.org/wiki/File:Vista_del_nucli_antic_de_X%C3%A0bia_des_del_riu.jpg) as geographic references, with the existing 2.0 event card as its visual style reference. It is a stylized composite of real landmarks, not an exact viewpoint. The text-free `sources/search-results-xabia-one-car-background.png` is a later edit of the same visual direction, keeping one car in the left foreground and clearing room for the gameplay screen. Check the gameplay capture against the selected release build and the complete asset against the selected header and Apple's App Store Connect preview before submission.

The older gameplay-led search concepts use the same capture, while `search-results-lcd.png` is an illustrated console draft with its text-free source in `sources/search-results-lcd-background.png`. The localized controller set is generated by `./retrorapid assets creative`; do not edit its rendered text or upload manifest by hand.

Apple's current [creative asset specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/creative-assets-specifications) accept 3840 × 1646 PNG for a 21:9 header and 1920–3840 × 1280–2560 PNG or JPEG for a 3:2 search image. Apple's [asset best practices](https://developer.apple.com/app-store/asset-best-practices/) call for a focused header and a search image that makes the app's purpose clear at a glance. Confirm the live requirements and the actual product-page/search previews at submission time.

## Search creative direction

- Apple's example pairs a brief purpose statement with an in-app view over cohesive brand artwork. Its search guidance asks for an obvious purpose and firsthand experience, while allowing creative assets to go beyond screenshots.
- Xarra's [`search-results-creative`](../../../Xarra/AppStore/search-results-creative/README.md) follows that pattern with a localized benefit statement, a real app screen, and artwork shared with its header.
- `search-results-controller-v2-en-US.png` is the lead for that structure. It keeps the product-page header's saturated arcade palette while using a dark left column for the approved screenshot hook, then gives the smaller friend-marker gameplay capture equal top, right, and bottom padding. Produce localized variants only after this composition and the selected-build capture are approved.
- `search-results-xabia-v2.png` places the familiar racer and title over a photo-informed Xàbia scene. It has no additional language-specific copy. Confirm the art direction and storefront crop before selecting it; the first Xàbia attempt is rejected.
- `search-results-xabia-gameplay-v4-en-US.png` remains the strongest Xàbia composition alternate. It uses the approved wordmark, the existing English screenshot headline, and the actual app screenshot on the right.
- Keep the focal car, benefit text, and brand mark clear within possible storefront crops. Check iPhone/iPad orientations and languages in App Store Connect's preview before submission.

## Localized Helm preparation

Run `./retrorapid assets creative` to generate the complete set, then
`./retrorapid assets creative --check` to verify it. The header does not need a
translated variant because its only text is the RetroRapid! brand mark; Helm can
place the same opaque RGB PNG for each locale. Search headlines come directly
from the canonical Screenshot Studio slide-0 title, while the phone uses each
locale's slide-5 capture.

The manifest records the review status from
`../localization/review-status.json`. `NEEDS_REVIEW` output is technically ready
for dry-run validation but is not editorially approved for upload. Before a real
upload, confirm the intended App Store Connect account and app version, stage the
manifest paths through Helm's agent upload inbox, and run
`creative-images upload --dry-run` for both asset kinds in every locale.
