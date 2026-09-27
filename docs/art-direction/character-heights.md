# Teen Titans Go! relative heights

Visual research checked September 27, 2026. This project follows the 2013
**Teen Titans Go!** designs. Feet/inches reported for the comics or the 2003
series are not a reliable scale chart for these drawings.

## References inspected

- [DC's official series artwork](https://www.dc.com/tv/teen-titans-go-2013-present)
  establishes the intended adaptation, but its airborne action poses cannot
  provide a common standing baseline.
- [The early character lineup reproduced by ReadMe!Girls!](https://ppgcom.blog12.fc2.com/blog-entry-5488.html)
  ([lineup image](https://blog-imgs-51-origin.fc2.com/p/p/g/ppgcom/TTGo_ca_01.jpg))
  shows all five standing. It is a photographed presentation, not a published
  numerical height chart, so camera perspective limits exact measurement.
- [An animation still showing the team outside Warner Bros.](https://netflixjunkie-media.b-cdn.net/media/image/image_1757317257845.jpeg)
  independently supports the same size relationships: Cyborg substantially
  taller than Robin, Starfire near Robin's body height with a visible hover gap,
  Raven smaller, and Beast Boy shortest. The still is reproduced in
  [this article](https://www.netflixjunkie.com/hollywood-news-warner-bros-faces-backlash-as-teen-titans-go-beast-boy-voice-actor-claims-he-was-fired-over-parkinsons/);
  only the picture is used as an art reference.
- [The blue-background action lineup](https://tvseriesfinale.com/tv-show/teen-titans-go-50-cent-goes-sons-birthday-party/)
  was also checked, but foreground placement, floating and crouching make it
  unsuitable for measuring standing heights.

## Applied visual targets

Approximate body-height ratios estimated from the standing references, with
Robin as 1.00 and the floating gap excluded:

| Character | Approximate reference ratio | Uniform drawing scale |
| --- | ---: | ---: |
| Robin | 1.00 | 1.00 |
| Cyborg | 1.25–1.30 | 1.17 |
| Starfire | about 1.00 | 0.95 |
| Raven | about 0.80 | 0.86 |
| Beast Boy | about 0.73 | 0.84 |

These are visual adaptation targets, **not canonical physical measurements**.
The drawing-scale column compensates for the existing art's different local
dimensions; it is not itself a height ratio. Hair, hood, stance, breathing and
hovering change the visible top of the silhouette during animation.

`heroes.modelScale` is shared by the title lineup, selection cards and fighter
spawning. Both axes use the same factor, preserving each menu model's existing
head/torso/limb proportions. Selection uses one common display zoom with enough
headroom for Cyborg, rather than fitting every character to equal height.

The fighter's resulting scale already drives rendering, dash echoes, running
cadence, projectile/beam attachments, vertical projectile collision bounds and
player markers. The local `HEIGHTS` and attachment coordinates stay in authored
drawing units. HUD face portraits retain their independent icon framing.
