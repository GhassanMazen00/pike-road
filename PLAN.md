# Pike Road — Project Context

Handoff file. Read this first, then start on the "First milestone" section at the bottom.

## The project

- **What:** a story-driven, first-person horror game for **PC (Windows)**, planned for Steam.
- **Owner:** Ghassan. Writes the story, plays every build and decides what looks and feels right.
- **Inspiration:** short indie horror on Steam, such as *Mimic Search*, *Missing Hiker* (both by Gemezl) and *The Lost Tape: Cellar*. These are low-budget games that get by on atmosphere, real sound and a strong hook rather than expensive graphics.
- **Structure:** three parts, each playable on its own. Part 1 comes first.

## What went wrong before (do not repeat)

A browser prototype (Three.js, one HTML file) was built in an earlier session. The owner rejected it. Their exact complaints:

- The car, road, gas station, characters and trees looked bad. Everything was built from code-generated boxes with code-drawn textures.
- The house was "so basic", with no real detail.
- The audio was annoying. It was all synthesized tones and noise.
- Dialogue bug: the clerk and the deputy talked in the same conversation box, so it read as both talking at once.
- The red, static-filled screen effect during chases was blinding.
- Hiding forced a hold-your-breath mechanic. **The owner never asked for that. Do not add it.**

**Rules from this:**
- Use **real assets**: models, PBR textures, Mixamo characters and animations, recorded sound effects. Do not build visible art out of primitives except as temporary blockout.
- Keep screen effects (grain, vignette, chase effects) subtle and optional.
- One speaker per dialogue line, one conversation at a time.
- Hiding works on its own. You are safe unless the enemy saw you get in.
- Do not show big chunks to the owner untested. Run the game, screenshot it and look at it yourself before asking for feedback.

## Tech decisions

- **Engine:** Godot 4, standard (GDScript) build, latest stable. Ask the owner which exact version they installed.
- **Target:** Windows desktop export.
- **Repo:** `GhassanMazen00/pike-road`. Use Git LFS for large binary assets (`.glb`, `.fbx`, `.png`, `.jpg`, `.wav`, `.ogg`, `.hdr`, `.exr`).
- **Asset sources** (prefer CC0, and record every asset and its license in `CREDITS.md`):
  - Poly Haven: textures, HDRIs, props (CC0)
  - Quaternius and Kenney: low-poly models (CC0)
  - Sketchfab: models with downloadable licenses (check each one; CC-BY needs credit)
  - Mixamo: characters and animations (needs an Adobe login, so the owner downloads them)
  - Freesound: recorded sound effects (check each license)
- **Downloads:** the owner downloads anything that needs a login. Give them an exact list with links, file names, formats and the folder each file goes in.
- **Suggested layout:** `scenes/`, `scripts/`, `assets/{models,textures,audio,characters}/`, `ui/`.

## Working style

- Build in small milestones. Each one ends with the owner playing it.
- The owner gives blunt feedback. Fix what they say. Don't argue taste.
- Be honest about limits. If something will look bad with what's available, say so before building it.

## Story (owner's script, organized)

**Names chosen so far** (all changeable):
- Player: Daniel Reyes, 38
- Wife: Nora
- Grandfather ghost: Amos Pike
- Granddaughter ghost: June Pike
- Deputy: R. Haskins
- Gas station clerk: Marge
- Roadside stand: an unnamed old woman
- The house: "the old Pike place" on Pike Road, Hollow Pines County

**Backstory:** Amos and June lived in the house and were killed in a robbery. They are buried in the forest. Daniel learns this from an old newspaper in the house. Renters keep going missing in the area.

### Part 1: The Drive, The House, The Night

1. Daniel drives at night to a rental house in the woods after a fight with Nora. He wants a few days alone.
2. He makes a few stops along the way:
   - **Gas station:** buys a flashlight, batteries and a frozen dinner. Missing-person posters hang on the board. The clerk reacts to "Pike Road." Deputy Haskins is there separately. He gives Daniel his direct number because 911 takes about 40 minutes out here.
   - **Roadside stand:** an old woman gives him candles and matches. She warns him in an indirect way ("There aren't any neighbors on Pike Road. Not anymore." "If a little girl comes to your door with a pie, don't you eat it.").
   - **Checkpoint:** a guard writes his name down and says something like "Count the knocks after midnight. Don't answer them."
   - Optional on the road: a glimpse of a little girl at the roadside in the headlights.
3. He arrives at an old house in the woods and unpacks: carries his bags in and puts things away.
4. **Weird things start:**
   - The front door opens by itself and no one is there. He closes it.
   - He heats a meal in the microwave. Someone knocks and keeps knocking every 5 to 10 seconds until he answers.
   - It's an old man: "I'm your neighbor, just saying hi." He gives his name (Amos) and June's. Daniel is uneasy, says thanks and closes the door.
5. A text arrives from Nora: sorry about the fight, she knows he needed time away, she hopes they can fix things. He replies.
6. **The lights go out.** He gets the flashlight (bought earlier) from the living room and checks the fuse box behind the house. One fuse is missing.
7. On the way back he finds a little girl (June) in the dark. Their conversation:
   - Daniel: "Who are you? What are you doing out here?"
   - June: "Out playing."
   - June: "Grandpa told me about you. You're our new neighbor."
   - Daniel: "I'm just visiting. Go home, it's dark and late. Be careful."
   - June, creepy: "No, you're the one who needs to be careful."
   - She drops the missing fuse, laughs and runs into the forest.
   - Daniel: "This girl and her grandpa are so weird. I need to be careful."
8. He puts the fuse back. If he wanders off instead, he says to himself "I better go put back this fuse." Then he goes to bed.
9. He wakes in the dark to loud TV static. Amos and June are on his couch watching a fuzzy TV.
   - Daniel: "What are you doing in here? Get out!"
   - Amos: "Relax, we don't have a TV, we wanted to watch our favorite show."
   - Daniel: "There's nothing but static! You broke in. Get out or I call the police."
   - Amos: "Not if I take your fingers first." He pulls a knife.
10. **Chase:** Daniel runs upstairs and must hide in a room (a closet). If he's caught, the death must be **very scary**. Checkpoint: the moment the knife comes out.
11. Hidden in the closet: "I have to call someone." He waits until Amos leaves the room, sneaks out to get his phone, and calls Deputy Haskins: someone broke in and attacked him. Haskins: "On my way. Stay hidden."
12. After he hangs up, a loud door slams. "Maybe they left." The house is empty. He locks the front door: "I must get something to protect myself."

### Part 2: The Basement

1. He looks for a weapon. The kitchen has a spatula: "Maybe something stronger in the basement."
2. The basement door is locked, so he must find the key. He can turn lights on and search drawers while the goal is "find the key."
3. When he finds the key, someone knocks: "This must be the police." At the door he gets two choices:
   - **Open:** no one is there. The door closes, he turns around, and June jumps on his face and kills him. Checkpoint: the knock.
   - **"Who's there?":** June says "It's me, I have a sorry gift from me and my grandpa, a tasty pie." He can tell her to go away, or open the door.
     - Opening always gives the same death as above, unless he holds the **spatula**. Then he hits her, she runs and the door closes.
     - If he keeps refusing, the door bangs violently for a few seconds, then stops.
4. "I must open the basement." If he wanders: "I should use the key I found." The key only works after the knock scene.
5. **The basement:** dark and scary. He needs the flashlight and can hold the spatula at the same time. He searches for a gun. Finding it should take about 4 to 6 minutes, and he may never find it.
6. Four minutes after the basement opens, knocking starts again and doesn't stop. He can go answer it with or without the gun, either opening the door or asking "who's there?"
7. **It's Deputy Haskins.** Daniel tells him what happened. Haskins asks the intruders' names. Daniel knows them from Part 1, so slot them into the dialogue.
   - Haskins is shocked and accuses Daniel of messing with him: "These two lived here. They're both dead, buried in the forest. You outsiders always fake a report and disappear."
   - He leaves. Daniel begs him to wait.
8. Nora texts asking how he is. He replies: "It was a mistake coming here. I'm packing and coming back tonight." She answers: "I'll wait for you, not gonna sleep, babe." He starts packing.

### Part 3: The Graves and Home (the owner's outline, details still open)

1. While packing, he finds notes from people who stayed before. They tried to learn what these dark souls want: certain **items must be taken to their graves**, and only then is the renter left alone. He also finds an old newspaper about the Pike robbery and murders.
2. He searches the house for the items while Amos and June attack and scare him.
3. **The forest:** he takes the items to the graves. More scares on the way, and he can hide behind or in trees.
4. When the items are delivered, June appears, throws him his car keys, and disappears with her grandpa.
5. He drives home to a small apartment with an upstairs. He texts Nora: "I'm here." She replies: "Good, I'm waiting for you upstairs under the bed." He: "Under the bed? What are you saying?" No answer.
6. The apartment is messy and bloody, and the player can explore it before the bedroom. Under the bed he finds Nora dead: "No… Nora."
7. He stands up and Amos and June are there: "Thanks for releasing us into this world. It's time for us to punish those who hurt us." They kill him. **The end.**

**Open questions for the owner:**
- **Twist idea (not approved yet):** the newspaper names a robbery suspect with Nora's maiden name, so it's clear why she was the target.
- What does the gun do, if he finds it?
- What exactly are the grave items, and where are they?
- Do the candles and matches from the stand get used, for example at the graves?

## Bigger vision (later, separate)

The owner also wants a five-part political-horror series that lives on a website. Finishing one part gives the player a code, and the code unlocks the next part and changes it based on their choices. The working concept is "The Quiet Republic." **Not in scope now.** Pike Road comes first.

## First milestone: the living room

**Goal:** prove the game can look and feel good before building any story.

- A Godot 4 project with `.gitignore`, Git LFS and the folder layout above.
- A first-person controller: walk, run, mouse look, a flashlight (F), interact (E), footstep sounds that change with the surface (wood or carpet).
- One living room built with **real assets**: wood floor, aged wallpaper, couch, an old CRT TV, coffee table, rug, lamp, front door, window with night outside.
- Moody lighting: one practical lamp, the flashlight, darkness outside the window, subtle fog. Use Godot 4's lighting features: shadows, SSAO and volumetric fog if it runs well.
- Real ambient sound: room tone, an old clock ticking, the house creaking.
- First give the owner an exact download list (links, file names, target folders), then wire the files in.
- Before showing the owner: run it, take screenshots, check them yourself, and fix anything ugly.
- Then the owner plays it and judges it. Only move on once they approve the room.
