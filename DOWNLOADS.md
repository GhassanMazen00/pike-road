# Getting the assets

All downloads are done. Both lists below are kept as a record of what came from where.

## Sketchfab models (CC-BY 4.0, in `assets/sketchfab/<folder>/`)

Each folder holds the glTF export plus its `license.txt`. Credit lines are in CREDITS.md.

| What | Folder | Author | Note |
|---|---|---|---|
| The car, 1980s sedan with interior ("Riverside '88") | `riverside88` | Daniel Zhabotinsky | 4.9 m, correct scale |
| Pine tree (main forest tree) | `pine_tree` | Oskar "K1TT3N" Adamczyk | imports 75 m tall, scale x0.2 |
| Coniferous forest pack (conifers, dead trees, bushes, rocks) | `forest_pack` | Dari | |
| Realistic white-tailed deer | `deer` | avatarka | imports huge, scale x0.015 |
| Old gas station with canopy | `gas_station` | Wardster | 13 x 15 m |
| Vintage gas pump | `gas_pump` | Rescue3D Assets | 1.83 m |
| Commercial drinks fridge | `store_fridge` | Sean Thomas | 2.18 m |
| Old cash register | `cash_register` | Li.Wenzhao | scale x0.2 |
| Supermarket goods pack (water, cereal, pallets, sale signs; no shelves) | `supermarket_pack` | multikunst | |

## Mixamo animations (in `assets/animations/mixamo/`)

Downloaded on the X Bot, **without skin**, FBX, 30 fps, no keyframe reduction, **in place** for walks, runs
and the crawl. Our MPFB cast uses Mixamo's bone names, so no retargeting is needed.

`godot --headless --path . --script res://tools/animations/build_library.gd` packs them into
`assets/animations/mixamo_library.res`: it drops tracks for the 13 finger/toe-end bones our rig lacks and
sets loop modes. To play one on a character, add an AnimationPlayer next to the character's `Skeleton3D`
(root = the node holding it), load the library, and set `Skeleton3D.motion_scale` to
character hips height / the library's `xbot_hips_height` meta, so children and short characters keep their
feet on the floor.

| File | Mixamo name | Use |
|---|---|---|
| `idle`, `breathing_idle`, `weight_shift_idle` | Idle, Breathing Idle, Weight Shift | everyone standing |
| `walking`, `careful_walk`, `female_walk`, `old_man_walk` | Male Standard Walk, Male Careful Walk, Female Walk, Old Man Walk | walking |
| `flashlight_walk` | Standing Torch Walk Forward | walking with a light held up |
| `sneak_walk`, `running`, `left_turn`, `right_turn` | Sneak Walk, Running, Left Turn, Right Turn | |
| `talking_two_hands`, `talking_chat`, `arguing`, `phone_call` | Talking, Talking At Watercooler, Standing Arguing, Talking On A Cell Phone | conversations |
| `bored`, `looking_around`, `nervous_look_around`, `standing_greeting` | Bored, Looking Around, Nervously Look Around, Standing Greeting | Walt |
| `drinking` | Drinking | Haskins' coffee |
| `sitting_idle`, `sit_to_stand`, `sad_idle` | Sitting Idle, Sit To Stand, Sad Idle | bench man |
| `old_man_idle`, `waving` | Old Man Idle, Waving | Agnes |
| `crouch_idle`, `zombie_crawl`, `mutant_run`, `standing_clap` | Crouching Idle, Zombie Crawl, Mutant Run, Standing Clap | Lily |
| `zombie_walk`, `creeping_walk` | Zombie Walking, Creeping Zombie Walk | Lily, late game |
| `driving`, `honking_horn`, `reaching_out`, `opening_door` | Driving, Honking Horn, Reaching Out, Opening Door Inwards | Daniel's arms |
| `zombie_attack`, `mutant_swiping`, `zombie_scream` | Zombie Attack, Mutant Swiping, Zombie Scream | scares |

## On a new machine (everything Claude downloaded)

Models and textures are in git (LFS). The licensed sounds are not, because the license forbids sharing raw files publicly. Recreate them with:

```
python -I tools/fetch_licensed_audio.py
python -I tools/process_audio.py
```

To re-download Poly Haven assets from scratch: `powershell -ExecutionPolicy Bypass -File tools\fetch_polyhaven.ps1`

After changing the house layout in `tools/house_builder.gd`, regenerate the house:

```
godot --headless --path . --script res://tools/house_builder.gd
```
