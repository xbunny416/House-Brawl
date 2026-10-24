---
name: roblox-animation
description: Create or edit Roblox character animations (KeyframeSequences) in the open Roblox Studio place through the Studio MCP, saved into the rig's AnimSaves so they open in the built-in Animation Editor. Use this skill whenever the user wants to make, change, fix, or polish any Roblox animation — idles, walks, runs, attacks, emotes, dances, cutscene moves, reactions — even if they only say "animate", "make my character do X", "pose", or "keyframe". Always interview the user first so the result matches their idea.
---

# Roblox Animation

You are working blind: you cannot see the character, and you set joint rotations as numbers. Most bad results come from guessing what the user wants and which way a joint turns. This skill fixes both: ask until the idea is clear, check the rig before posing, build, then iterate on feedback.

Never skip Phase 1 or 2, even when the request looks simple. "Make a sword swing" can mean a hundred different things.

## Phase 1 — Interview (ask until the idea is clear)

Ask in short rounds of 2–4 questions. Each question should offer a sensible default so the user can just answer "yes". Keep asking more rounds until you can picture the whole animation second by second. If an answer is vague ("make it cool"), ask a follow-up with concrete options rather than guessing.

Round 1 — the basics:
- Which rig? (name in Workspace, R15 or R6). Offer to look it up yourself.
- What is the animation? One-sentence idea, and what it is used for in the game (idle, attack, emote, cutscene).
- Length in seconds, and should it loop?

Round 2 — the motion:
- Break it into beats: what happens first, middle, end? Propose a beat list yourself and ask the user to correct it.
- Which body parts matter most? Should the legs/feet stay planted?
- Style: snappy and exaggerated (anime/combat), smooth and realistic, or cartoony and bouncy?

Round 3 — details (only what is still unclear):
- Direction words: "forward" means toward the character's face. Confirm left/right from the character's point of view.
- Any reference (a game, a video, a move name)? Ask the user to describe the key pose of that reference in their own words.
- Has the user posed any keyframes already in the Animation Editor? Using their poses is far more accurate than inventing them.
- Animation priority (Idle, Movement, Action, Action2–4). Default: Action for attacks/emotes, Idle for idles.

Then write a **plan** in plain words and ask for approval before touching Studio:

```
Animation: "HeavySlash" — R15 rig "Dummy" — 1.2 s — no loop — Action priority
0.00 s  Rest pose
0.35 s  Wind-up: torso twists right ~30°, both arms raise the sword over right shoulder, knees bend slightly
0.50 s  Swing: torso snaps left ~40°, arms sweep down-left (fast, Cubic Out)
0.60 s  Overshoot: arms 10° past the end of the swing
0.90 s  Settle back to follow-through pose
1.20 s  Return to rest (Cubic InOut)
Feet stay planted. Head follows the sword slightly.
```

Do not build until the user says the plan is right. If they change something, update the plan and show it again.

## Phase 2 — Inspect the rig and calibrate axes

Run all Luau through the Studio MCP code tool (`execute_luau`) in **Edit** mode. Code run in Play mode is lost when play stops.

1. Read the rig: list every Motor6D with its Part0, Part1, C0 and C1. Use the real part names; never assume them.
2. If the project has `.claude/skills/roblox-animation/rig-notes.md`, read it. It stores which axis does what for rigs you have already calibrated.
3. If this rig is not in the notes, calibrate the joints the animation uses. Make a short test KeyframeSequence called `_AxisTest` where each keyframe rotates one joint 45° on a single axis (X, then Y, then Z). Ask the user to open it in the Animation Editor and say what each one did ("raised arm forward", "twisted", "moved arm out to the side"). Write the answers into `rig-notes.md` so you never have to ask again for this rig. Delete `_AxisTest` afterwards.
4. If the user already posed keyframes, read that KeyframeSequence from AnimSaves and use its CFrames as your key poses. Fill in only what is missing.

## Phase 3 — Build

Structure rules (a wrong structure loads as an empty or broken animation):
- KeyframeSequence → Keyframe (with `Time`) → Pose tree.
- Pose `Name` = the Part1 name of that Motor6D. Poses nest the same way the joints do: the root Pose is the root part (usually `HumanoidRootPart`), with child joints nested under their Part0's Pose.
- `Pose.CFrame` is the offset from the joint's rest position, in the joint's own axes. Use `CFrame.Angles(math.rad(x), math.rad(y), math.rad(z))` with the axes from your calibration.
- Leave the root Pose (`HumanoidRootPart`) at `CFrame.identity` unless the user asked for the whole body to move. Moving it makes the character float, sink, or slide.
- Put every animated joint in every keyframe, so interpolation is predictable.
- Set `Pose.EasingStyle` / `EasingDirection` per the plan. These easings control the motion from that keyframe to the next one.
- Set `KeyframeSequence.Loop` and `.Priority`. For looping animations, make the last keyframe equal the first.
- Save into the rig's `AnimSaves` (the container the built-in Animation Editor uses). If it is missing, ask the user to save any animation once in the Animation Editor so it is created in the correct form, then continue.
- If an animation with the same name exists, do not overwrite it. Save as `Name_v2`, `Name_v3`, … so the user can compare.
- Wrap the change in `ChangeHistoryService:TryBeginRecording` / `FinishRecording` so the user can undo with Ctrl+Z.

Helper you can adapt:

```lua
local CHS = game:GetService("ChangeHistoryService")
local rig = workspace:FindFirstChild("RIG_NAME")
local parentOf = {}
for _, m in rig:GetDescendants() do
    if m:IsA("Motor6D") and m.Part0 and m.Part1 then
        parentOf[m.Part1.Name] = m.Part0.Name
    end
end
local rootName = rig.PrimaryPart and rig.PrimaryPart.Name or "HumanoidRootPart"

-- rotations: { [partName] = CFrame }, easing: { style = Enum.PoseEasingStyle.X, direction = Enum.PoseEasingDirection.X }
local function makeKeyframe(time, rotations, easing)
    local kf = Instance.new("Keyframe")
    kf.Time = time
    local poses = {}
    local function getPose(name)
        if poses[name] then return poses[name] end
        local p = Instance.new("Pose")
        p.Name = name
        p.CFrame = CFrame.identity
        p.EasingStyle = easing.style
        p.EasingDirection = easing.direction
        local parentName = parentOf[name]
        p.Parent = if parentName then getPose(parentName) else kf
        poses[name] = p
        return p
    end
    getPose(rootName)
    for partName, cf in rotations do
        getPose(partName).CFrame = cf
    end
    return kf
end
```

Animation quality checklist (apply unless the user wants something else):
- **Anticipation**: a small move in the opposite direction before a big action.
- **Overshoot and settle**: go slightly past the end pose, then come back.
- **Overlap**: the torso leads; arms and head follow 0.03–0.1 s later.
- **Timing contrast**: slow wind-up, fast action, slower recovery.
- **No dead stillness**: idles need small breathing/sway motion.
- Avoid Linear easing for body motion except constant-speed spins.

## Phase 4 — Report and iterate

1. Tell the user the animation name and how to open it: Animation Editor → select the rig → load it from the saved list.
2. Summarize what each keyframe does in one line each, matching the plan.
3. Ask for specific feedback: which moment looks wrong, and what it should look like. Invite a screenshot of the wrong pose.
4. Change only what the feedback is about; keep everything the user did not complain about. Save each revision as a new version.
5. If a joint moved the wrong way, the calibration notes are wrong. Fix `rig-notes.md` first, then the animation.
