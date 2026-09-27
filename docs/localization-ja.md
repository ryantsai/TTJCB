# Japanese localization

Choose **日本語** at the title screen. Tab and controller LB cycle English →
Traditional Chinese → Japanese → English. Browser preferences beginning with
`ja` select Japanese automatically unless the player has saved another choice.
The existing `ttgo.language.v1` preference accepts `ja` and synchronizes between
browser tabs. Progress and game controls are unchanged.

## Text coverage

- All 226 UI catalog entries: disclaimer, names, powers, menus, tutorial, HUD,
  stage objectives, world signs, hazards, equipment, boss warnings, save status,
  reset confirmation, and end screens.
- All 675 hero remarks and 96 boss remarks, stored as the third field alongside
  their English and Taiwan Chinese counterparts. Cinderblock retains nonverbal
  roars and translated sound captions.
- All eight browser messages, including loading/failure text, document title,
  canvas accessibility label, and fullscreen controls.
- Tutorial direction labels are translated. Physical key names such as START,
  SPACE, SHIFT, CTRL, and controller button letters remain recognizable legends.
  Language selector labels remain each language's own name.

Japanese dialogue is a project-authored translation, not a claim to reproduce
an official dub. Hero spellings follow the Japanese broadcaster's usage:
[Warner Bros. Discovery / Cartoon Network](https://www.discoveryjapan.jp/cartoonnetwork/ttg/)
and [Turner Japan's series announcement](https://prtimes.jp/main/html/rd/p/000000417.000030758.html).

## Fonts and rendering

Japanese uses bundled **Noto Sans JP Bold**, licensed under SIL OFL. Source URL,
character inventory, and SHA-256 are recorded in
`assets/fonts/noto-sans-jp-source.json`. The browser host loads the WOFF2 subset;
native Rive renders generated paths from `jp_glyphs.luau`. Japanese and Taiwan
Chinese glyph/run caches are distinct, preserving regional kanji forms when
switching languages. No runtime font download is required.

After adding Japanese text:

```sh
python3 tools/build_tc_font.py --locale ja --download
rive . --verify
rive inspect . --summary
rive . --test
python3 tools/check_localization.py
node --test web/*.test.mjs
```

The catalog test checks every source key, placeholder parity, and every
non-ASCII glyph. Dialogue tests check all three translations fit three lines
without dropping text. Browser tests cover detection, saved choices, reload,
cross-tab changes, and host-message parity. Renderer tests cover regional font
cache separation and menu backgrounds in all three languages.

Native visual review, without changing browser saves:

```sh
python3 tools/capture_localization.py --locale ja --screen title
python3 tools/capture_localization.py --locale ja --screen tutorial
python3 tools/capture_localization.py --locale ja --screen select
python3 tools/capture_localization.py --locale ja --screen reset
python3 tools/capture_campaign.py --locale ja --stage 6 --signature --equipment
```

The menu capture also supports map, play, paused, win, and over screens.
Regenerate the signed `site/` release before deploying from main.
