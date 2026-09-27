# Gameplay fighting stance

Research: Capcom's 2017 GDC presentation, [Art Direction of Street Fighter V](https://media.gdcvault.com/gdc2017/Presentations/Kamei_Art%20Direction%20Street%20Fighter.pdf), particularly slides 18–29 (readable silhouettes), 43–51 (battle-camera-specific animation comparisons), and 52 (reviewing animation in the battle camera).

The presentation distinguishes ordinary animation from poses adjusted for the battle camera. The comparison on slides 43–44 shows how a pose can be opened toward the battle view so the chest and limbs remain readable.

Our application of that principle is an art-direction choice: a three-quarter character drawing, rather than a strict 90-degree profile. This game uses scripted 2D vector artwork, so there is no 3D camera to rotate. Gameplay heads show both eyes with a smaller far eye and gaze toward the opponent. Wider chest planes, separated shoulders, an offset costume seam, and staggered feet reveal depth. Both arms retain the corrected elbow bend. The entire fighter mirrors once for left-facing play.

Title and selection screens retain their frontal artwork. Combat input, lane movement, ranges and facing logic stay the same. Projectile attachments follow the new shoulder coordinates; Cyborg's ultimate beam uses the updated cannon origin.

## Character model correction

Visual references inspected in September 2026:

- [DC's official Teen Titans Go! series page](https://www.dc.com/tv/teen-titans-go-2013-present), including its ensemble action artwork.
- [The show's team-lineup frame reproduced by TV Series Finale](https://tvseriesfinale.com/tv-show/teen-titans-go-50-cent-goes-sons-birthday-party/). This frame was inspected directly for costume silhouettes, facial landmarks and limb proportions.

Corrections derived from those images: Robin has fewer broad hair peaks, a central widow's peak and balanced mask eyes; Cyborg has a flatter crown, strong jaw, black upper limbs and broad mechanical forearms; Starfire has two rounded bangs, evenly proportioned eyes and long silver gauntlets; Raven's hood casts the characteristic black shadow around her eyes; Beast Boy has a swept fringe and long pointed ears. Gameplay fists, glove cuffs and boots are oriented with the limbs rather than rendered as upright circles. Hair and cape roots use the torso lean transform so they stay attached during attacks.

These are hand-authored vector adaptations. Online reference imagery is not bundled in the game. Title/select drawings retain their existing frontal view.
