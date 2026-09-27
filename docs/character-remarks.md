# Character remarks

Research checked September 27, 2026 for **Teen Titans Go!**. The game has 675
event/character variants: fifteen choices for each of five Titans across encounter,
hurt, low health, primary special, secondary, ultimate, wave victory, pizza and
knockout. Reused catchphrases mean this is not a count of unique sentences.

## Voice research

- [DC's official announcement](https://www.dc.com/blog/2013/03/13/teen-titans-reimagined-for-cartoon-network-this-spring-in-teen-titans-go)
  describes Robin's perfectionism and need to lead, Starfire's unfamiliarity with
  Earth, Raven's deadpan temperament, Beast Boy's easygoing silliness, and
  Cyborg's relaxed confidence. These guide the original lines.
- [Legendary Sandwich transcript](https://teen-titans-go.fandom.com/wiki/Legendary_Sandwich/Transcript)
  supports Robin's orders and self-importance, Starfire's formal phrasing,
  Raven's desire to be left alone, and Cyborg/Beast Boy's food banter. The short
  lines **“Titans, GO!”** (Robin) and **“Finally.”** (Raven) are retained.
- [Double Trouble transcript](https://teen-titans-go.fandom.com/wiki/Double_Trouble/Transcript)
  records Cyborg's **“Boo-yah!”**, Raven's **“Azarath Metrion Zinthos!”**,
  Beast Boy's casual slang, and Starfire's unusual word choices. The English game uses
  BOOYAH as its display spelling; zh-TW uses **「好耶！」**, as requested.
- [Teen Titans Go! vs. Teen Titans transcript](https://teentitans.fandom.com/wiki/Teen_Titans_Go%21_vs._Teen_Titans/Transcript)
  distinguishes the Go versions from their 2003 counterparts. Starfire's
  **“I am the victorious.”** is used for a wave clear. Only the Go characters'
  speech was used to guide these voices.

The transcripts are community-maintained supporting sources, not studio scripts.
Aside from those short identified catchphrases, the remarks are **original game
dialogue written to fit the characters**, not claims of verbatim episode quotes.
None of the lines are song lyrics. Taiwan translations are authored for this
game; they are not presented as quotations from the Taiwan dub. Raven's spell
uses the project's researched Taiwan rendering, documented in
[localization-zh-TW.md](localization-zh-TW.md).

The expanded banks add 540 original bilingual entries (12 per situation per
Titan), for 135 entries per character. They follow the same voice direction:
Robin focuses on plans and leadership; Cyborg on machines, music, food and
team spirit; Starfire on earnest friendship and formal alien phrasing; Raven on
deadpan understatement; Beast Boy on animal jokes, games and vegetarian snacks.
These additions are original game lines, not newly discovered episode quotes.
Cyborg’s BOOYAH variants use 好耶 consistently in Traditional Chinese.

## Behavior and display

Each fighter owns a private random stream seeded from their spawn ID/time. A
remark avoids both that situation's last variant and the last spoken text.
Speech does not consume the combat/loot RNG. Seeing a nearby visible enemy
triggers once per wave; denied encounter lines can wait for a free speech slot.
Low-health warnings latch until health recovers above 40%. A fatal blow uses a
knockout reaction. Successful power activation, pizza collection and wave clear
have their own banks; rejected powers do not speak.

Lines last roughly 2.4–3.3 seconds, with longer cooldowns for encounters and
damage. Urgent health/knockout reactions can replace lower-priority chatter.
Healing replaces an outdated low-health warning, and a wave clear replaces an
encounter line if the fight ended quickly.
At most two heroes speak at once. Text follows its fighter, remains upright
when the fighter faces left, wraps in English and Traditional Chinese, stays
below the HUD and within the screen, and shifts to avoid the other bubble.
When a high jump leaves no overhead space, the bubble moves beside its speaker.
Pause freezes the speech timers. Removed fighters and a return to the title
discard the bubbles.

`remarks_catalog.luau` pairs English and zh-TW text. `localization.luau` imports
those translations; `tools/build_tc_font.py` includes the catalog when building
the Noto Sans TC web-font subset. `remarks_test.luau` covers state transitions,
priorities, variation, pause, co-op limits and both language layouts; the existing
localization test checks every added Chinese glyph.
