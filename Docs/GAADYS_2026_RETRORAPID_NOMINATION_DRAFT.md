# GAADYs 2026 RetroRapid! Nomination Draft

Draft date: 2026-06-10

This file contains the RetroRapid! GAADYs 2026 nomination draft and supporting evidence. It was split from the earlier combined draft so RetroRapid-specific wording, metrics, and sources can be maintained in the RetroRacing workspace.

## Form Questions Observed

- Was your product released before January 1, 2024?
- Does your product use an accessibility overlay?
- Full name, email address, company/organization name
- Product name and product URL
- Describe in detail where and how the team made accessibility a core technical requirement throughout ideation, design, development, testing, and/or launch.
- Describe in detail where and how the team prioritized input from persons with disabilities throughout ideation, design, development, testing, and/or launch. To what extent did the team proactively source feedback from people with disabilities on the product and allow it to influence the roadmap? If people with disabilities were involved in the actual design or development of the product, include this information.
- What challenges, if any, did you face when you included accessibility and users with disabilities during different phases of the product development process? How did you manage these?
- What specific technical or design challenges did your team face and how were these overcome? Describe how you leveraged existing or new technologies or methods to address accessibility.
- Please indicate whether your product was designed and built to meet WCAG. If so, which version and level? If other accessibility guidelines or standards were adopted, for example gaming or kiosk accessibility, describe this as well.
- Approximately how many end users has the product reached? Describe any online/offline coverage or recognition received for accessibility efforts.
- Additional accessibility assurance information.
- Certification.

## RetroRapid

### Eligibility

Was your product released before January 1, 2024?

No. RetroRapid first shipped publicly in 2026.

Does your product use an accessibility overlay?

No. RetroRapid is a native Apple-platform game. Accessibility support is built into gameplay, settings, controls, audio/haptics, VoiceOver behavior, Dynamic Type layout, and platform-specific input handling.

### Contact And Product

Full name: Daniel Devesa Derksen-Staats

Email: hello@accessibilityUpTo11.com

Company/Organization Name: Accessibility Up to 11!

Product Name: RetroRapid!

Product URL: https://accessibilityupto11.com/apps/retrorapid/

### Product Description

RetroRapid! is a retro-inspired arcade racing game for iPhone, iPad, Apple Watch, and Mac. Players steer between three lanes, avoid traffic, react to speed changes, and chase high scores in short, replayable sessions inspired by classic handheld racing games.

The game is designed so the same arcade loop can be played through different senses and input methods. It supports visual play, VoiceOver, audio lane cues, haptics, adjustable speed, Direct Touch, Voice Control-friendly labels, Dynamic Type-aware screens, simplified/larger visuals, Apple Watch Digital Crown input, keyboard input, and game controller support. The goal is not to provide a separate accessible version of the game, but to make the main game playable and enjoyable for more people.

### Accessibility As A Core Requirement

RetroRapid! is a retro-inspired arcade racing game, so accessibility had to be part of the game's core design rather than something added around the menus. From the beginning, the central question was: can a fast, visual, three-lane collision game remain a real arcade game while also being playable through VoiceOver, audio cues, haptics, adaptable visuals, and different input methods?

That question shaped the game model itself. The player needs to understand their lane, nearby traffic, speed changes, score, lives, collisions, and available actions. RetroRapid therefore treats gameplay state as information that must be available in multiple ways: visually, through sound, through haptics, through semantic VoiceOver information, and through configurable controls.

Accessibility was part of the definition of done for gameplay, settings, onboarding, and platform behavior. Features were not considered complete if they only worked visually. VoiceOver behavior, Direct Touch, Voice Control-friendly labels, Dynamic Type-aware screens, Reduce Motion, high-contrast and simplified visual options, larger car visuals, sound and haptic feedback, Apple Watch Digital Crown support, keyboard input, game controller support, and platform-specific layout were all treated as product requirements.

Accessibility also shaped the game's defaults. When VoiceOver is running, RetroRapid can use a slower starting pace, enable lane audio cues, and make sound feedback more prominent so players have enough information to learn the game. These are defaults rather than a separate "accessible mode": users can still adjust speed, cues, visuals, and feedback to match their own preferences.

Testing included live gameplay, not just menus: whether a player could understand the three-lane model, move between lanes, detect danger, respond to speed changes, recover after collisions, access settings, and restart using different combinations of VoiceOver, audio, haptics, touch, keyboard, controller, and platform-specific input.

### Input From People With Disabilities

RetroRapid! was developed in public with accessibility communities rather than only through private internal testing. I posted an early TestFlight build on AppleVis, a community centered on blind and low-vision Apple users, and explicitly asked for feedback on audio cues, pacing, Direct Touch, and anything confusing, fatiguing, or frustrating.

That feedback directly influenced shipped features and the roadmap. Early testers found the game hard to understand at first, so I added and improved tutorial content explaining the three-lane model, movement, safe-lane sounds, and audio cues. Feedback that the game could feel too fast shaped slower and more forgiving defaults, especially for VoiceOver users.

Players also gave detailed feedback about audio, haptics, and input. Some found spoken announcements useful; others found speech distracting during fast gameplay. Some preferred audio lane cues; others wanted haptic alternatives. That led to more configurable feedback, including haptic warnings, options around lane-change feedback, the ability to disable VoiceOver announcements during gameplay, and a broader approach where sound, haptics, and announcements can be tuned instead of forced into one pattern.

The AppleVis thread also surfaced platform and assistive-technology needs: Apple Watch, Mac, controller support, Direct Touch, and Braille keyboard or Braille display play. That feedback influenced Watch and Mac refinements, controller support, Direct Touch fixes, and a setting to disable Direct Touch for users whose setup works better without it.

Because I am a solo developer, I did not have a formal research team or paid research panel. Instead, I used an open feedback loop: share builds, ask specific accessibility questions, listen to lived experience, reproduce issues, ship improvements, and keep larger suggestions on the roadmap.

### Inclusion Challenges

The main challenge was building a meaningful accessibility feedback process as a solo developer without the resources of a larger game studio or formal research team. I relied on public community feedback, TestFlight builds, App Store reviews, direct follow-up, and iterative releases.

Another challenge was that accessibility feedback for a real-time game can reveal genuinely different preferences. Some players benefit from VoiceOver announcements; others find speech distracting once the game becomes fast. Some prefer audio lane cues; others asked for haptic alternatives. Some VoiceOver users benefit from Direct Touch; users with Braille keyboards or Braille displays may need a way to play without it.

I managed this by avoiding a single forced "accessible mode." RetroRapid uses accessible defaults, configurable options, and platform-aware behavior. VoiceOver users can get a more forgiving starting setup, but players can still change speed, audio cues, haptics, announcements, Direct Touch behavior, and visual presentation.

There was also a prioritization challenge. Public feedback produced many valid ideas: better tutorials, haptic-only feedback, different lane sounds, self-voicing, more practice material, Watch improvements, Mac availability, controller support, Direct Touch fixes, Braille display considerations, and new gameplay ideas. I prioritized issues that prevented people from playing, understanding the game, or using their assistive technology first, while keeping broader gameplay expansions on the roadmap.

### Technical Or Design Challenges

The hardest technical and design challenge was translating a visual, real-time, three-lane collision game into multimodal information without making it noisy, slow, or no longer fun. The player must know where they are, where danger is, when speed changes, and whether input worked. That information cannot rely only on vision.

RetroRapid addresses this by layering feedback. Visually, it supports larger car visuals, simplified road/grid presentation, Dynamic Type-aware screens, Dark Mode, and high-contrast-friendly design. Audibly, it uses retro-style sound effects, lane cues, movement feedback, speed-warning sounds, and optional VoiceOver announcements. Haptics can communicate movement, warnings, and state changes where supported. Semantically, VoiceOver labels and values expose meaningful UI and game state rather than just describing decorative sprites.

A second challenge was VoiceOver interaction during live gameplay. Standard VoiceOver navigation is not designed for fast arcade movement, but a fully custom interaction can make the game harder to inspect. RetroRapid uses Direct Touch for active gameplay so players can move quickly, while intentional pause states can expose the grid for exploration with row and lane descriptions.

A third challenge was cross-platform input. RetroRapid runs across iPhone, iPad, Apple Watch, and Mac, each with different expectations: touch and Direct Touch, Digital Crown, keyboard/controller-style input, focus behavior, haptic availability, and layout constraints. I managed this through native Apple-platform APIs, platform-specific input paths, and shared game logic so the accessibility model remains consistent even when interaction methods change.

### Standards And Guidelines

RetroRapid! was designed with WCAG 2.2 AA as an accessibility reference and practical target, although it has not been through a formal external WCAG audit. I used the POUR principles throughout development: making gameplay information perceivable through visuals, sound, haptics, and VoiceOver; making controls operable through multiple input methods; making the game understandable through onboarding, consistent lane cues, predictable settings, and plain inclusive language; and making the implementation robust with native Apple accessibility APIs and platform conventions.

Because RetroRapid! is a game, I also applied game accessibility principles beyond a checklist interpretation of WCAG. The game provides multiple ways to perceive state, configurable feedback, adjustable speed, reduced-motion behavior, non-color-only communication, accessible menus, support for assistive technologies, and multiple input paths including touch, Direct Touch, Digital Crown, keyboard, and controller support.

I also avoided framing speed settings as ability labels such as "easy" or "hard." Instead, RetroRapid! uses speed names that describe pace and feel, so players can choose the experience that suits them without the interface implying that one setting is more legitimate or that slower play is lesser play.

RetroRapid! was also built around Apple's accessibility APIs, Human Interface Guidelines, and native platform behavior for VoiceOver, Voice Control, Dynamic Type, Reduce Motion, haptics, Game Center, Apple Watch, Mac, and iPhone/iPad input.

### Reach, Coverage, Recognition

As of June 10, 2026, RetroRapid! has reached approximately 3,329 downloads.

The app has also received strong early user feedback. The App Store review export currently includes 14 reviews, all rated 5 stars. Several reviews independently mention the qualities this nomination is about: accessibility, simple controls, Apple Watch support, and the fact that the game still feels fun and replayable. Examples include reviewers calling it a "nice accessible game" they can "pick up and play," saying it "also works with the Apple Watch," describing it as "accessible and entertaining," and noting that "the simplicity and accessibility is unmatched."

RetroRapid! was featured by Create with Swift as an Indie App of the Week. Their coverage highlighted the retro gameplay and noted that "what truly stands out is its accessibility."

RetroRapid! was also discussed on Double Tap in the episode "Weekend: Building Accessible Games and Reading Tools with Dani Devesa Derksen-Staats." The episode described RetroRapid as an accessible retro racing game across iPhone, iPad, Mac, and Apple Watch, and highlighted multiple input methods, audio cues that map musical notes to lanes, haptic feedback, Direct Touch controls, and the role of AppleVis community feedback in refining the experience.

The app also has a public AppleVis development and feedback thread, where blind and low-vision users discussed TestFlight builds, VoiceOver play, audio cues, haptics, Direct Touch, Braille keyboard/display considerations, Watch support, Mac support, pacing, and controller input.

### Additional Accessibility Assurance

One additional effort worth highlighting is that RetroRapid!'s accessibility was tested against the live gameplay loop, not only against menus or static screens. I treated "can someone actually play, understand, recover, restart, and improve?" as the accessibility test.

I also treated accessibility as part of public accountability. RetroRapid!'s App Store listing declares VoiceOver support through Apple's Accessibility Nutrition Labels, which is a meaningful commitment for a fast-paced arcade game. The product page and App Store presence describe accessibility features in practical terms, and the AppleVis thread remained open for users to report confusing behavior, request changes, and validate improvements.

Finally, my broader professional work is focused on Apple-platform accessibility. I wrote Developing Accessible iOS Apps, publish iOS accessibility guidance through Accessibility Up to 11 and #365DaysIOSAccessibility, and regularly speak about accessibility. That background shaped RetroRapid!, but I also tried not to rely only on my own assumptions: public feedback from blind and low-vision players directly influenced the game's accessibility model, defaults, settings, and roadmap.

## Evidence Appendix

### GAAD And Form

- GAADYs How to Enter: https://gaad.foundation/what-we-do/gaadys/how-to-enter
- Live nomination form linked from GAAD page: https://forms.cloud.microsoft/pages/responsepage.aspx?id=R4VkjNDneEi3FTjKW0Kd1BY0MC1vBSlFhef12Y6R-odUQUs5NzhUSFNCQ0xDSERHNUJOT0hZOVozNS4u&route=shorturl

### Product Pages And Store Listings

- RetroRapid product page: https://accessibilityupto11.com/apps/retrorapid/
- RetroRapid App Store listing: https://apps.apple.com/app/retrorapid/id6758641625
- About Daniel Devesa Derksen-Staats: https://accessibilityupto11.com/about/

### AppleVis Threads

- RetroRapid feedback thread: https://www.applevis.com/forum/ios-ipados-gaming/working-developing-accessible-retro-racing-game-feedback-welcome
- RetroRapid AppleVis thread includes public requests for feedback on audio cues, pacing, Direct Touch, confusion/fatigue, and later discussion of tutorial improvements, haptics, Dynamic Type, paused-grid exploration, macOS/Watch support, Direct Touch fixes, and a Direct Touch opt-out.

### RetroRapid Public Feedback Examples

- AppleVis thread contains feedback on gameplay understandability, VoiceOver, Direct Touch, Braille/display interaction, audio/haptic cues, Apple Watch, pace/difficulty, and controller/keyboard input.
- Product page coverage quote from Create with Swift Weekly Newsletter #96: https://accessibilityupto11.com/apps/retrorapid/
- Double Tap episode "Weekend: Building Accessible Games and Reading Tools with Dani Devesa Derksen-Staats": https://doubletaponair.com/weekend-building-accessible-games-and-reading-tools-with-dani-devesa-derksen-staats-2/
- App Store review export, 2026-06-10: /Users/dadederk/Desktop/com.accessibilityUpTo11.RetroRacing-reviews-2026-06-10.csv. Current export includes 14 reviews, all 5-star, with comments mentioning accessibility, Apple Watch support, simple controls, and replayable arcade fun.
- App Store Connect downloads for RetroRapid as of 2026-06-10: 3,329.

## Claim Safety Notes

- Do not identify individual commenters as disabled unless they explicitly consent or the submission does not name them. The safer formulation is "feedback from public accessibility communities, VoiceOver users, and assistive-technology users."
- Do not claim formal WCAG conformance unless an audit exists. Use "WCAG-informed/native Apple accessibility implementation" language.
- Do not claim formal user research if the process was public beta/community feedback. "Public accessibility feedback loop" is accurate and strong.
- Verify App Store Connect/user metrics shortly before submission.

