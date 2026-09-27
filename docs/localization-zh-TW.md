# 繁體中文（台灣）

Research checked on 2026-09-27. This localization follows the Taiwan television
characters and vocabulary. It does not claim that this fan game's original
stage names and ability names are official episode terminology.

## Terminology and sources

| English | In-game zh-TW | Basis |
|---|---|---|
| Teen Titans | 少年悍將 | Taiwan programme title |
| Robin / Cyborg | 羅賓／鋼骨 | Apple TV Taiwan programme description |
| Starfire / Raven / Beast Boy | 俏嬌娃／酷姬／人皮獸 | Apple TV Taiwan description and Taiwan dubbing cast record |
| Jump City | 雀躍城 | Netflix Taiwan programme description |
| Slade | 史萊德 | Taiwan film coverage and television character lists |
| Jinx / Mammoth / H.I.V.E. | 金兒／瑪莫／海夫 | Taiwan dubbing record and television character lists |
| Cinderblock | 石頭怪 | Contemporary Taiwan viewer terminology list; no current distributor glossary located |
| Birdarang | 鳥飛鏢 | Traditional Chinese episode description; 鳥飛標 is also used in cast lists |
| Azarath Metrion Zinthos | 天地萬物聽我命令 | Chinese-dub incantation documented in the television character entry |

- [Apple TV Taiwan — 少年悍將Go](https://tv.apple.com/tw/show/少年悍將go/umc.cmc.7k3e6qd9y25s4luk7n1ghvsvw): primary distributor source for all five hero names.
- [Netflix Taiwan — 少年悍將 GO！](https://www.netflix.com/tw/title/80103408): primary source for 雀躍城. This listing uses 星火; this game consistently uses the Taiwan TV cast name **俏嬌娃**, supported by Apple TV and the dubbing record.
- [台灣配音維基 — 少年悍將](https://vocustaiwan.fandom.com/zh-tw/wiki/少年悍將): community-maintained Taiwan cast record, including 俏嬌娃、酷姬、人皮獸、金兒.
- [少年悍將GO！ television character list](https://zh.wikipedia.org/wiki/少年悍將GO！): secondary source for 金兒、瑪莫、海夫 and 史萊德. The 2005 viewer list below spells Mammoth 馬莫; the current GO list uses 瑪莫, selected here.
- [PTT CartoonNet — 少年悍將人物中英對照, 2005](https://www.ptt.cc/bbs/CartoonNet/M.1119616957.A.70D.html): historical viewer record for 石頭怪 and 史萊德; the author explicitly notes uncertainty, so this is supporting evidence, not an official glossary.
- [Vogue Taiwan — 電影少年悍將GO！](https://www.vogue.com.tw/movie/content-40209): corroborates 史萊德 in Taiwan release coverage.
- [Now TV — 少年悍將GO! 第9季](https://nowplayer.now.com/ondemand/detail?id=S202504150190768&type=series): traditional-Chinese distributor synopsis uses 鳥飛鏢; Hong Kong service, used only as corroboration.
- [少年悍將 television character entry](https://zh.wikipedia.org/wiki/少年悍將_(動畫)): secondary source for the dubbed incantation 天地萬物聽我命令.

Other stage subtitles, robot classes and moves are project-authored translations:
鋼鐵碼頭、咒術工廠、旋風棍、震地重擊、暗影束縛, etc. UI vocabulary uses
台灣、玩家、控制器、鍵盤、關卡、生命、能量、返回、暫停、必殺技、披薩.
Physical button labels (START, BACK, X, A, B, Y, RT, LB) and P1–P4 remain
recognizable in either language. Cyborg’s catchphrase BOOYAH is rendered as
「好耶！」in Traditional Chinese.

## Font and rendering

The Chinese face is **Noto Sans TC Bold (700)** from the
[Google Fonts web font family](https://fonts.google.com/noto/specimen/Noto+Sans+TC).
The actual Google Fonts WOFF2 subset is checked in at
`assets/fonts/noto-sans-tc-700.woff2`, with its SIL OFL license and source URL/SHA-256
in the adjacent files. No system font or network request is required to play.

Rive's script Renderer has no text/font drawing method, so
`tools/build_tc_font.py` converts that web font's outlines into `tc_glyphs.luau`.
Quadratics are converted exactly to cubics to avoid missing strokes in the local
Rive renderer. Paths are cached on first use. Chinese uses filled upright glyphs;
the existing English comic lettering and character emblems retain their style.

To rebuild with the checked-in font: `python3 tools/build_tc_font.py`.
When adding Chinese characters, run `python3 tools/build_tc_font.py --download`
to refresh the subset first. The authoring script requires `fonttools[woff]`.
Translation edits must also pass `rive . --verify`, `rive inspect . --summary`,
`rive . --test`, and native screenshot review. The coverage test rejects missing
Chinese glyphs and mismatched interpolation placeholders.

## Language control

The title screen's top-right selector offers ENGLISH and 繁中（台灣）.
Click either choice, press Tab, or press controller LB to switch. Holding a key
or shoulder button switches only once. Pointer input follows the same scaling
and letterboxing as the game. Changes are allowed only on the title screen and
remain selected through character selection, play, pause, continue, results,
and returning to the title. In the browser, the initial choice follows
`navigator.languages`: `zh-TW`, `zh-Hant`, `zh-HK`, and `zh-MO` use 繁中（台灣）;
other languages fall back to English. An explicit choice is stored as `en` or
`zh-TW` under `ttgo.language.v1` in localStorage and overrides browser language
on later visits. Automatic detection alone does not write a preference. Other
tabs receive preference changes through the browser storage event. The native
preview defaults to English and can be shown in Chinese with
`rive . --data=browserLanguage=zh-TW --advance=1`.
