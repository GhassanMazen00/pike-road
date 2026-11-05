# Getting the assets

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

## Still needed from the owner (login sites)

These need your account, so you download them. Exact picks and links will be added here per milestone.

1. **Characters**: Amos (old man), June (girl, about 8), Deputy Haskins, Marge, the old woman, Nora. Realistic, rigged or rig-able.
2. **Animations (Mixamo)**: walk, run, idle, sitting idle, knife attack, grab or lunge, and a crawl or jump for June.
3. **Trees and forest**: realistic pines with simpler versions for distance, for the yard, the road and the Part 3 forest.
4. **Car**: an interior and exterior for the drive.
5. **Voices** (optional): we can record lines later, or keep subtitles only.
