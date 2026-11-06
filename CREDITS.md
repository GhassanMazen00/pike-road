# Credits

Every third-party asset in the game, where it came from and its license.
Re-download everything with `tools/fetch_polyhaven.ps1` and `tools/fetch_licensed_audio.py` (see README section in DOWNLOADS.md).

## Models: Poly Haven (CC0)

From [polyhaven.com](https://polyhaven.com), glTF. License: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) (no credit required; credited anyway).
Folder: `assets/models/<id>/`. Link: `https://polyhaven.com/a/<id>`.

Furniture and props: Television_01, sofa_03, Rockingchair_01, gothic_coffee_table, side_table_tall_01, vintage_wooden_drawer_01,
vintage_grandfather_clock_01, vintage_oil_lamp, Chandelier_01, vintage_cabinet_01, fancy_picture_frame_01, ornate_mirror_01,
electric_stove, vintage_microwave, GothicBed_01, ClassicNightstand_01, GothicCabinet_01, vintage_day_bed, painted_wooden_cabinet,
round_wooden_table_01, WoodenChair_01, dining_chair_02, WoodenTable_03, vintage_pocket_watch, CheeseBox_01, vintage_flashlight,
bolt_action_rifle_7_62, power_box_01, painted_wooden_chair_01, hanging_picture_frame_02, Shelf_01, Ottoman_01,
vintage_electric_kettle, tea_set_01, wooden_cutting_board, pot_enamel_01, jug_01, wine_bottles_01, vintage_suitcase,
throw_pillows_01, rubber_duck_toy, worn_metal_rack, steel_frame_shelves_01, bench_vice_01, cardboard_box_01, old_military_crate,
wooden_crate_01, Barrel_02, metal_toolbox, hatchet, crowbar_01, wooden_candlestick, pull_chain_light_socket, lightbulb_01,
wooden_bookshelf_worn, book_encyclopedia_set_01, wooden_bucket_01, rusted_spade_01, Lantern_01, security_light,
painted_wooden_nightstand, trashbag.

## Textures: Poly Haven (CC0)

decrepit_wallpaper, old_wooden_floor_03, white_plaster_02, quatrefoil_jacquard_fabric, weathered_plank_siding, wood_floor_deck,
forest_leaves_04, old_linoleum_flooring_01, dirty_concrete, plastered_stone_wall, painted_plaster_wall.

## Characters: MakeHuman / MPFB

The cast (`assets/characters/cast/`) is built with [MPFB](https://static.makehumancommunity.org/mpfb.html)
from `tools/characters/cast/*.json`. Base bodies, skins, eyes, eyebrows, eyelashes, hair styles and hair
colors are MakeHuman system and community assets under **CC0**.

These clothing assets are **CC-BY** (credit required), from the MakeHuman community asset packs:

| Asset | Author | Pack |
|---|---|---|
| Men's untucked button-down shirt, shirt with tie, hooded sweat jacket, straight-leg jeans | Elvaerwyn (elvs) | shirts02, pants02 |
| Men's trousers 1 and 2, women's monk-strap shoes | Mindfront | pants02, shoes02 |
| Old female sweater | Janexx | shirts02 |
| Mary Jane shoes | DressUpDoc | shoes02 |
| Women's tight jeans | punkduck | pants02 |

CC0 clothing used (credited anyway): Toigo (dress, skirt, sweater, ankle boots, hair colors), Culturalibre (boots),
Frankyaye (glasses), Cortu (messy hair), Dariush086 and Bogdan666 (hair colors).

## Audio

| Sound | Source | License |
|---|---|---|
| Fallback footsteps (wood, carpet) in `assets/audio/footsteps/` | Kenney, [Impact Sounds](https://kenney.nl/assets/impact-sounds) | CC0 1.0 |
| Footsteps, doors, knocks, drawers, creaks, room tones, night ambience, static, heartbeat (`assets/audio/licensed/`, not in git) | [Sonniss GDC Game Audio Bundle](https://sonniss.com/gameaudiogdc) 2018/2019. Contributors include PMSFX, Soundopolis, 3maze, Articulated Sounds, Coll Anderson, Matt Script, Studio 23, 2496SoundEffects, Ivo Vicic, Airborne Sound, Eiravaein Works, GainWalkers, UberDuo, The Sound Pack Tree, Sounds Visual, Discover Oregon, Federico Soler Fernández | Sonniss GDC license: royalty-free, commercial use, no attribution required. **Not redistributable as raw sound files**, which is why they're kept out of the public repo. The exact file list is in `tools/licensed_audio_manifest.json`. |
