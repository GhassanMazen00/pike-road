# Getting the assets

## For you to download now: the opening (Sketchfab, free account)

1. Sign in at sketchfab.com (a free account works).
2. Open each link and click **Download 3D Model**, then pick **glTF** (the "Autoconverted format" row). It downloads a `.zip`.
3. Unzip each into its own folder under `C:\pike road\assets\sketchfab\` using the folder name below
   (for example `C:\pike road\assets\sketchfab\riverside88\scene.gltf`).
4. Tell me when they're in. I'll check every file, fix scale and materials, and credit each author.

All of these are **CC Attribution**: free for a commercial Steam game, as long as the credits name the author.
I'll handle the credits.

| # | What | Link | Folder name | Author |
|---|---|---|---|---|
| 1 | **The car**: 1980s American sedan with an interior ("Riverside '88") | https://sketchfab.com/3d-models/riverside-88-low-poly-model-8509a7f82665442592627940b7a1cfab | `riverside88` | Daniel Zhabotinsky |
| 2 | **Pine tree** (the main forest tree, light enough for thousands) | https://sketchfab.com/3d-models/pine-tree-game-ready-dc3fbd9205cf4027a4455d1f415e0478 | `pine_tree` | Wenedi |
| 3 | **Forest pack** (more conifers, bushes and rocks for variety) | https://sketchfab.com/3d-models/coniferous-forest-assets-pack-240ce9cf0ad3474f809a59f9446e63cd | `forest_pack` | Dari |
| 4 | **The deer** (realistic white-tailed buck) | https://sketchfab.com/3d-models/realistic-whitetailed-deer-free-commercial-use-d8192bb6909042a0b8ba08774358a8f1 | `deer` | avatarka |
| 5 | **Gas station building** (old roadside station with canopy) | https://sketchfab.com/3d-models/old-gas-station-ad5f6816d35a4944a034b80443a62cfa | `gas_station` | Wardster |
| 6 | **Gas pump** (vintage) | https://sketchfab.com/3d-models/vintage-gas-pump-0096f206ce1a4381bea58f9f94fc6b1c | `gas_pump` | Rescue3D Assets |
| 7 | **Drinks cooler** for the store | https://sketchfab.com/3d-models/commercial-fridge-2174e1e4f1f24f1a95aa110ee060f473 | `store_fridge` | Sean Thomas |
| 8 | **Cash register** | https://sketchfab.com/3d-models/old-cash-register-pbr-cfdc8b3756fa4bb4b7c26d8ac92fd1bc | `cash_register` | Li.Wenzhao |
| 9 | **Store shelves and products** (big pack; I'll use only parts) | https://sketchfab.com/3d-models/multi-supermarket-assetpack-vol1-de856c67c9fc4880978f375f987c27bd | `supermarket_pack` | multikunst |

Things I'll get myself (CC0, no login): the asphalt and dirt-road textures, road signs, the mailbox and the payphone (Poly Haven).

## Animations (Mixamo, free Adobe account)

The cast is already built and uses Mixamo's own skeleton, so **you don't upload anything**. Just download
animations and they play on every character.

1. Go to mixamo.com and sign in. Leave the default character (Y Bot) selected.
2. For each animation below: search the name, click the best match, then **Download** with these settings:
   **Format: FBX Binary (.fbx)**, **Skin: Without Skin**, **Frames per second: 30**, **Keyframe reduction: none**.
   If an animation shows an **"In Place"** checkbox, tick it.
3. Save every file into `C:\pike road\assets\animations\mixamo\` and keep Mixamo's file name.

If a name isn't found exactly, take the closest match. Tell me which ones you picked.

| For | Search for |
|---|---|
| Everyone | `Idle`, `Breathing Idle`, `Walking`, `Running`, `Talking`, `Turn` (left and right) |
| Walt (behind the counter) | `Bored`, `Look Around`, `Standing Greeting`, `Nervously Look Around` |
| Haskins | `Drinking` (his coffee), `Talking On Phone`, `Standing Arguing` |
| Bench man | `Sitting Idle`, `Stand Up`, `Sad Idle` |
| Agnes | `Old Man Idle`, `Old Woman Walk` (or any slow walk), `Waving` |
| Lily | `Sad Idle`, `Crouch Idle`, `Zombie Crawl`, `Mutant Run`, `Standing Clap` |
| Daniel (hands) | `Driving`, `Reaching Out`, `Opening Door` |
| Scares | `Zombie Attack`, `Mutant Swiping`, `Zombie Scream` |

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
