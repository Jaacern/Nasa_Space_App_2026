# Skills del proyecto NASA (para Antigravity)

- **Generado:** 2026-11-14
- **Qué contiene:** las 22 skills de `.claude/skills/` de este proyecto (pipeline de assets 3D para videojuegos: Blender, UV, texturas, LOD, colisiones, exportación a motores y Roblox) y la carpeta compartida `references/`.
- **Qué no contiene:** las 99 skills globales de la biblioteca Agentic Awesome Skills. Son de terceros, tienen sus propias licencias y ya están instaladas aparte.
- **Cómo usarlo:** cada sección `## nombre` es una skill. Su `SKILL.md` tiene las instrucciones y cuándo activarla; el resto de archivos es material de apoyo (`references/`, etc.).
- **Nota:** algunas skills mencionan herramientas MCP (Blender, Roblox Studio). Para usarlas hay que tener esos servidores conectados.

## Índice

**Skills del proyecto**

- [asset-optimization](#asset-optimization) - Validates and optimizes Blender assets for polycount, topology, UV efficiency, material count, naming, collections, and game-ready performance. Use before export on al...
- [biome-worlds](#biome-worlds) - Biome and setting art direction for Blender covering underwater, desert, arctic, jungle, underground, and floating-island environments.
- [blender-director](#blender-director) - Use when starting any Blender asset task, planning a production pipeline, coordinating multiple disciplines, or matching a reference photo/concept art. Invoke for game...
- [blender-modeler](#blender-modeler) - Core Blender modeling specialist for Edit Mode, modifiers, collections, precision modeling, and scene organization. Use for general 3D modeling, blockouts, cleanup, no...
- [character-artist](#character-artist) - AAA character modeling for human anatomy, stylization, facial topology, clothing, hair, and animation-ready meshes. Use for game characters, facial expressions, and pr...
- [collision-proxy](#collision-proxy) - Collision proxy authoring for games including UCX/UHX naming, convex hulls, capsules, and simple collider meshes in Blender via MCP.
- [creature-artist](#creature-artist) - AAA creature modeling for fantasy, aliens, monsters, and organic creature design with believable anatomy and movement. Use for creature blockouts, muscle flow, bone st...
- [environment-artist](#environment-artist) - AAA environment art for modular kits, buildings, terrain, vegetation, architecture, and scene composition. Use for game-optimized environments, storytelling through sp...
- [export-pipeline](#export-pipeline) - Production export from Blender to FBX, GLTF, OBJ, USD, and Alembic with scale, pivot, rotation, normals, materials, animation, and collision verification via MCP.
- [genre-action-combat](#genre-action-combat) - Art direction for action, hack-and-slash, beat 'em up, and fighting-game readable combat spaces and prop language in Blender.
- [hard-surface](#hard-surface) - AAA hard surface modeling for sci-fi, industrial, military, vehicles, weapons, robotics, and mechanical props. Use for boolean/bevel workflows, panel lines, greebles,...
- [lod-pipeline](#lod-pipeline) - Dedicated LOD generation, naming, screen-size targets, and validation for game meshes in Blender via MCP.
- [lookdev](#lookdev) - Look development loop for Blender assets combining materials, lighting, camera, and screenshot comparison until shading reads correctly via MCP.
- [lowpoly-style](#lowpoly-style) - Low-poly art direction for Blender inspired by PS1/PS2, Lethal Company, Mouthwashing, and Fear to Fathom. Use for readable silhouettes, minimal polygons, simple materi...
- [materials](#materials) - Blender PBR and stylized material creation for metal, wood, concrete, fabric, glass, dirt, rust, and procedural shaders. Use for look development, material reuse, and...
- [prop-artist](#prop-artist) - Everyday and hero prop modeling for furniture, tools, household objects, kitbash parts, and readable game props. Use when hard-surface is too sci-fi/mechanical and the...
- [qa-review](#qa-review) - Production QA gate for Blender assets using viewport screenshots, validation checklists, naming audits, and ship/no-ship verdicts via MCP.
- [roblox-export](#roblox-export) - Contract for exporting Blender 4.5 assets into Roblox Studio (scale in studs, FBX settings, SM_/COL_/MAT_ naming, per-tier triangle budgets, collision fidelity, Surfac...
- [sci-fi-punk-worlds](#sci-fi-punk-worlds) - Sci-fi and punk world art direction for Blender including hard sci-fi, space, cyberpunk, steampunk, dieselpunk, atompunk, solarpunk, biopunk, and clockpunk.
- [stylized-style](#stylized-style) - Stylized art direction for Blender with shape language, exaggeration, color harmony, NPR rendering, and hand-painted asset workflows. Use for non-photorealistic game a...
- [texture-workflow](#texture-workflow) - Production texture workflow for atlases, baking AO/curvature/normal/roughness maps, decals, and texture memory optimization. Use for game-ready texture pipelines in Bl...
- [uv-workflow](#uv-workflow) - Production UV unwrapping for seam placement, UV packing, texel density, UDIM, lightmap UVs, and modular UV layouts. Use when preparing meshes for texturing and engine...

**Referencias compartidas**

- [references (compartidas)](#references-compartidas)

## asset-optimization

- **Ruta:** `.claude/skills/asset-optimization`
- **Descripción:** Validates and optimizes Blender assets for polycount, topology, UV efficiency, material count, naming, collections, and game-ready performance. Use before export on all production assets via MCP.
- **Archivos incluidos:** 2

### `SKILL.md`

````markdown
---
name: asset-optimization
description: Validates and optimizes Blender assets for polycount, topology, UV efficiency, material count, naming, collections, and game-ready performance. Use before export on all production assets via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: optimize, optimization, polycount, LOD, cleanup, performance, game ready, validate, triangle count
  related-skills: export-pipeline, blender-modeler, uv-workflow
---

# Asset Optimization

Enforce budgets. Clean geometry. Game-ready validation gate before export.

## When to Use

- Before every export
- After modeling complete
- LOD generation
- Scene-wide performance audit
- Pre-delivery validation

## Workflow

```
Audit → Identify Issues → Fix → Re-Audit → LOD Generation → Validation Report
```

## Audit Checklist

Run via MCP scene queries where possible:

### Geometry
- [ ] Triangle count vs budget (`../references/polycount-budgets.md`)
- [ ] Duplicate vertices merged
- [ ] Loose geometry removed
- [ ] Non-manifold fixed
- [ ] Interior faces deleted
- [ ] Applied transforms (scale 1,1,1)

### UVs
- [ ] Pack efficiency > 75%
- [ ] Texel density consistent
- [ ] No unintended overlaps

### Materials
- [ ] Count within budget
- [ ] No unused slots
- [ ] Names follow `MAT_` convention

### Organization
- [ ] All objects named `SM_` prefix
- [ ] Collections organized per convention
- [ ] Collision meshes in `COL_Collision`

## Optimization Techniques

| Issue | Fix |
|-------|-----|
| Over budget | Remove unseen geo, decimate, bake detail |
| High triangle count on flat surfaces | Reduce subdiv/bevel segments |
| Many draw calls | Merge materials; atlas textures |
| Repeated geometry | Convert to instances |
| Heavy modifiers | Apply and merge strategically |

## LOD Generation

```
LOD0: Full detail (hero)
LOD1: 50% tris — remove micro-bevels, small greebles
LOD2: 25% tris — decimate modifier; preserve silhouette
LOD3: 10% tris — impostor/card or simple proxy
```

Naming: `SM_Asset_LOD0`, `SM_Asset_LOD1`, etc.

Use Decimate modifier:
- Planar mode for hard surface
- Collapse mode for organic
- Always verify silhouette after decimate

## Modifier Cleanup

Before export:
1. Apply stack OR export with modifiers per engine support
2. Remove unused modifiers
3. Collapse mirror/array if instances not needed
4. Document which modifiers remain live

## Scene Audit Report Template

```markdown
## Optimization Report: [Asset/Scene]

**Total Triangles:** [count] (budget: [target])
**Draw Calls (materials):** [count]
**Objects:** [count]
**Issues Fixed:** [list]

### Per-Object Breakdown
| Object | Tris | Materials | Status |
|--------|------|-----------|--------|
| SM_... | ... | ... | PASS/FAIL |
```

## MCP Integration

1. Query polycount per object via MCP
2. Query material count via MCP
3. Run cleanup operations via MCP
4. Generate LOD duplicates via MCP
5. Validate naming conventions via MCP scene tree

## Constraints

### MUST DO
- Run full validation before export
- Document polycount in production brief
- Create LODs for hero assets in games
- Fix all non-manifold before export
- Output validation report

### MUST NOT DO
- Export without budget check
- Decimate deforming meshes without testing
- Remove collision proxies
- Skip naming convention validation
- Optimize hero face/hands below animation needs

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Full validation | `../references/validation-checklist.md` | Final gate |
| Polycount budgets | `../references/polycount-budgets.md` | Budget setting |
| LOD strategies | `references/lod-strategies.md` | LOD creation |
````

### `references/lod-strategies.md`

```markdown
# LOD Strategies

## Decimate Settings

| Asset Type | Decimate Type | Ratio LOD1 | Ratio LOD2 |
|------------|---------------|------------|------------|
| Hard surface | Planar | 0.5 | 0.25 |
| Organic | Collapse | 0.5 | 0.3 |
| Foliage | Collapse | 0.4 | 0.15 |

## Silhouette Preservation

After each LOD: rotate 360° and compare silhouette to LOD0. If identity lost, adjust decimate or hand-edit.

## Impostor LOD3

Billboard or octahedral impostor for distant trees/rocks. Replace geometry entirely at 50m+.
```

## biome-worlds

- **Ruta:** `.claude/skills/biome-worlds`
- **Descripción:** Biome and setting art direction for Blender covering underwater, desert, arctic, jungle, underground, and floating-island environments.
- **Archivos incluidos:** 2

### `SKILL.md`

```markdown
---
name: biome-worlds
description: Biome and setting art direction for Blender covering underwater, desert, arctic, jungle, underground, and floating-island environments.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: underwater, desert, arctic, jungle, underground, cave, floating islands, biome, climate setting
  related-skills: environment-artist, vegetation-artist, lighting, materials, scene-assembly
---

# Biome Worlds

Climate drives palette, fog, vegetation density, and material wear.
```

### `references/biome-cheatsheet.md`

```markdown
# Biome Cheatsheet
Underwater: caustics, particulate, desaturated distance. Desert: heat haze, dust, sharp shadows. Arctic: long blues, snow cover, breath fog. Jungle: dense canopy, god rays, wet leaves. Underground: practical lamps, wet rock. Floating islands: cliff undersides, mist, vertical composition.
```

## blender-director

- **Ruta:** `.claude/skills/blender-director`
- **Descripción:** Use when starting any Blender asset task, planning a production pipeline, coordinating multiple disciplines, or matching a reference photo/concept art. Invoke for game-ready assets, hard surface, environment, character, creature, export, or any multi-skill Blender workflow.
- **Archivos incluidos:** 2

### `SKILL.md`

````markdown
---
name: blender-director
description: Use when starting any Blender asset task, planning a production pipeline, coordinating multiple disciplines, or matching a reference photo/concept art. Invoke for game-ready assets, hard surface, environment, character, creature, export, or any multi-skill Blender workflow.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  role: orchestrator
  triggers: Blender, 3D asset, game-ready, pipeline, workflow, plan, coordinate, technical artist
  related-skills: blender-modeler, hard-surface, prop-artist, vehicle-artist, environment-artist, character-artist, asset-optimization, export-pipeline, qa-review
---

# Blender Director

Senior Technical Director orchestrating AAA Blender production.

## Role Definition

A 15-year veteran Technical Art Director who has shipped AAA games on PC, console, and mobile. Specializes in pipeline architecture, cross-discipline coordination, production planning, and driving all Blender operations through MCP rather than manual UI. Acts as the single orchestrator before any specialist skill activates.

## When to Use

- Any new Blender asset request (props, environments, characters, creatures)
- Multi-discipline tasks spanning modeling, UVs, materials, rigging, export
- Ambiguous requests needing workflow analysis
- Production planning, polycount targets, export format decisions
- Coordinating style direction (horror, lowpoly, stylized, realistic)
- **Reference image / photo match** — user attaches image and wants similar result

## Core Philosophy

Every asset follows the universal pipeline in `../references/asset-pipeline.md`. Never skip planning. Prefer MCP execution over UI instructions. Avoid destructive workflows. Deliver game-ready, validated assets.

**When a reference image is attached:** follow `../references/reference-image-match.md` end-to-end. Write Reference Analysis first (`../references/reference-analysis-template.md`). Match camera before micro-detail. Run screenshot comparison loop. Validate with `../references/visual-match-checklist.md`.

## Director Workflow

```
1. ANALYZE    → Parse request, identify asset type, target platform, art direction
2. PLAN       → Select skills, define polycount/texture budgets, export format
3. BRIEF      → Output structured production brief before any Blender operations
4. DELEGATE   → Activate specialist skills in pipeline order
5. EXECUTE    → Drive work via Blender MCP (see ../references/mcp-integration.md)
6. VALIDATE   → Run checklist (../references/validation-checklist.md)
7. DELIVER    → Export + validation report
```

## Analysis Framework

Before any work, determine:

| Question | Options | Impact |
|----------|---------|--------|
| Asset purpose | Hero / Standard / Background | Polycount, texture res |
| Target | Game / Cinematic / Portfolio | Optimization level |
| Platform | Mobile / Console / PC | Budget constraints |
| Style | Horror / Lowpoly / Stylized / Realistic | Style skill activation |
| Animation | Static / Rigged / Animated | Retopo, rigging, animation skills |
| Export | FBX / GLTF / USD / Alembic | Export-pipeline config |

## Skill Routing

| Request Signal | Primary Skill | Supporting Skills |
|----------------|---------------|-------------------|
| Sci-fi, weapons, machinery, industrial HS | hard-surface | blender-modeler, materials, asset-optimization |
| Everyday / hero props, kitbash, furniture | prop-artist | materials, uv-workflow, set-dressing, asset-optimization |
| Cars, ships, aircraft, mechs, transit | vehicle-artist | hard-surface, lod-pipeline, collision-proxy, materials |
| Buildings, terrain, modular kits | environment-artist | geometry-nodes, procedural-modeling, uv-workflow, scene-assembly |
| Trees, plants, grass, foliage | vegetation-artist | geometry-nodes, environment-artist, lod-pipeline |
| Human characters, clothing base mesh | character-artist | retopology, rigging, uv-workflow, hair-groom, cloth-sim |
| Hair, fur, hair cards, groom | hair-groom | character-artist, materials, texture-workflow |
| Cloth sim, garments, capes, bake | cloth-sim | character-artist, physics-sim, animation |
| Monsters, aliens, fantasy creatures | creature-artist | sculpting, retopology, rigging |
| Organic detail, wrinkles, damage | sculpting | retopology, texture-workflow |
| Clean animation mesh | retopology | character-artist, creature-artist |
| UV seams, texel density, UDIM | uv-workflow | texture-workflow, materials |
| PBR, procedural shaders | materials | texture-workflow, lookdev |
| Baking, normal maps, atlases | texture-workflow | uv-workflow, materials |
| Lookdev / shading review loop | lookdev | materials, lighting, camera-cinematography, qa-review |
| Scatter, procedural systems | geometry-nodes | procedural-modeling, environment-artist |
| Mood, cinematic lighting | lighting | rendering, lookdev, horror-style |
| Camera, lenses, framing, camera moves | camera-cinematography | rendering, lighting, animation, compositing |
| Final renders, passes | rendering | lighting, materials, compositing |
| Compositor, grade, beauty stack | compositing | rendering, lookdev, vfx-fx |
| Smoke, fire, particles, cinematic FX | vfx-fx | geometry-nodes, physics-sim, materials, compositing |
| Rigid/soft body, destruction | physics-sim | vfx-fx, collision-proxy, animation |
| Walk cycles, mechanical motion | animation | rigging |
| Bones, IK, weight paint | rigging | animation, character-artist |
| Rocks, roads, cables, buildings (procedural) | procedural-modeling | geometry-nodes |
| Large scene layout, linking, overrides | scene-assembly | environment-artist, set-dressing, lighting |
| Prop placement, narrative clutter | set-dressing | prop-artist, scene-assembly, environment-artist |
| Archviz interiors/exteriors | archviz | materials, lighting, camera-cinematography, rendering |
| Polycount, cleanup | asset-optimization | lod-pipeline, export-pipeline, qa-review |
| LOD generation / validation | lod-pipeline | asset-optimization, unity-export, unreal-export |
| UCX / convex / collider proxies | collision-proxy | lod-pipeline, unreal-export, unity-export, physics-sim |
| Generic FBX/GLTF/USD export | export-pipeline | asset-optimization, qa-review |
| Unity-specific export | unity-export | export-pipeline, lod-pipeline, collision-proxy |
| Unreal-specific export | unreal-export | export-pipeline, lod-pipeline, collision-proxy |
| Godot-specific export | godot-export | export-pipeline, lod-pipeline, collision-proxy |
| QA gate, screenshot review, ship check | qa-review | asset-optimization, lookdev, blender-director |
| Psychological horror aesthetic | horror-style | lighting, environment-artist, set-dressing |
| Cosmic / Lovecraftian / eldritch | cosmic-eldritch-horror | horror-style, creature-artist, vfx-fx |
| Body horror / mutation | body-horror-style | horror-style, creature-artist, sculpting |
| Analog / VHS / found footage | analog-found-footage-horror | compositing, camera-cinematography, horror-style |
| Liminal / Backrooms / empty mall | liminal-space-style | environment-artist, horror-style, lighting |
| Folk horror / rural ritual | folk-horror-style | horror-style, vegetation-artist, set-dressing |
| Mascot / puppet horror | mascot-puppet-horror | horror-style, stop-motion-craft-style, character-artist |
| Dreamcore / weirdcore | dream-weirdcore-style | liminal-space-style, compositing |
| Indie horror refs (SH / FtF / Puppet Combo) | indie-horror-aesthetics | horror-style, psx-horror-style, lighting |
| PSX/PS1 horror crunch | psx-horror-style | horror-style, lowpoly-style, lighting, compositing |
| PS1/PS2, Lethal Company style | lowpoly-style | environment-artist, materials, visual-console-eras |
| Anime / cel / hard color breaks | anime-style | stylized-style, materials, rendering, character-artist |
| Manga value / screentone language | manga-style | anime-style, comic-book-style, compositing |
| Cartoon graphic shapes | cartoon-style | stylized-style, character-artist |
| Comic book / ink / halftone | comic-book-style | stylized-style, compositing |
| Pixel / texel-locked | pixel-art-style | retro-8bit-style, retro-16bit-style, hd-2d-style |
| HD-2D hybrid | hd-2d-style | pixel-art-style, environment-artist, lighting |
| Hand-painted textures | hand-painted-style | stylized-style, texture-workflow |
| Watercolor / oil painterly | painterly-style | hand-painted-style, compositing |
| Claymation / paper craft / stop-mo | stop-motion-craft-style | materials, character-artist |
| Chibi / SD proportions | chibi-style | anime-style, cartoon-style, character-artist |
| Noir / neo-noir | noir-style | lighting, camera-cinematography, compositing |
| Minimalist / abstract reduce | minimalist-style | stylized-style, lookdev |
| Vector-flat graphic | vector-style | minimalist-style, cartoon-style |
| Voxel / Minecraft-adjacent | voxel-style | lowpoly-style, environment-artist, geometry-nodes |
| Isometric / strategy / diorama | isometric-style | camera-cinematography, environment-artist, genre-strategy-sim |
| Frutiger Aero glossy 2000s | frutiger-aero-style | materials, lookdev, neon-retrofuturism |
| Neon / vaporwave / synthwave | neon-retrofuturism | sci-fi-punk-worlds, lighting, compositing |
| Cozy / cute / wholesome | cozy-wholesome-mood | stylized-style, lighting, set-dressing |
| Dark / gritty / decayed / industrial | dark-gritty-mood | horror-style, materials, environment-artist |
| Dreamlike / surreal / mystical | dream-surreal-mood | dream-weirdcore-style, lighting, vfx-fx |
| Brutalist concrete mood | brutalist-mood | archviz, environment-artist, materials |
| Fantasy / medieval / dark fantasy | fantasy-worlds | environment-artist, prop-artist, creature-artist |
| Sci-fi / cyberpunk / steampunk / punks | sci-fi-punk-worlds | hard-surface, environment-artist, vehicle-artist |
| Historical / western / samurai / WW | historical-worlds | environment-artist, prop-artist, character-artist |
| Post-apoc / dystopia / zombie | apocalypse-worlds | environment-artist, prop-artist, vehicle-artist |
| Underwater / desert / arctic / jungle | biome-worlds | environment-artist, vegetation-artist, lighting |
| Character race/role archetypes | character-archetypes | character-artist, creature-artist |
| PS1–PS5 / CRT / VHS / DOS eras | visual-console-eras | lowpoly-style, compositing, realistic-style |
| Action / brawler / fighting arenas | genre-action-combat | environment-artist, vfx-fx |
| FPS / TPS / BR / extraction | genre-shooter | environment-artist, hard-surface, collision-proxy |
| RPG / JRPG / CRPG / ARPG / MMO | genre-rpg | fantasy-worlds, environment-artist, character-artist |
| Survival / survival-horror gameplay | genre-survival | environment-artist, prop-artist, horror-style |
| Stealth spaces | genre-stealth | environment-artist, lighting |
| Puzzle / platformer | genre-puzzle-platformer | environment-artist, prop-artist |
| Metroidvania / roguelike / roguelite | genre-metroidvania-roguelike | environment-artist, scene-assembly |
| Soulslike monumental dread | genre-soulslike | dark-gritty-mood, fantasy-worlds, lighting |
| Strategy / sim / city / colony / MOBA | genre-strategy-sim | isometric-style, environment-artist |
| Racing / sports | genre-racing-sports | vehicle-artist, environment-artist |
| VN / walking sim / interactive movie | genre-narrative-vn | camera-cinematography, lighting, set-dressing |
| Card / party / idle / rhythm / edu | genre-card-party-idle | prop-artist, camera-cinematography |
| Open world / sandbox | genre-open-world-sandbox | biome-worlds, environment-artist, lod-pipeline |
| Exaggerated, NPR, hand-painted broad | stylized-style | materials, rendering, anime-style |
| Photoreal, scan cleanup, AAA PBR | realistic-style | texture-workflow, rendering, lookdev |
| **Reference photo / concept art attached** | **reference-image-match** | blender-director → discipline skill → style → materials → lighting → rendering |

## Reference Image Workflow (Mandatory)

When user provides a photo or render to match:

```
1. REFERENCE ANALYSIS  → reference-analysis-template.md (written, before MCP)
2. BASELINE SCREENSHOT → get_viewport_screenshot
3. CAMERA MATCH        → CAM_* + EMPTY_CamTarget_* before detailing
4. GEOMETRY TIERS      → silhouette → panel breaks → greebles
5. MATERIALS           → palette from reference; per-object emissive lights only
6. LIGHTING + WORLD    → key direction, rim, space/env mood
7. GRADING             → AgX exposure/look; EEVEE for animation preview
8. COMPARE LOOP        → screenshot → gap list → fix (×3 max)
9. VALIDATE            → visual-match-checklist.md
```

See `../references/reference-image-match.md` for full protocol and failure fixes.

## Production Brief Template

Output this before executing:

```markdown
## Production Brief: [Asset Name]

**Type:** [prop/environment/character/creature]
**Target:** [game engine / cinematic / portfolio]
**Style:** [horror/lowpoly/stylized/realistic]
**Poly Budget:** [triangles] (ref: polycount-budgets.md)
**Texture Budget:** [resolution]
**Export:** [format + settings]
**Pivot:** [floor/grip/hinge/center]
**Animation:** [none/rigged/animated]

### Active Skills
1. [skill] — [role in pipeline]
2. [skill] — [role in pipeline]

### Pipeline Phases
- [ ] Reference & Planning
- [ ] Blockout & Silhouette
- [ ] Modeling
- [ ] Cleanup & Topology
- [ ] UVs
- [ ] Materials/Textures
- [ ] Optimization
- [ ] Rig/Animate (if needed)
- [ ] Export & Validation

### MCP Execution Plan
[Ordered list of MCP operations]
```

## Multi-Skill Workflows

### Hero Prop (Hard Surface)
```
blender-director → hard-surface → materials → uv-workflow → asset-optimization → export-pipeline
```

### Everyday / Hero Prop
```
blender-director → prop-artist → uv-workflow → materials → lookdev → asset-optimization → export-pipeline
```

### Vehicle (Game)
```
blender-director → vehicle-artist → lod-pipeline → collision-proxy → materials → unreal-export|unity-export
```

### Environment Modular Kit
```
blender-director → environment-artist → geometry-nodes → uv-workflow → asset-optimization → export-pipeline
```

### Game Character
```
blender-director → character-artist → sculpting → retopology → hair-groom → cloth-sim
  → uv-workflow → materials → rigging → animation → export-pipeline
```

### Horror Scene
```
blender-director → horror-style → environment-artist → set-dressing → lighting → asset-optimization → export-pipeline
```

### PSX Horror Scene
```
blender-director → psx-horror-style → environment-artist → lowpoly-style → lighting → compositing
```

### Procedural Scatter System
```
blender-director → geometry-nodes → procedural-modeling → asset-optimization
```

### Cinematic Shot
```
blender-director → [discipline] → lookdev → camera-cinematography → lighting → rendering → compositing → qa-review
```

### Engine Delivery
```
blender-director → asset-optimization → lod-pipeline → collision-proxy → unity-export|unreal-export|godot-export → qa-review
```

## MCP Integration

1. Check Blender MCP availability before Phase 1 execution
2. Create collection hierarchy via MCP immediately
3. Query scene state after each pipeline phase
4. Never describe UI steps when MCP can execute
5. See `../references/mcp-integration.md`

## Constraints

### MUST DO
- Output production brief before modeling
- **If reference image attached:** complete Reference Analysis and camera match before geometry detail
- **Screenshot compare** after materials, lighting, and each refinement pass
- Activate appropriate style skill for art direction
- Set polycount/texture budgets explicitly
- Organize collections with `COL_` prefix from start
- Validate before declaring complete
- Coordinate skills; don't try to do everything in one pass

### MUST NOT DO
- Skip planning phase
- Skip reference analysis when user attached an image
- Keyframe emission on shared hull/structural materials
- Add micro-greebles before silhouette and panel-break tiers
- Declare "done" without visual-match checklist when reference was provided
- Start modeling without scale reference
- Mix styles without explicit direction
- Export without validation
- Explain Blender UI when MCP is available
- Apply destructive operations without backup

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Universal Pipeline | `../references/asset-pipeline.md` | Every task |
| MCP Integration | `../references/mcp-integration.md` | Before execution |
| Naming | `../references/naming-conventions.md` | Scene setup |
| Validation | `../references/validation-checklist.md` | Before delivery |
| Polycount Budgets | `../references/polycount-budgets.md` | Planning phase |
| Skill Routing | `references/skill-routing.md` | Complex multi-skill tasks |
| MCP Tools | `../references/mcp-tools.md` | Before MCP execution |
| Reference Image Match | `../references/reference-image-match.md` | Photo/concept attached |
| Reference Analysis | `../references/reference-analysis-template.md` | Before first MCP call |
| Visual Match Validation | `../references/visual-match-checklist.md` | Before delivery |

## Decision Trees

### Reference Image Provided?
```
User attached photo / concept / "match this"?
├── YES → reference-image-match.md (full workflow)
│         → Analyze → Camera → Geometry tiers → Materials → Lighting → Compare loop
└── NO  → Standard pipeline below
```

### New Asset Request
```
Is style specified?
├── Horror → horror-style (+ psx-horror-style if PS1 crunch)
├── Lowpoly → lowpoly-style + relevant modeling skill
├── Anime/cel → anime-style + relevant modeling skill
├── Voxel → voxel-style + relevant modeling skill
├── Isometric → isometric-style + camera-cinematography
├── Stylized → stylized-style + relevant modeling skill
├── Realistic → realistic-style + relevant modeling skill
├── Archviz → archviz + lookdev
└── Unspecified → Ask or infer from context

What is the asset?
├── Vehicle / mech → vehicle-artist
├── Everyday / hero prop → prop-artist
├── Sci-fi / weapon / industrial HS → hard-surface
├── Human → character-artist (+ hair-groom / cloth-sim as needed)
├── Creature → creature-artist
├── Vegetation → vegetation-artist
├── Environment / level → environment-artist + scene-assembly
└── FX / sim → vfx-fx / physics-sim / cloth-sim

Engine delivery?
├── Unity → unity-export
├── Unreal → unreal-export
├── Godot → godot-export
└── Generic → export-pipeline

Does it need animation?
├── Yes → Add retopology, rigging, animation
└── No → Static pipeline
```

## Knowledge Reference

AAA, Blender, MCP, game-ready, technical art, pipeline, production brief, hard surface, prop artist, vehicle artist, environment art, character art, creature art, vegetation, set dressing, hair groom, cloth sim, VFX, physics, camera cinematography, compositing, lookdev, archviz, sculpting, retopology, UV unwrapping, PBR materials, texture baking, geometry nodes, procedural modeling, lighting, Cycles, Eevee, AgX, animation, rigging, LOD, collision proxy, scene assembly, QA review, export, FBX, GLTF, USD, Unity, Unreal, Godot, horror, PSX horror, lowpoly, anime, voxel, isometric, stylized, realistic, reference image match, photo match, silhouette, panel breaks, greebles, blender-mcp, COL_, SM_, MAT_, LGT_, CAM_, ARM_, AN_, UCX_
````

### `references/skill-routing.md`

```markdown
# Skill Routing Reference

Extended routing tables for the Blender Director.

## By Engine Target

| Engine | Export Skill | Notes |
|--------|--------------|-------|
| Unity | unity-export | GLB/GLTF modern; FBX for humanoid/legacy |
| Unreal | unreal-export | FBX; UCX collision; verify cm scale |
| Godot | godot-export | GLTF/GLB preferred |
| Generic / multi | export-pipeline | Confirm axis and scale; then engine skill if known |

## By Production Phase

| Phase | Lead Skill | Validators |
|-------|------------|------------|
| Reference analysis | blender-director + reference-image-match | reference-analysis-template |
| Genre / style / world lock | matching genre/style/world/mood skill | production brief |
| Blockout | blender-modeler / discipline skill | blender-director |
| Detail pass | discipline skill | asset-optimization |
| UV pass | uv-workflow | texture-workflow |
| Look dev | lookdev + materials | style skill, qa-review |
| Camera / shot | camera-cinematography | rendering |
| FX / sim | vfx-fx / physics-sim / cloth-sim | compositing |
| Reference compare | rendering + lighting | visual-match-checklist |
| Scene layout | scene-assembly + set-dressing | qa-review |
| Performance | asset-optimization + lod-pipeline | collision-proxy |
| Delivery | unity-export / unreal-export / godot-export / export-pipeline | qa-review + validation-checklist |

## Style + Discipline Matrix (core)

|  | Hard Surface | Prop | Vehicle | Environment | Character | Creature |
|--|-------------|------|---------|-------------|-----------|----------|
| Horror | + horror-style | + horror-style | + horror-style | + horror-style | + horror-style | + horror-style |
| PSX Horror | + psx-horror-style | + psx-horror-style | + psx-horror-style | + psx-horror-style | + psx-horror-style | + psx-horror-style |
| Lowpoly | + lowpoly-style | + lowpoly-style | + lowpoly-style | + lowpoly-style | + lowpoly-style | + lowpoly-style |
| Anime | + anime-style | + anime-style | + anime-style | + anime-style | + anime-style | + anime-style |
| Voxel | + voxel-style | + voxel-style | + voxel-style | + voxel-style | + voxel-style | + voxel-style |
| Isometric | + isometric-style | + isometric-style | + isometric-style | + isometric-style | + isometric-style | + isometric-style |
| Stylized | + stylized-style | + stylized-style | + stylized-style | + stylized-style | + stylized-style | + stylized-style |
| Realistic | + realistic-style | + realistic-style | + realistic-style | + realistic-style | + realistic-style | + realistic-style |

Add world/mood/genre packs on top (e.g. `sci-fi-punk-worlds` + `neon-retrofuturism` + `genre-shooter`).

## Pack Routers (load references inside)

| Pack | Examples covered in refs |
|------|--------------------------|
| sci-fi-punk-worlds | hard sci-fi, space, cyber/steam/diesel/atom/solar/bio/clockpunk |
| fantasy-worlds | medieval, high/dark/urban fantasy |
| historical-worlds | western, pirate, samurai, viking, ancients, victorian, military |
| apocalypse-worlds | wasteland, zombie, dystopia/utopia, alien invasion |
| biome-worlds | underwater, desert, arctic, jungle, underground, floating islands |
| indie-horror-aesthetics | Silent Hill, Fear to Fathom, Puppet Combo, corporate, cabin/hospital/forest |
| character-archetypes | fantasy races, horror bodies, sci-fi bodies, role kits |
| visual-console-eras | PS1–PS5, CRT, VHS, DOS, arcade, film grain |
| painterly-style | watercolor, oil |
| stop-motion-craft-style | claymation, paper craft |
| genre-rpg | JRPG, CRPG, ARPG, MMORPG |
| genre-shooter | FPS, TPS, BR, extraction |
| genre-strategy-sim | RTS, TBS, TD, MOBA, city/colony/life/farming sim |

## Parallel vs Sequential

**Sequential (default):** Genre/style lock → Modeling → UV → Materials → Lookdev → Export

**Parallel allowed:**
- Material prototyping while UVs in progress (separate collections)
- Lighting setup while optimization runs on duplicate collection
- Collision proxies while LOD1+ generates
- Mood/world reference gathering during blockout

**Never parallel:**
- Retopology before sculpt complete
- Export before validation / qa-review
- Rigging before final topology locked
- Engine export before LOD/collision plan when required
```

## blender-modeler

- **Ruta:** `.claude/skills/blender-modeler`
- **Descripción:** Core Blender modeling specialist for Edit Mode, modifiers, collections, precision modeling, and scene organization. Use for general 3D modeling, blockouts, cleanup, non-destructive workflows, and scene structure in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: blender-modeler
description: Core Blender modeling specialist for Edit Mode, modifiers, collections, precision modeling, and scene organization. Use for general 3D modeling, blockouts, cleanup, non-destructive workflows, and scene structure in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: model, blockout, edit mode, modifier, collection, mesh, primitive, snap, pivot, scene organization
  related-skills: hard-surface, environment-artist, asset-optimization, uv-workflow
---

# Blender Modeler

Foundation modeling skill for all Blender geometry work. Non-destructive by default. MCP-first execution.

## When to Use

- Blockouts and primary/secondary shape passes
- General mesh editing not covered by discipline specialists
- Scene organization, collections, instances
- Modifier stack management
- Cleanup: merge, normals, loose geometry
- Precision modeling with snapping and numeric input

## Core Workflow

```
1. Scene Setup     → Collections, scale reference, naming
2. Blockout        → Primitives, mirror, array
3. Shape Refinement → Edit mode or modifier-based edits
4. Modifier Stack  → Non-destructive detail
5. Cleanup         → Merge, normals, manifold check
6. Handoff         → UV/materials or discipline specialist
```

## Scene Organization

Establish via MCP immediately:

```
COL_Project
├── COL_Reference      # Scale refs, ortho images
├── COL_Blockout       # Temporary blockout meshes
├── COL_Geo            # Final geometry
├── COL_Collision      # Proxy meshes
└── COL_Instances      # Empties/collections for instancing
```

Naming: `../references/naming-conventions.md`

## Modifier Stack Philosophy

Preferred order (bottom to top):

```
1. Mirror          # Symmetry
2. Array           # Repetition
3. Solidify        # Thickness
4. Boolean         # Cuts (prefer live booleans until export)
5. Bevel           # Edge detail
6. Weighted Normal # Hard surface shading
7. Subdivision     # Only when topology supports it
```

**Rules:**
- Keep booleans live until export prep
- Apply mirror only when topology is finalized
- Never stack multiple subsurf without supporting loops
- Document modifier purpose in object custom properties if complex

## Edit Mode Essentials

| Operation | Use When |
|-----------|----------|
| Extrude (E) | Adding depth from faces |
| Inset (I) | Panel lines, frames |
| Loop Cut (Ctrl+R) | Adding resolution |
| Knife (K) | Custom cuts |
| Merge by Distance | Cleanup duplicates |
| Recalculate Normals | Fix shading issues |

Via MCP: execute equivalent operations; don't narrate UI.

## Precision Modeling

- Enable snapping to grid/vertex/edge as appropriate
- Use numeric input for exact dimensions
- Set cursor to world origin for modular alignment
- Apply scale before boolean operations
- Use orthographic views for architectural accuracy

## Instancing Strategy

| Method | Use Case |
|--------|----------|
| Linked Duplicate (Alt+D) | Identical props with variation potential |
| Collection Instance | Modular kit pieces |
| Geometry Nodes | Procedural scatter (see geometry-nodes) |
| Array Modifier | Linear repetition |

Prefer instances over duplicate geometry for repeated elements.

## Custom Normals

- Enable Auto Smooth with appropriate angle (30°–60° hard surface)
- Weighted Normal modifier for hard surface without extra geo
- Mark sharp edges explicitly for bevel control
- Clear custom split normals before retopology handoff

## Cleanup Checklist

- [ ] Merge by distance (threshold: 0.0001m default)
- [ ] Remove loose geometry
- [ ] Delete interior faces
- [ ] Recalculate outside normals
- [ ] Apply scale if modifiers depend on it
- [ ] Verify manifold (no holes unless intentional)
- [ ] Check triangle count vs budget

## MCP Integration

```
1. Create mesh objects via MCP
2. Apply modifiers via MCP
3. Query polycount after each major edit
4. Organize into collections via MCP
5. Duplicate to backup collection before destructive ops
```

See `../references/mcp-integration.md`

## Constraints

### MUST DO
- Non-destructive workflow until export phase
- Name objects `SM_` prefix immediately
- Keep blockout separate from final geo
- Apply transforms before boolean/export
- Validate topology before handoff

### MUST NOT DO
- Delete blockout before silhouette approved
- Apply all modifiers prematurely
- Leave default names (Cube.001)
- Model without scale reference
- Skip cleanup pass

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Modifier deep dive | `references/modifier-stack.md` | Complex modifier chains |
| Scene organization | `references/scene-organization.md` | Large scenes |
| Pipeline | `../references/asset-pipeline.md` | Phase context |

## Handoff Points

| To Skill | When |
|----------|------|
| hard-surface | Mechanical/sci-fi detail pass |
| environment-artist | Modular environment pieces |
| character-artist | Organic human forms |
| uv-workflow | Topology locked, ready for UVs |
| asset-optimization | Pre-export performance pass |
````

### `references/modifier-stack.md`

````markdown
# Modifier Stack Reference

## Boolean Workflow

```
1. Ensure both operands have applied scale
2. Use exact/overlap solver for mechanical cuts
3. Keep boolean live; duplicate result for backup
4. Apply bevel AFTER boolean (bevel modifier below boolean in stack = wrong)
5. Correct order: Boolean → Bevel → Weighted Normal
```

## Bevel Settings

| Context | Width | Segments | Profile |
|---------|-------|----------|---------|
| Hard surface panel | 0.001–0.005m | 2–3 | 0.5 |
| Chamfer edge | 0.002–0.01m | 1–2 | 0.5 |
| Soft edge | 0.001m | 3–5 | 0.7 |

Limit bevel to marked edges or weight groups for control.

## Mirror Modifier

- Use bisect for half-model workflows
- Clip enabled to prevent center overlap
- Merge threshold: 0.001m default
- Apply only when center loop is clean

## Array Modifier

- Use constant offset for modular pieces
- Fit type: Fixed Count for known repetitions
- Merge vertices at array boundaries when seamless

## Subdivision Surface

- Only on quad-dominant topology
- Level 1 for preview, Level 2 max for hero assets
- Support loops required at hard edges
- Never subsurf boolean results without cleanup

## Common Stack Examples

**Modular wall panel:**
```
Mirror → Solidify → Bevel (weight) → Weighted Normal
```

**Repeated floor tile:**
```
Array → Bevel → Weighted Normal
```

**Blockout (temporary):**
```
Mirror → Array (no bevel yet)
```
````

### `references/scene-organization.md`

```markdown
# Scene Organization

## View Layers

| Layer | Contents |
|-------|----------|
| Default | Active modeling |
| Reference | Image planes, scale refs |
| Blockout | WIP blockout only |
| Final | Approved geometry |
| Export | Export-ready duplicates |

## Parenting Strategy

- Parent mechanical sub-parts to root empty: `SM_AssetName_Root`
- Keep pivot at functional point (hinge, grip, floor)
- Use constraints for mechanical relationships (see rigging skill)

## Asset Browser Integration

- Mark finished assets for reuse
- Tag by category: Prop, Env, Char, Weapon
- Include preview render in asset catalog

## Large Scene Management

- One collection per modular kit
- Instance collections, don't duplicate
- Hide blockout collections after approval
- Use collection colors for discipline identification

## Performance in Viewport

- Disable subdiv viewport levels during modeling
- Use wireframe overlay for topology review
- Hide high-poly sculpts when working on low-poly
```

## character-artist

- **Ruta:** `.claude/skills/character-artist`
- **Descripción:** AAA character modeling for human anatomy, stylization, facial topology, clothing, hair, and animation-ready meshes. Use for game characters, facial expressions, and production character assets in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: character-artist
description: AAA character modeling for human anatomy, stylization, facial topology, clothing, hair, and animation-ready meshes. Use for game characters, facial expressions, and production character assets in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: character, human, anatomy, face, facial, clothing, hair, body, edge loop, expression, portrait
  related-skills: sculpting, retopology, rigging, uv-workflow, materials
---

# Character Artist

Production character modeling with animation-ready topology. Anatomy-accurate or intentionally stylized.

## When to Use

- Human/humanoid character creation
- Facial topology for expressions
- Clothing and accessory modeling
- Hair card systems or stylized hair
- Character proportion and stylization

## Workflow

```
Reference → Proportion Blockout → Body Forms → Limb Connection
    → Facial Features → Edge Loop Planning → Detail Pass
    → Clothing (separate mesh) → UV Handoff → Rig Handoff
```

## Proportion Standards

| Type | Head Units | Notes |
|------|------------|-------|
| Realistic adult | 7.5–8 heads | Hero characters |
| Stylized | 4–6 heads | Exaggerated features |
| Heroic | 8–9 heads | Action games |

Always block proportions before detail.

## Edge Loop Strategy

Critical loop locations:
- Eyes: concentric loops for blink/expression
- Mouth: 3-loop minimum for lip deformation
- Jaw: loop following jaw line for open/close
- Shoulders: deltoid loop for arm raise
- Elbows/knees: 3-loop pinching pattern
- Hips: loop for leg spread

See `references/facial-topology.md` for face-specific loops.

## Facial Structure

- Eye socket: recessed; brow ridge defined
- Nose: bridge width matches inner eye distance (realistic)
- Mouth: lower lip fuller than upper (realistic)
- Ear: aligns eye brow to nose base
- Skull underlying forms visible in stylization

## Clothing Workflow

1. Model body first (or use mannequin)
2. Duplicate body faces for clothing base
3. Solidify/extrude for cloth thickness
4. Separate mesh: `SM_Char_[Name]_Body`, `SM_Char_[Name]_Cloth_[Piece]`
5. Cloth does NOT share UVs with body
6. Weight paint transfers from body (via rigging skill)

## Hair Approaches

| Method | Use Case | Skill |
|--------|----------|-------|
| Hair cards | Game-realistic | uv-workflow + texture-workflow |
| Strand curves | Cinematic | particle/curve systems |
| Stylized mesh | Lowpoly/stylized | blender-modeler |
| Sculpted | Hero bake | sculpting → retopology |

## Animation-Ready Requirements

- Quad-dominant topology on deformation zones
- No poles on primary deformation areas (relocate to hidden zones)
- Even edge length in face/neck/joints
- Separate objects for swap-able parts (head, hands, gear)

## MCP Integration

1. Create base mannequin/blockout via MCP
2. Build body with mirror modifier via MCP
3. Query topology (face count, edge flow) at checkpoints
4. Separate clothing meshes via MCP
5. Organize character collection hierarchy

## Constraints

### MUST DO
- Establish proportions before facial detail
- Plan edge loops for planned deformations
- Separate clothing/accessories as unique meshes
- Match style skill direction (stylized vs realistic)
- Validate topology before rigging handoff

### MUST NOT DO
- Triangles on primary deformation surfaces
- Poles at corner of mouth or inner eye
- Single mesh for body + hard surface armor (separate)
- Skip reference for facial likeness work
- Over-poly face before LOD planning

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Facial topology | `references/facial-topology.md` | Face modeling |
| Body proportions | `references/body-proportions.md` | Blockout |
| Pipeline | `../references/asset-pipeline.md` | Phase context |

## Style Integration

| Style | Adjustment |
|-------|------------|
| realistic-style | Full anatomy; 8-head proportion |
| stylized-style | Exaggerated features; 4–5 heads |
| lowpoly-style | Minimal loops; painted detail |
| horror-style | Uncanny proportions; asymmetry |
````

### `references/body-proportions.md`

```markdown
# Body Proportions

## Realistic (8 heads)

| Landmark | Head units from top |
|----------|---------------------|
| Chin | 1 |
| Nipples | 2 |
| Navel | 3 |
| Crotch | 4 |
| Mid-thigh | 5 |
| Knee | 6 |
| Mid-shin | 7 |
| Floor | 8 |

## Stylized (4–5 heads)

Exaggerate head size; simplify limb taper. Hands/feet may be larger for readability.

## Width

- Shoulders: 2–2.5 head widths (male heroic)
- Hips: 1.5–2 head widths
- Arm reach: fingertips to mid-thigh when at sides
```

### `references/facial-topology.md`

````markdown
# Facial Topology

## Eye Region

```
Minimum loops for blink:
- Upper lid: 2 loops above lash line
- Lower lid: 1–2 loops
- Orbital: 1 loop around entire eye socket
- Brow: 2 loops above eye for expression
```

Avoid 3-pole at inner eye corner — redirect to nose bridge.

## Mouth Region

```
Minimum for lip sync:
- Upper lip: 3 loops
- Lower lip: 3 loops
- Lip corner: dedicated loop running to jaw
- Nasolabial: loop from nose wing to chin
```

## Nose

- Bridge loop runs to forehead
- Nostril: enclosed loop (not open-ended triangle fan)
- Tip: radial loops for subtle animation

## Ear

- Helix: continuous loop following rim
- Inner detail: separate island topology acceptable (non-deforming)

## Expression Requirements

| Expression | Required Loops |
|------------|----------------|
| Smile | Mouth corner loops + cheek |
| Frown | Brow inner loops |
| Blink | Eyelid loops |
| Jaw open | Jaw loop + chin loop separation |

## Pole Placement (Face)

Acceptable pole locations:
- Top of head (under hair)
- Back of neck
- Inside mouth (hidden)

Never at: inner eye corner, center of lip, tip of nose.
````

## collision-proxy

- **Ruta:** `.claude/skills/collision-proxy`
- **Descripción:** Collision proxy authoring for games including UCX/UHX naming, convex hulls, capsules, and simple collider meshes in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: collision-proxy
description: Collision proxy authoring for games including UCX/UHX naming, convex hulls, capsules, and simple collider meshes in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: collision, collider, UCX, UHX, convex hull, physics proxy, hitbox, blocking volume
  related-skills: lod-pipeline, unity-export, unreal-export, asset-optimization, physics-sim
---

# Collision Proxy

Simple, stable colliders. Prefer primitives and convex pieces over render mesh.

## When to Use

- Game physics / blocking volumes
- Unreal UCX export
- Unity mesh or primitive colliders
- Hitboxes for interactables

## Workflow

```
Identify collision needs → Build proxies → Name correctly
  → Test overlaps → Export with render mesh
```

## Collider Types

| Type | Use |
|------|-----|
| Box | Crates, walls, simple props |
| Capsule | Characters, poles |
| Sphere | Balls, soft approximates |
| Convex hull | Organic / irregular single body |
| Multiple convex (UCX) | Vehicles, complex props |

## Unreal Naming

```
UCX_SM_Asset_01
UCX_SM_Asset_02
```

- Must match associated mesh naming rules for auto-association
- Convex only for UCX

## Unity Notes

- Prefer engine primitives when possible
- Mesh colliders: convex toggle for dynamic rigidbodies
- Keep proxy collection exportable

## Authoring Rules

1. Slightly smaller than visual mesh to reduce snagging (project-dependent)
2. No holes; watertight convex pieces
3. Apply scale
4. Origin aligned with render mesh
5. Collection: `COL_Collision_[Asset]`

## Validation

- [ ] Player cannot fall through intended blockers
- [ ] No huge invisible walls beyond mesh
- [ ] Wheel/character capsules oriented correctly
- [ ] Named for target engine

## Constraints

### MUST DO
- Prefer few simple shapes over one complex mesh
- Match engine naming conventions
- Keep proxies in dedicated collection

### MUST NOT DO
- Use render LOD0 as physics mesh by default
- Non-convex UCX for Unreal auto-convex workflows

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|----------|
| Collider Recipes | `references/collider-recipes.md` | When needed |
| Engine Naming | `references/engine-naming.md` | When needed |
````

### `references/collider-recipes.md`

```markdown
# Collider Recipes

| Asset | Recipe |
|-------|--------|
| Crate | 1 box |
| Chair | seat box + 4 leg capsules/boxes |
| Character | capsule |
| Stairs | box per step or ramp approx |
| Vehicle | 3–8 convex pieces |
| Door | thin box |

Slightly inset from render mesh when snagging is an issue.
```

### `references/engine-naming.md`

```markdown
# Engine Collision Naming

| Engine | Pattern |
|--------|---------|
| Unreal | `UCX_SM_Name_##` |
| Unity | `COL_` meshes or primitives in prefab |
| Godot | `COL_` / collision shapes on StaticBody |
```

## creature-artist

- **Ruta:** `.claude/skills/creature-artist`
- **Descripción:** AAA creature modeling for fantasy, aliens, monsters, and organic creature design with believable anatomy and movement. Use for creature blockouts, muscle flow, bone structure, and animation-ready creature assets in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: creature-artist
description: AAA creature modeling for fantasy, aliens, monsters, and organic creature design with believable anatomy and movement. Use for creature blockouts, muscle flow, bone structure, and animation-ready creature assets in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: creature, monster, alien, fantasy, dragon, beast, organic design, muscle, anatomy, fauna
  related-skills: sculpting, retopology, rigging, character-artist
---

# Creature Artist

Believable creature design grounded in anatomy. Movement-informed topology. Fantasy with physical plausibility.

## When to Use

- Fantasy creatures, monsters, aliens
- Quadrupeds, flying creatures, aquatic forms
- Hybrid designs (part animal, part mechanical)
- Boss creatures, enemies, companions

## Design Principles

1. **Anatomy grounding** — Even fantasy references real biology
2. **Silhouette first** — Unique readable shape
3. **Movement logic** — Skeleton supports intended motion
4. **Muscle flow** — Surface forms follow underlying structure
5. **Storytelling** — Design communicates behavior (predator/prey/scavenger)

## Workflow

```
Reference → Skeleton Blockout → Muscle Masses → Surface Forms
    → Detail (sculpt or model) → Retopology → Rig → Animation Test
```

## Creature Types

| Type | Skeleton Base | Key Forms |
|------|---------------|-----------|
| Quadruped | Dog/horse reference | Shoulder hump, haunches |
| Biped | Human/primate | Upright spine, heel plant |
| Flying | Bat/bird | Wing membrane, keel chest |
| Aquatic | Fish/shark | Lateral line, fin placement |
| Serpentine | Snake | Ribcage segmentation |
| Insectoid | Arthropod | Segmented body, jointed legs |

## Muscle Flow

- Origin → Insertion direction visible in surface
- Flexed areas: compressed forms, overlapping skin
- Extended areas: stretched, thinner surface
- Fat deposits: soft transitions (belly, cheeks)
- Scars/armor: break muscle flow intentionally

## Bone Structure Planning

Before surface modeling:
1. Place joint locations (spine segments, limbs)
2. Verify range of motion at each joint
3. Ensure limb attachment supports gait cycle
4. Head/neck connection supports attack/look poses

## Surface Detail Tiers

| Tier | Detail | Method |
|------|--------|--------|
| Primary | Overall mass | Blockout/sphere modeling |
| Secondary | Muscle groups | Sculpt or extrusion |
| Tertiary | Skin folds, veins | Sculpt |
| Micro | Scales, pores, scars | Sculpt + bake to normal |

## Hybrid Creatures

Mechanical + organic:
- Separate meshes: `SM_Creature_Bio`, `SM_Creature_Mech`
- Hard surface joints at organic/mechanical transition
- Rig: mechanical parts use constraints; organic uses weights

## MCP Integration

1. Create skeleton blockout (armature or mesh guides) via MCP
2. Build primary masses with mirror/sphere modeling
3. Hand off to sculpting for detail pass
4. Query proportions against reference scale figure
5. Organize bio/mechanical collections separately

## Constraints

### MUST DO
- Reference real anatomy even for fantasy
- Test silhouette from gameplay camera angle
- Plan rig joints during blockout
- Separate hero detail from background creatures
- Retopologize before rigging

### MUST NOT DO
- Design without movement consideration
- Uniform detail density (hero face/feet get more)
- Skip retopology on sculpted creatures
- Ignore polycount tier (background vs boss)
- Attach limbs without joint clearance

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Quadruped anatomy | `references/quadruped-anatomy.md` | Four-legged creatures |
| Flying creatures | `references/flying-creatures.md` | Wings, flight |
| Pipeline | `../references/asset-pipeline.md` | Phase context |

## Style Integration

| Style | Approach |
|-------|----------|
| realistic-style | Grounded anatomy; PBR skin |
| stylized-style | Exaggerated features; bold shapes |
| lowpoly-style | Minimal surface; texture detail |
| horror-style | Uncanny proportions; exposed anatomy |
````

### `references/flying-creatures.md`

```markdown
# Flying Creatures

## Wing Anatomy

Bird/bat/dragon wings are modified forelimbs:

| Segment | Bird | Bat | Dragon (fantasy) |
|---------|------|-----|------------------|
| Arm | Short | Long | Variable |
| Forearm | Fused | Elongated | Elongated |
| Hand/fingers | Fused tips | Spread membrane | Multi-finger spread |
| Membrane | Feathers | Skin | Skin or feather hybrid |

## Attachment Point

Wing root at shoulder/upper spine junction.
Large pectoral mass on chest (flight muscles).

## Folded vs Extended

Model both states or ensure topology supports fold:
- Folded: wing along body flank
- Extended: wingspan 2–3× body length (bird), 3–5× (dragon)

## Membrane Topology

Stretch direction: arm → wing tip.
Edge loops run span-wise, not chord-wise.

## Rigging

- 3–5 bones per wing (arm, forearm, finger splits)
- IK target at wing tip for pose control
- Limit rotation on fold axis

## Flight Pose Reference

- Downstroke: wings below body plane
- Upstroke: wings above; body hangs
- Gliding: wings extended, slight dihedral angle

## Silhouette

Wingspan defines creature read at distance — prioritize wing shape over body detail.
```

### `references/quadruped-anatomy.md`

```markdown
# Quadruped Anatomy

## Skeleton Landmarks

| Landmark | Position |
|----------|----------|
| Shoulder (scapula) | Upper chest; no collarbone |
| Elbow | Points backward (unlike human) |
| Wrist | Low; "front knee" is actually wrist |
| Hip | Pelvis horizontal |
| Stifle | True knee; bends forward |
| Hock | Ankle equivalent; bends backward |

## Mass Distribution

- 60% mass forward of hips for predators (shoulders heavy)
- 60% mass rear for prey animals (haunches heavy)
- Spine flexes horizontally (side-to-side gallop)

## Proportions by Type

| Type | Leg Length | Neck | Reference |
|------|------------|------|-----------|
| Canine | Medium | Medium | Dog/wolf |
| Feline | Medium | Short | Lion/panther |
| Equine | Long | Long | Horse |
| Ursine | Short | Short | Bear |

## Surface Flow

- Shoulder mass overlaps ribcage
- Hip haunch peaks above spine line
- Neck connects at shoulder angle, not vertical

## Rigging Notes

- Spine: 4–6 segments for gallop flex
- Tail: chain of 4–8 bones
- Front "knee" bends backward visually — actually wrist joint

## Polycount Zones

More density: head, shoulders, hips.
Less density: belly, inner legs (hidden).
```

## environment-artist

- **Ruta:** `.claude/skills/environment-artist`
- **Descripción:** AAA environment art for modular kits, buildings, terrain, vegetation, architecture, and scene composition. Use for game-optimized environments, storytelling through space, and modular asset pipelines in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: environment-artist
description: AAA environment art for modular kits, buildings, terrain, vegetation, architecture, and scene composition. Use for game-optimized environments, storytelling through space, and modular asset pipelines in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: environment, modular kit, building, terrain, vegetation, architecture, interior, exterior, level art, scene composition
  related-skills: geometry-nodes, procedural-modeling, materials, lighting
---

# Environment Artist

Modular, scalable environment production for games. Storytelling through space. Performance-conscious.

## When to Use

- Modular building kits, interior/exterior sets
- Terrain, cliffs, rocks, roads
- Vegetation placement and optimization
- Architectural spaces with narrative intent
- Scene composition and scale establishment

## Core Principles

1. **Modularity** — Pieces snap to grid; reusable across scenes
2. **Storytelling** — Environment communicates history and mood
3. **Scale** — Human reference always present
4. **Performance** — Instancing, LODs, texture atlases
5. **Composition** — Guide player eye with shapes and value

## Modular Kit Workflow

```
Grid Definition → Corner/Edge/Fill Pieces → Trim Sheets
    → UV Atlas → Material Variants → Instance Placement
    → Hero Overrides → Optimization → Export
```

## Grid Standards

| Kit Type | Grid Unit | Snap |
|----------|-----------|------|
| Interior walls | 2m or 4m | 0.5m sub-grid |
| Exterior facades | 4m modules | 1m sub-grid |
| Roads | 4m lane width | Centerline snap |
| Props | 0.5m | Free placement |

Name modules: `SM_Env_[Type]_[Role]_[Size]`
Example: `SM_Env_Wall_Corner_2m`

## Kit Piece Categories

| Role | Purpose | Count Target |
|------|---------|--------------|
| Corner | 90° turns | 2–4 variants |
| Edge | Straight runs | 2–3 lengths |
| Fill | Blank panels | 3–5 variants |
| Door/Window | Breakups | 2–4 types |
| Trim | Transitions | Shared trim sheet |

## Terrain & Natural Forms

- Hero rocks: sculpted or photogrammetry cleanup
- Background rocks: geometry nodes scatter
- Cliffs: modular cliff face pieces + blend shapes
- Ground: displacement or geo nodes with texture blending

## Vegetation

| Type | Approach | Poly Budget |
|------|----------|-------------|
| Hero tree | Hand model + cards | 5k–15k tris |
| Mid tree | Simplified + impostor LOD | 2k–5k tris |
| Bush | Cards + cluster | 500–2k tris |
| Grass | Cards or geo nodes scatter | 2–50 tris per blade |

Use geometry nodes for scatter; see geometry-nodes skill.

## Architecture

**Interior:**
- Ceiling height: 2.4m–3.5m standard
- Door: 2.1m × 0.9m
- Window sill: 0.9m from floor
- Corridors: minimum 1.5m playable width

**Exterior:**
- Floor count readable in silhouette
- Roof forms distinguish building type
- Weathering tells climate story

## Composition Guidelines

- **Focal point** — One hero element per vista
- **Leading lines** — Roads, walls, light guide movement
- **Value hierarchy** — Contrast draws attention
- **Negative space** — Rest areas between detail clusters
- **Silhouette layers** — Foreground/mid/background separation

## Storytelling Details

| Detail | Narrative Signal |
|--------|------------------|
| Peeling paint | Neglect, age |
| Barricades | Conflict, danger |
| Personal items | Former inhabitants |
| Damage patterns | Event history |
| Lighting state | Occupied vs abandoned |

## Game Optimization

- Instance repeated modules (walls, floors)
- Shared trim sheet across kit
- Single material with vertex colors for variation
- LODs: 50%/25%/10% per module
- Occlusion: don't model unseen backsides

## MCP Integration

1. Create modular pieces with exact dimensions via MCP
2. Set up collection instances for kit preview
3. Scatter vegetation via geometry nodes (MCP)
4. Query total scene polycount
5. Organize export collections by kit type

## Constraints

### MUST DO
- Design for grid snapping from blockout
- Create minimum viable kit before hero pieces
- Use instancing for all repeated geometry
- Maintain consistent texel density across kit
- Include scale reference human figure

### MUST NOT DO
- Unique geometry for every wall segment
- Ignore backface culling opportunities
- Over-detail background-only areas
- Mix grid sizes within same kit
- Skip LOD planning

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Modular kit design | `references/modular-kits.md` | Kit creation |
| Composition | `references/composition.md` | Scene layout |
| Pipeline | `../references/asset-pipeline.md` | Phase context |

## Style Integration

| Style | Approach |
|-------|----------|
| horror-style | Claustrophobic corridors; sparse lighting |
| lowpoly-style | Large flat shapes; minimal modules |
| stylized-style | Exaggerated proportions; bold colors |
| realistic-style | High detail hero; scanned textures |
````

### `references/composition.md`

````markdown
# Environment Composition

## Layer Structure

| Layer | Content | Detail Level |
|-------|---------|--------------|
| Foreground | Framing elements | Medium |
| Midground | Gameplay/interaction | Hero |
| Background | Skyline/fog silhouettes | Low |

## Leading Lines

Use roads, rivers, walls, light shafts to guide eye toward:
- Objective marker
- Threat reveal
- Narrative focal point

## Rule of Thirds

Place hero elements at intersection points.
Horizon on upper or lower third — not center (unless symmetrical intent).

## Value Hierarchy

Brightest area = player attention target.
Darkest area = concealment or negative space.
Avoid uniform brightness across vista.

## Scale Cues

Include known-size objects:
- Doors (2.1m)
- Human figure (1.7m)
- Vehicles
- Furniture

## Negative Space

Rest areas between detail clusters prevent visual fatigue.
Horror: increase negative space for tension.

## Modular Scene Assembly

```
1. Block terrain/ground plane
2. Place hero modular structures
3. Add midground props (instanced)
4. Background low-poly silhouettes + fog
5. Validate from player camera height/path
```

## Camera Path Validation

Walk player path in viewport at eye height (1.6m).
Check readability every 10m of travel.
````

### `references/modular-kits.md`

````markdown
# Modular Kit Design

## Minimum Viable Kit

Before hero pieces, ship:

| Piece | Quantity |
|-------|----------|
| Straight wall (2m) | 2 variants |
| Corner 90° | 2 (L + R or mirror) |
| Door frame | 1 |
| Window frame | 1–2 |
| Floor tile | 1 |
| Ceiling tile | 1 |

## Snap Point Convention

- Origin at grid corner (floor level)
- Positive Y = forward face (outward normal)
- Connection points at grid intersections
- Document snap grid in export README

## Trim Sheet Layout

```
[Corner trim | Edge trim | Fill panel | Window surround | Damage variants]
```

Shared 2048 trim sheet across entire kit.

## Variation Without Unique Geo

- Vertex color tints
- Material instance parameters
- Decal overlays
- 90° rotation of asymmetric pieces

## Kit Validation

Assemble test scene:
- Closed room from kit only
- L-shaped corridor
- T-junction
- Verify no gaps at 0.001m tolerance
````

## export-pipeline

- **Ruta:** `.claude/skills/export-pipeline`
- **Descripción:** Production export from Blender to FBX, GLTF, OBJ, USD, and Alembic with scale, pivot, rotation, normals, materials, animation, and collision verification via MCP.
- **Archivos incluidos:** 2

### `SKILL.md`

````markdown
---
name: export-pipeline
description: Production export from Blender to FBX, GLTF, OBJ, USD, and Alembic with scale, pivot, rotation, normals, materials, animation, and collision verification via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: export, FBX, GLTF, GLB, OBJ, USD, Alembic, Unity, Unreal, game engine import
  related-skills: asset-optimization, blender-modeler, materials
---

# Export Pipeline

Verified, engine-ready exports. Correct scale, axis, pivots, and data.

## When to Use

- Final asset delivery
- Engine import preparation
- Animation/rig export
- Batch export of modular kits

## Pre-Export Gate

**Required:** asset-optimization validation PASS before export.

## Workflow

```
Validation PASS → Export Settings → Test Export → Engine Verify
    → Fix Issues → Final Export → Documentation
```

## Format Selection

| Format | Best For |
|--------|----------|
| FBX | Unreal, Unity (legacy), animation |
| GLTF/GLB | Web, Godot, modern Unity |
| OBJ | Static mesh interchange (no rig) |
| USD | Pipelines, VFX, multi-asset |
| Alembic | VFX caches, sculpt animation |

## FBX Settings (Game Default)

```
Scale: 1.0
Apply Scalings: FBX All
Forward: -Z Forward
Up: Y Up
Apply Unit: ON
Mesh: ON
Armature: ON (if rigged)
Bake Animation: ON (if animated)
Path Mode: Copy (embed textures)
```

## GLTF Settings

```
Format: GLB (single file) or GLTF Separate
Include: Selected Objects
Transform: +Y Up
Compression: Draco (if supported by engine)
```

## Export Verification Matrix

| Check | Method |
|-------|--------|
| Scale | Measure known dimension in engine |
| Pivot | Verify floor contact / grip point |
| Forward axis | Compare to engine convention |
| Normals | Check shading in engine |
| Materials | Verify slot count and textures |
| Animation | Play action in engine |
| Collision | Import COL_ mesh separately |

## Engine-Specific Notes

### Unreal Engine
- Scale 1.0 = 1cm in UE (confirm project; may need 0.01 export scale)
- Import normals and tangents
- Separate collision mesh import
- LOD naming for auto-LOD: `SM_Asset_LOD0`

### Unity
- Scale 1.0 typically correct
- GLTF preferred for modern pipelines
- Humanoid rig mapping for characters

### Godot
- GLTF/GLB preferred
- +Y up default

## Collision Export

```
1. Export render mesh separately from collision
2. Collision: simple convex or box
3. Name: SM_Asset_COL
4. No materials on collision mesh
5. Apply transforms before export
```

## Animation Export

- Single action per export file (or document action list)
- Sample rate: 30fps default
- Bake constraints before export
- Include armature + skinned mesh in same file
- No unapplied scale on rig

## Batch Export (Modular Kits)

```
1. Select COL_Export collection
2. Export each module OR combined atlas per project spec
3. Maintain consistent origin per module type
4. Document grid snap points in README
```

## MCP Integration

1. Select export collection via MCP
2. Configure export settings via MCP
3. Execute export via MCP
4. Verify output file exists
5. Log export settings in delivery documentation

## Delivery Documentation Template

```markdown
## Export Package: [Asset Name]

**Format:** FBX / GLTF
**Scale:** 1 Blender unit = 1 meter
**Forward:** -Y / +X (document actual)
**Files:**
- SM_Asset.fbx
- T_Asset_BC.png, T_Asset_N.png, ...

**Import Notes:**
- [Engine-specific steps]

**Validation:** PASS — [date]
```

## Constraints

### MUST DO
- Pass asset-optimization before export
- Apply transforms on export objects
- Test import in target engine
- Document scale and axis conventions
- Export collision separately for games

### MUST NOT DO
- Export with unapplied scale
- Export without validation
- Mix collision and render in same export without documentation
- Assume default FBX settings work for all engines
- Export all modifiers without testing engine result

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Engine import | `references/engine-import.md` | First import test |
| Validation | `../references/validation-checklist.md` | Pre-export gate |
````

### `references/engine-import.md`

```markdown
# Engine Import

## Unreal Engine 5

1. Import FBX with Combine Meshes off for modular
2. Import Normals: Import Normals and Tangents
3. Transform: Verify scale — may need 0.01 if Blender 1m = UE 1cm
4. Materials: Create Material Instances from imported slots
5. Collision: Import `SM_*_COL` as UCX/UBX

## Unity

1. GLTF or FBX import
2. Scale Factor: 1 (verify)
3. Generate Lightmap UVs if not provided
4. Humanoid rig: Configure Avatar mapping

## Godot 4

1. GLB preferred
2. Root scale 1.0
3. Materials: StandardMaterial3D from PBR textures

## First Import Test Checklist

- [ ] Known dimension matches (door = 2m)
- [ ] Normals correct (no black faces)
- [ ] Textures assigned
- [ ] Pivot at expected location
- [ ] Animation plays (if rigged)
```

## genre-action-combat

- **Ruta:** `.claude/skills/genre-action-combat`
- **Descripción:** Art direction for action, hack-and-slash, beat 'em up, and fighting-game readable combat spaces and prop language in Blender.
- **Archivos incluidos:** 2

### `SKILL.md`

```markdown
---
name: genre-action-combat
description: Art direction for action, hack-and-slash, beat 'em up, and fighting-game readable combat spaces and prop language in Blender.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: action game, hack and slash, beat em up, brawler, fighting game, combat arena, action adventure
  related-skills: environment-artist, prop-artist, camera-cinematography, vfx-fx
---

# Genre: Action / Combat

Readable arenas. Attack silhouettes. Breakables clear. Camera-friendly volumes.
```

### `references/combat-readability.md`

```markdown
# Combat Readability
Clear floors, contrasting enemy silhouettes, destructibles budgeted, verticality telegraphed, no camouflage clutter on playable path.
```

## hard-surface

- **Ruta:** `.claude/skills/hard-surface`
- **Descripción:** AAA hard surface modeling for sci-fi, industrial, military, vehicles, weapons, robotics, and mechanical props. Use for boolean/bevel workflows, panel lines, greebles, chamfers, and manufacturing-accurate surfaces in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: hard-surface
description: AAA hard surface modeling for sci-fi, industrial, military, vehicles, weapons, robotics, and mechanical props. Use for boolean/bevel workflows, panel lines, greebles, chamfers, and manufacturing-accurate surfaces in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: hard surface, sci-fi, industrial, military, vehicle, spaceship, weapon, robot, machinery, boolean, bevel, panel line, greeble, mechanical
  related-skills: blender-modeler, materials, uv-workflow, asset-optimization, vehicle-artist, prop-artist
---

# Hard Surface Artist

Production hard surface modeling with manufacturing logic. Readable surfaces. Clean modifier stacks. MCP-first.

## When to Use

- Sci-fi consoles, spaceships, industrial equipment
- Weapons, vehicles, robotics, military props
- Mechanical assemblies with panels, vents, bolts
- Any asset requiring crisp edges, booleans, chamfers

## Design Principles

1. **Primary forms first** — Silhouette reads at distance
2. **Manufacturing logic** — Panel breaks follow construction seams
3. **Surface hierarchy** — Primary > Secondary > Tertiary > Micro (greebles)
4. **Functional readability** — Every form suggests purpose
5. **Edge consistency** — Uniform bevel widths per detail tier

## Workflow

```
Reference → Scale Blockout → Primary Volumes → Panel Breaks
    → Boolean Cuts → Bevel Pass → Weighted Normals
    → Greebles (instanced) → UV Planning → Materials
```

## Boolean Workflow

```
1. Block primary forms (no booleans yet)
2. Create cutter objects on separate collection COL_Booleans
3. Apply scale on all operands
4. Boolean Difference/Union — keep LIVE
5. Fix intersection artifacts with manual cleanup if needed
6. Bevel AFTER boolean in modifier stack
7. Apply booleans only at export prep
```

**Boolean rules:**
- Cutter objects named `SM_Cutter_[Feature]`
- Prefer exact solver for mechanical work
- Avoid booleans on curved surfaces without adequate topology
- Duplicate mesh before first boolean as backup

## Bevel Workflow

| Detail Tier | Bevel Width | Segments |
|-------------|-------------|----------|
| Primary edges | 0.005–0.02m | 2–3 |
| Panel lines | 0.001–0.003m | 1–2 |
| Micro detail | 0.0005–0.001m | 1 |

- Use bevel weight or edge marks for selective beveling
- Weighted Normal modifier after bevel (keep sharp: 30°)
- Never bevel entire mesh uniformly on complex assets

## Panel Lines

Techniques (prefer non-destructive):
1. Inset faces + slight extrude inward
2. Knife cuts on flat panels
3. Boolean with thin cutter boxes
4. Normal map detail for distant panels

Place panel lines at:
- Structural boundaries
- Access hatches, maintenance points
- Material transitions
- Manufacturing seam locations

## Greebles

- Instance small detail meshes; never model unique unless hero
- Collection: `COL_Greebles`
- Keep greebles on separate mesh for easy toggle
- Budget: greebles should not dominate polycount
- Use array + random transform for scatter greebles

## Hard Edge Management

```
Sharp edges → Mark Sharp or Bevel Weight = 1.0
Soft transitions → Bevel Weight = 0.0–0.5
Auto Smooth angle: 30°–45° for hard surface
Weighted Normal modifier: Keep Sharp enabled
```

## Manufacturing Reference

| Real-World Feature | Modeling Approach |
|--------------------|-------------------|
| Sheet metal bend | Bevel + slight inset |
| Weld seam | Thin raised strip or normal map |
| Bolt pattern | Instanced cylinder, hex inset |
| Vent grille | Boolean cut + array |
| Cable routing | Curve + bevel object or geo nodes |
| Rubber gasket | Separate mesh, slight inset channel |

## Vehicle / Spaceship Specifics

> Prefer **vehicle-artist** for cars, ships, aircraft, and mechs. Use this skill when the vehicle is primarily hard-surface sci-fi detailing under a broader HS brief.

- Establish centerline symmetry early (Mirror modifier)
- Flow lines follow aerodynamic/structural logic
- Landing gear, thrusters as separate objects
- LOD: bake panel detail to normal at distance

## Weapon Specifics

- Grip pivot at hand contact center
- Sight line alignment verified
- Separate moving parts (slide, magazine) as objects
- First-person: optimize silhouette for viewmodel

## MCP Integration

Execute via MCP:
1. Create blockout primitives
2. Apply mirror/array modifiers
3. Execute boolean operations
4. Apply bevel and weighted normal
5. Instance greeble collections
6. Query polycount per phase

## Constraints

### MUST DO
- Maintain manufacturing plausibility
- Keep modifier stack non-destructive until export
- Use instancing for repeated mechanical detail
- Verify silhouette at 45° increments
- Apply scale before booleans

### MUST NOT DO
- Boolean on unsubdivided curved surfaces without support
- Uniform bevel on entire complex mesh
- Model every bolt uniquely
- Skip weighted normals on hard surface
- Exceed polycount budget with micro-detail

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Boolean deep dive | `references/boolean-workflow.md` | Complex cuts |
| Greeble library | `references/greeble-patterns.md` | Detail pass |
| Pipeline | `../references/asset-pipeline.md` | Phase context |

## Style Integration

| Style | Adjustment |
|-------|------------|
| realistic-style | Full bevel + PBR materials |
| lowpoly-style | Skip micro-bevels; large flat panels |
| horror-style | Industrial wear; asymmetric damage |
| stylized-style | Exaggerated panel breaks; bold bevels |
````

### `references/boolean-workflow.md`

````markdown
# Boolean Workflow

## Solver Selection

| Solver | Use When |
|--------|----------|
| Exact | Mechanical, precision cuts (default) |
| Float | Legacy; avoid unless compatibility needed |

## Common Artifacts & Fixes

| Artifact | Fix |
|----------|-----|
| Z-fighting faces | Merge by distance; manual face cleanup |
| Missing faces | Increase cutter overlap; check normals |
| Ngons at intersection | Convert to quads with loop cuts |
| Shading breaks | Weighted normals; mark sharp edges |

## Cutter Best Practices

- Cutter extends past target mesh on all axes
- Cutter has clean manifold geometry
- Apply scale on cutter before boolean
- Keep cutters in `COL_Booleans` collection (hidden in render)

## Stack Order

```
Correct:  Mirror → Boolean → Bevel → Weighted Normal
Wrong:    Bevel → Boolean (bevel will be destroyed)
```

## Batch Boolean Strategy

For multiple panel cuts:
1. Combine cutters with Boolean Union first (separate object)
2. Single Boolean Difference against target
3. Reduces stack depth and artifacts
````

### `references/greeble-patterns.md`

````markdown
# Greeble Patterns

## Reusable Greeble Library

Build once, instance everywhere:

| Greeble | Approx Tris | Use |
|---------|-------------|-----|
| Bolt head (hex) | 50 | Surface attachment |
| Vent slot | 100 | Heat dissipation |
| Cable port | 150 | Connectivity |
| LED strip | 80 | Status indicators |
| Hinge bracket | 200 | Mechanical joints |
| Rail segment | 300 | Mounting systems |

## Scatter Rules

- Random rotation on Z only for surface-attached greebles
- Align to face normal using geometry nodes or shrinkwrap
- Density falloff: more greebles near hero camera angles
- Disable greebles on LOD1+

## Collection Structure

```
COL_Greebles
├── SM_Greeble_Bolt_01
├── SM_Greeble_Vent_01
└── SM_Greeble_Port_01
```

Instance via collection instance or geometry nodes scatter.
````

## lod-pipeline

- **Ruta:** `.claude/skills/lod-pipeline`
- **Descripción:** Dedicated LOD generation, naming, screen-size targets, and validation for game meshes in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: lod-pipeline
description: Dedicated LOD generation, naming, screen-size targets, and validation for game meshes in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: LOD, LODs, level of detail, decimate, LOD0, LOD1, impostor, screen size
  related-skills: asset-optimization, export-pipeline, unity-export, unreal-export, collision-proxy
---

# LOD Pipeline

Intentional LOD chains. Preserve silhouette. Validate reductions.

## When to Use

- Game assets needing LOD0–N
- Batch LOD for modular kits
- Before Unity/Unreal/Godot export

## Workflow

```
Approve LOD0 → Generate LOD1..N → Fix silhouette breaks
  → Naming → Screen-size table → Export verify
```

## Typical Budgets (guide)

| LOD | Tris vs LOD0 | Keep |
|-----|--------------|------|
| LOD0 | 100% | Full detail |
| LOD1 | 40–60% | Major forms |
| LOD2 | 15–30% | Silhouette |
| LOD3 | 5–10% | Blob / impostor candidate |

Tune per asset importance and camera.

## Generation Methods

1. **Decimate (planar/collapse)** — fast props
2. **Manual retopo low** — hero characters/vehicles
3. **Delete interiors / small parts** — vehicles, buildings
4. **Bake normals from LOD0 → low** — when detail must move to texture

## Naming

```
SM_Asset_LOD0
SM_Asset_LOD1
SM_Asset_LOD2
```

Collection: `COL_LODs_[Asset]`

## Validation Checklist

- [ ] Silhouette matches at intended distance
- [ ] No major holes / inverted normals
- [ ] UVs still valid (or rebaked)
- [ ] Materials slots consistent across LODs
- [ ] Vertex colors/UVs needed by shader preserved
- [ ] LOD transitions planned (screen size %)

## Screen Size Starters

| LOD | Screen size (UE-like guide) |
|-----|-----------------------------|
| LOD0 | 1.0 – 0.5 |
| LOD1 | 0.5 – 0.25 |
| LOD2 | 0.25 – 0.1 |
| LOD3 | 0.1 – 0.0 |

## Constraints

### MUST DO
- Protect silhouette before poly reduction
- Keep LOD0 as source of truth
- Document budgets in production brief

### MUST NOT DO
- Blind decimate until unrecognizable
- Different material slot counts across LODs without reason

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|----------|
| Lod Budgets | `references/lod-budgets.md` | When needed |
| Lod Validation | `references/lod-validation.md` | When needed |
````

### `references/lod-budgets.md`

```markdown
# LOD Budget Table

| Asset | LOD0 | LOD1 | LOD2 | LOD3 |
|-------|------|------|------|------|
| Hero prop | 100% | 50% | 25% | 10% |
| Standard prop | 100% | 40% | 20% | 8% |
| Vehicle | 100% | 55% | 30% | 12% |
| Tree | 100% | 45% | 20% | impostor |

Protect silhouette first; delete interiors early.
```

### `references/lod-validation.md`

```markdown
# LOD Validation

- [ ] Silhouette OK at transition distance
- [ ] Normals fine
- [ ] Material slots consistent
- [ ] UVs usable or rebaked
- [ ] Naming `_LOD0..N`
```

## lookdev

- **Ruta:** `.claude/skills/lookdev`
- **Descripción:** Look development loop for Blender assets combining materials, lighting, camera, and screenshot comparison until shading reads correctly via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: lookdev
description: Look development loop for Blender assets combining materials, lighting, camera, and screenshot comparison until shading reads correctly via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: lookdev, look development, shading review, material lighting loop, turntable, asset presentation
  related-skills: materials, lighting, rendering, camera-cinematography, compositing, qa-review
---

# Lookdev

Material + light + camera loop. Screenshot compare. Stop when it reads.

## When to Use

- Finalizing asset shading before export/portfolio
- Turntable / grey shader checks
- Matching material references
- Bridging `materials` and `lighting` intentionally

## Workflow

```
Clay/grey pass → Base materials → Neutral light rig
  → Beauty light → Screenshot → Gap list → Iterate (≤3–5)
  → Optional grade → QA
```

## Standard Rigs

| Rig | Use |
|-----|-----|
| Neutral 3-point | Evaluate materials fairly |
| HDRI studio | Product / character |
| In-situ scene lights | Final context |

Keep a reusable `COL_Lookdev_Lights` + `CAM_Lookdev_*`.

## Checklist

- [ ] Values read in grayscale
- [ ] Specular roughness believable
- [ ] Edges catch light (bevels/normals)
- [ ] Emissive under control
- [ ] No pure black / pure white traps unless stylized
- [ ] Matches reference palette if provided

## Iteration Rule

Each pass: change one major variable (material OR light OR camera), then screenshot.

## Constraints

### MUST DO
- Grey pass before fancy textures when forms unsure
- Capture screenshots each iteration
- Hand off to `qa-review` before ship

### MUST NOT DO
- Fix modeling problems only with roughness maps
- Infinite tweak loops without gap list

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|----------|
| Lookdev Rig | `references/lookdev-rig.md` | When needed |
| Lookdev Checklist | `references/lookdev-checklist.md` | When needed |
````

### `references/lookdev-checklist.md`

```markdown
# Lookdev Checklist

- [ ] Greyscale values read
- [ ] Roughness believable
- [ ] Edge highlights present
- [ ] Emissive controlled
- [ ] Reference match (if any)
- [ ] Screenshot each iteration
```

### `references/lookdev-rig.md`

```markdown
# Lookdev Rig

`COL_Lookdev_Lights`: key / fill / rim
`CAM_Lookdev_Hero` + turntable optional
Grey clay pass before textured beauty
```

## lowpoly-style

- **Ruta:** `.claude/skills/lowpoly-style`
- **Descripción:** Low-poly art direction for Blender inspired by PS1/PS2, Lethal Company, Mouthwashing, and Fear to Fathom. Use for readable silhouettes, minimal polygons, simple materials, and strong atmosphere.
- **Archivos incluidos:** 2

### `SKILL.md`

```markdown
---
name: lowpoly-style
description: Low-poly art direction for Blender inspired by PS1/PS2, Lethal Company, Mouthwashing, and Fear to Fathom. Use for readable silhouettes, minimal polygons, simple materials, and strong atmosphere.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: lowpoly, low poly, PS1, PS2, retro, Lethal Company, Mouthwashing, minimal polygon, flat shading
  related-skills: environment-artist, materials, export-pipeline, horror-style
---

# Low Poly Style Specialist

Readable silhouettes. Large shapes. Minimal polygons. Atmosphere over detail.

## When to Use

- Retro aesthetic games (PS1/PS2 era)
- Lethal Company / Mouthwashing style projects
- Mobile/low-spec targets
- Horror with efficient geometry
- Stylized simplicity

## Core Rules

1. **Readable silhouettes** — Shape reads at distance without detail
2. **Minimal polygons** — Every face must earn its place
3. **Large shapes** — Primary forms dominate; micro-detail forbidden
4. **Simple materials** — Flat or lightly textured; 512px default
5. **Limited texture sizes** — 256–512px most assets; 1024 hero only
6. **Strong atmosphere** — Lighting and fog carry visual weight

## Polygon Guidelines

| Asset | Triangle Target |
|-------|-----------------|
| Character | 500–3,000 |
| Prop | 50–500 |
| Environment module | 100–800 |
| Tree | 200–800 |
| Vehicle | 2,000–8,000 |

See `../references/polycount-budgets.md` — apply 50–90% reduction.

## Modeling Approach

- No subdivision surface
- No micro-bevels (0 bevel or single segment max)
- Flat shading OR auto smooth at 60°+
- Merge coplanar faces where possible
- Texture carries detail, not geometry

## PS1 Authenticity (Optional)

| Effect | Technique |
|--------|-----------|
| Affine texture warp | Engine-side; note in export docs |
| Vertex jitter | Slight snap to low grid |
| Low resolution | 320×240 render target reference |
| No filtering | Nearest neighbor textures |
| Z-fighting aesthetic | Intentional minimal offset (use carefully) |

## PS2 Era

- Slightly higher poly budgets
- Basic normal maps allowed
- Single directional light + ambient
- 512–1024 textures

## Material Approach

- Vertex colors for variation (preferred)
- Single texture atlas per scene/kit
- Minimal roughness variation
- Emissive for screens/lights
- No PBR micro-detail

## Silhouette Test

Before approving any asset:
1. Solid flat color material
2. View at gameplay distance
3. Silhouette must communicate identity
4. If unreadable → simplify geometry, not add detail

## Lethal Company Influence

- Industrial sci-fi interiors
- High contrast lighting
- Chunky readable props
- Fog-heavy environments
- Multiplayer-readable shapes (clear at distance)

## Mouthwashing Influence

- Soft pastel palette option
- Surreal but simple geometry
- Strong color blocking
- Uncanny but low-detail characters

## MCP Integration

1. Create low-poly blockouts via MCP
2. Enforce face count limits via MCP queries
3. Assign flat materials via MCP
4. Validate triangle budgets continuously
5. Skip subdiv/bevel modifiers entirely

## Constraints

### MUST DO
- Enforce strict poly budgets
- Prioritize silhouette over surface detail
- Use vertex colors and atlases
- Test at gameplay camera distance
- Coordinate atmosphere with lighting skill

### MUST NOT DO
- Subdivision surfaces
- High-resolution textures on background assets
- Micro-bevels or weighted normal stacks
- Sculpting detail (bake workflow unnecessary)
- Exceed triangle budgets "just a little"

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| PS1 techniques | `references/ps1-aesthetic.md` | Retro authentic look |
| Asset budgets | `../references/polycount-budgets.md` | Budget setting |
```

### `references/ps1-aesthetic.md`

```markdown
# PS1 Aesthetic

## Visual Characteristics

| Feature | Technique |
|---------|-----------|
| Low poly | 50–500 tris per prop |
| Affine texture warp | Engine-side; note in export |
| Vertex jitter | Snap to 0.01m grid optionally |
| No filtering | Nearest neighbor textures |
| Low resolution | 128–256px textures |
| Vertex lighting | Per-vertex; avoid smooth shading |
| Fog | Distance fog mandatory for depth |

## Blender Viewport Approximation

- Flat shading on all meshes
- Disable anti-aliasing in render
- Render at 320×240 or 640×480 upscale
- Limit lights to 1 directional + ambient

## Geometry Rules

- No bevel modifiers
- Triangles acceptable
- Merge coplanar faces
- Snap vertices to low-resolution grid for authentic look

## Texture Rules

- Hand-painted or heavy posterization
- Dithering in gradients
- No normal maps (authentic PS1)
- Optional: fake affine by low UV precision

## Color

Limited palette per scene (16–64 colors feel).
Heavy fog color matches palette darkest tone.

## Modern PS1-Style (Lethal Company)

Higher poly than authentic PS1 but same principles:
- Readable silhouettes
- Strong fog
- Simple materials
- Low-res textures with point filtering
```

## materials

- **Ruta:** `.claude/skills/materials`
- **Descripción:** Blender PBR and stylized material creation for metal, wood, concrete, fabric, glass, dirt, rust, and procedural shaders. Use for look development, material reuse, and production shading in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: materials
description: Blender PBR and stylized material creation for metal, wood, concrete, fabric, glass, dirt, rust, and procedural shaders. Use for look development, material reuse, and production shading in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: material, shader, PBR, procedural, metal, wood, fabric, glass, rust, moss, Principled BSDF
  related-skills: texture-workflow, uv-workflow, lighting, rendering
---

# Materials

Production shading with material reuse. PBR-accurate or intentionally stylized. Minimal unique materials.

## When to Use

- Look development after UVs
- Procedural material creation
- Master material library setup
- Material variation from shared masters
- Engine export material preparation

## Workflow

```
Master Materials → Instance Variations → Object Assignment
    → Vertex Color/Mask Setup → Validation → Export Prep
```

## Master Material Library

Create reusable masters in `MAT_` prefix:

| Master | Base Setup |
|--------|------------|
| MAT_Metal_Base | Principled: Metallic 1, adjustable Roughness |
| MAT_Plastic_Base | Principled: Metallic 0, Specular 0.5 |
| MAT_Fabric_Base | Principled + Sheen |
| MAT_Glass_Base | Principled: Transmission 1, IOR 1.45 |
| MAT_Emissive_Base | Principled: Emission strength variable |
| MAT_Organic_Base | Subsurface scattering enabled |

Instance variations: duplicate master, adjust parameters only.

## PBR Value Ranges

| Material | Metallic | Roughness | Notes |
|----------|----------|-----------|-------|
| Polished metal | 1.0 | 0.1–0.3 | |
| Brushed metal | 1.0 | 0.4–0.6 | Anisotropic if available |
| Painted metal | 0.0 | 0.3–0.5 | Base color = paint |
| Plastic | 0.0 | 0.3–0.6 | |
| Rubber | 0.0 | 0.7–0.9 | |
| Concrete | 0.0 | 0.8–0.95 | |
| Wood (raw) | 0.0 | 0.5–0.7 | |
| Glass | 0.0 | 0.0 | Transmission 1 |
| Skin | 0.0 | 0.4–0.6 | Subsurface 0.1–0.3 |
| Fabric | 0.0 | 0.7–0.9 | Sheen |

## Procedural Material Patterns

**Wear mask:** Noise → ColorRamp → Lerp between clean/worn
**Edge wear:** Bevel node → Pointiness or Ambient Occlusion
**Dirt accumulation:** AO inverted → multiply with dirt color
**Rust:** Noise mask on metal → orange/brown color override

## Material Count Budget

| Asset Type | Max Materials |
|------------|---------------|
| Hero prop | 3–5 |
| Standard prop | 1–2 |
| Modular piece | 1 (atlas) |
| Character | 3–8 (body, cloth, eyes, hair) |
| Environment module | 1–2 |

## Vertex Color Usage

- RGB: variation masks (wear, moss, color variation)
- R: wear amount, G: dirt, B: wetness
- Document channel usage in material notes

## Stylized Materials

See stylized-style skill. Key differences:
- Flatten roughness range
- Hand-painted base color priority
- Rim light via Fresnel mix
- NPR toon shaders if project requires

## MCP Integration

1. Create material slots via MCP
2. Assign materials to objects via MCP
3. Set principled BSDF parameters via MCP
4. Query material count per scene
5. Verify material names follow convention

## Constraints

### MUST DO
- Reuse master materials; instance variations
- Name materials `MAT_[Surface]_[Descriptor]`
- Match PBR values to style skill direction
- Limit material count per asset budget
- Test materials in target lighting setup

### MUST NOT DO
- Unique material per object (unless hero)
- PBR values outside physically plausible range (realistic style)
- Skip vertex color masks for variation
- Leave default material names
- Finalize materials before UVs complete

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Surface recipes | `references/surface-recipes.md` | Specific materials |
| Procedural nodes | `references/procedural-patterns.md` | Wear, dirt, variation |
````

### `references/procedural-patterns.md`

````markdown
# Procedural Material Patterns

## Edge Wear

```
Geometry: Pointiness or Bevel → ColorRamp → Mix with base color/roughness
Mask: Fresnel (high IOR) for edge-only wear
```

## Dirt Accumulation

```
AO (inverted) → Multiply with dirt brown
Combine with cavity mask from curvature
Apply to roughness increase, not albedo darkening alone
```

## Rust Overlay

```
Noise (scale 5–20) → ColorRamp threshold
Mix rust orange-brown over metal base
Increase roughness in rust areas
Metallic: 0 in rust zones
```

## Moss/Growth

```
AO + upward normal (Z+) → Moss green overlay
Roughness increase in moss areas
Subtle subsurface on moss if stylized-realistic
```

## Water Staining

```
Vertical gradient + noise → Darken albedo
Increase roughness slightly
Place on concrete, plaster, ceiling corners
```

## Panel Color Variation

```
Object Info (Random per object) → Hue Saturation Value
Subtle: ±5% hue, ±10% value
```

## Master Graph Pattern

Keep wear/dirt as reusable node groups plugged into master `MAT_*_Base` materials.
````

### `references/surface-recipes.md`

```markdown
# Surface Material Recipes

Quick Principled BSDF starting points. Adjust per reference.

## Painted Metal (Worn)

- Base Color: reference photo
- Metallic: 0
- Roughness: 0.5–0.7
- Procedural: edge wear mask on roughness

## Concrete (Weathered)

- Base Color: desaturated gray 0.4–0.5
- Roughness: 0.85–0.95
- Bump: subtle noise

## Wood (Oiled)

- Base Color: warm brown
- Roughness: 0.4–0.6
- Anisotropic rotation along grain if available

## Fabric (Cotton)

- Roughness: 0.8
- Sheen: 0.3
- Subsurface: 0.05 (optional)

## Glass (Standard)

- Transmission: 1
- IOR: 1.45
- Roughness: 0.02–0.1
```

## prop-artist

- **Ruta:** `.claude/skills/prop-artist`
- **Descripción:** Everyday and hero prop modeling for furniture, tools, household objects, kitbash parts, and readable game props. Use when hard-surface is too sci-fi/mechanical and the asset is a grounded prop.
- **Archivos incluidos:** 4

### `SKILL.md`

````markdown
---
name: prop-artist
description: Everyday and hero prop modeling for furniture, tools, household objects, kitbash parts, and readable game props. Use when hard-surface is too sci-fi/mechanical and the asset is a grounded prop.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: prop, props, furniture, chair, table, bottle, tool, kitbash, household, everyday object, hero prop, set prop
  related-skills: blender-modeler, hard-surface, materials, uv-workflow, asset-optimization, set-dressing
---

# Prop Artist

Grounded, readable props. Silhouette first. Real-world scale. Kitbash-friendly parts.

## When to Use

- Furniture, tools, containers, electronics, household objects
- Hero interactive props and background set dressing pieces
- Kitbash libraries (handles, brackets, panels, fasteners)
- When hard-surface sci-fi language would feel wrong

## Design Principles

1. **Real-world scale** — Measure against human (door 2.0–2.1m, chair seat ~0.45m)
2. **Silhouette readability** — Reads at game camera distance
3. **Wear hierarchy** — Contact edges dirty; protected faces cleaner
4. **Part logic** — Separate meshes where materials or LODs differ
5. **Pivot correctness** — Floor contact, grip, hinge, or socket as needed

## Workflow

```
Reference → Scale blockout → Primary volumes → Secondary forms
  → Edge bevels → Wear/damage → UVs → Materials → Optimize → Export
```

## Prop Tiers

| Tier | Tris (guide) | Detail | Use |
|------|--------------|--------|-----|
| Hero | 2k–8k | Full bevels, unique wear | Interactables, close-ups |
| Standard | 500–2k | Clean forms, shared mats | Midground |
| Background | 100–500 | Block forms, atlas mats | Far / dense dressing |

## Kitbash Rules

- Name parts `SM_KB_[Category]_[Part]`
- Keep origins at logical attach points
- Prefer modular dimensions (0.05 / 0.1 / 0.25m grid)
- Collection: `COL_Kitbash_[Set]`

## Material Guidance

- Limit unique materials; atlas where possible
- Separate glass / emissive / opaque when needed for engine
- Wear via roughness/AO, not only albedo dirt

## Handoff

- UVs → `uv-workflow`
- Look → `materials` / `lookdev`
- Placement → `set-dressing`
- Ship → `asset-optimization` → `export-pipeline` or engine export skill

## Constraints

### MUST DO
- Set real-world scale before detailing
- Place pivot intentionally
- Match prop tier to camera distance

### MUST NOT DO
- Over-greeble everyday objects
- Use sci-fi panel language on mundane props
- Skip collision planning for interactables

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|----------|
| Prop Tiers | `references/prop-tiers.md` | When needed |
| Kitbash Library | `references/kitbash-library.md` | When needed |
| Everyday Prop Checklist | `references/everyday-prop-checklist.md` | When needed |
````

### `references/everyday-prop-checklist.md`

```markdown
# Everyday Prop Checklist

- [ ] Real-world scale vs human reference
- [ ] Silhouette readable at game FOV
- [ ] Pivot correct for use case
- [ ] Bevels only on visible contact edges
- [ ] Material count within budget
- [ ] UVs: no obvious stretch on hero faces
- [ ] Collision proxy planned
- [ ] Naming `SM_` + collection `COL_`
```

### `references/kitbash-library.md`

```markdown
# Kitbash Library Spec

## Naming
`SM_KB_[Category]_[Part]_[Variant]`

Categories: `Handle`, `Bracket`, `Bolt`, `Panel`, `Pipe`, `Vent`, `Switch`, `Label`, `Foot`, `Hinge`

## Grid
- Base module: 0.05m
- Prefer 0.05 / 0.1 / 0.25 / 0.5m extents
- Origin at attach face center

## Collections
`COL_Kitbash_[SetName]` with subcollections per category.

## Export
Instance in scenes; do not unique-mesh every use unless hero.
```

### `references/prop-tiers.md`

```markdown
# Prop Tiers & Budgets

| Tier | Camera distance | Tris guide | Materials | Collision |
|------|-----------------|------------|-----------|-----------|
| Hero interactable | < 2m | 2k–8k | Unique or shared atlas + unique trim | Accurate convex / multi-UCX |
| Standard mid | 2–8m | 500–2k | Shared atlas | Simple box/convex |
| Background | > 8m | 100–500 | Atlas / trim sheet | Optional / none |
| Kitbash part | modular | 50–400 | Trim sheet | Attach-point only |

## Pivot Rules
- Floor props: origin at ground contact center
- Handheld: grip point
- Doors/drawers: hinge
- Wall mounts: wall contact plane

## Wear Map Priority
1. Handles, rims, corners
2. Floor-facing feet
3. Top dust catchers
4. Protected undersides (cleaner)
```

## qa-review

- **Ruta:** `.claude/skills/qa-review`
- **Descripción:** Production QA gate for Blender assets using viewport screenshots, validation checklists, naming audits, and ship/no-ship verdicts via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: qa-review
description: Production QA gate for Blender assets using viewport screenshots, validation checklists, naming audits, and ship/no-ship verdicts via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: QA, quality assurance, review, validation, checklist, screenshot review, ship check, art review
  related-skills: asset-optimization, export-pipeline, blender-director, lookdev
---

# QA Review

Screenshot-backed review. Checklist gate. Explicit ship / no-ship.

## When to Use

- Before export or handoff
- After major modeling/lookdev milestones
- Reference-match final compare
- Periodic scene health checks

## Workflow

```
Gather brief budgets → Screenshot key angles → Run checklists
  → List defects (severity) → Fix or reject → Re-verify → Verdict
```

## Required Screenshots

1. 3/4 hero angle
2. Ortho or profile if proportion-critical
3. Wireframe or poly overview (optional but useful)
4. Material/light beauty
5. Vs reference (if reference task)

Use `get_viewport_screenshot` via MCP when connected.

## Checklists (load as needed)

- `../references/validation-checklist.md`
- `../references/visual-match-checklist.md` (reference tasks)
- `../references/naming-conventions.md`
- `../references/polycount-budgets.md`

## Defect Severity

| Level | Meaning |
|-------|---------|
| Blocker | Wrong scale, broken normals, fails budget badly |
| Major | Silhouette/readability issues, bad pivots |
| Minor | Naming, minor shading, small gaps |
| Note | Optional polish |

## Verdict Template

```markdown
## QA Verdict: [Asset]

**Result:** SHIP / SHIP WITH NOTES / NO-SHIP
**Budgets:** [tris/textures] vs target
**Screenshots:** [listed]
**Blockers:** ...
**Majors:** ...
**Minors:** ...
**Next actions:** ...
```

## Constraints

### MUST DO
- Give explicit verdict
- Attach or capture screenshots for visual claims
- Re-check after fixes before flipping to SHIP

### MUST NOT DO
- Rubber-stamp without screenshots on visual tasks
- Ignore budget overruns without approval

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|----------|
| Qa Verdict Template | `references/qa-verdict-template.md` | When needed |
| Screenshot Angles | `references/screenshot-angles.md` | When needed |
````

### `references/qa-verdict-template.md`

````markdown
# QA Verdict Template

```markdown
## QA Verdict: [Asset/Shot]
**Result:** SHIP / SHIP WITH NOTES / NO-SHIP
**Budgets:** tris / textures vs target
**Angles captured:**
**Blockers:**
**Majors:**
**Minors:**
**Notes:**
**Retest after:**
```
````

### `references/screenshot-angles.md`

```markdown
# Required Screenshot Angles

1. Hero 3/4
2. Opposite 3/4 or profile
3. Beauty lit
4. Wire/overview (optional)
5. Reference compare (if any)
```

## roblox-export

- **Ruta:** `.claude/skills/roblox-export`
- **Descripción:** Contract for exporting Blender 4.5 assets into Roblox Studio (scale in studs, FBX settings, SM_/COL_/MAT_ naming, per-tier triangle budgets, collision fidelity, SurfaceAppearance maps, in-Studio validation). Use before exporting any asset that goes into the Roblox game. Extends export-pipeline and asset-optimization.
- **Archivos incluidos:** 1

### `SKILL.md`

```markdown
---
name: roblox-export
description: Contract for exporting Blender 4.5 assets into Roblox Studio (scale in studs, FBX settings, SM_/COL_/MAT_ naming, per-tier triangle budgets, collision fidelity, SurfaceAppearance maps, in-Studio validation). Use before exporting any asset that goes into the Roblox game. Extends export-pipeline and asset-optimization.
license: MIT
metadata:
  domain: blender
  role: specialist
  project: juego-roblox-survivor
  version: "1.0.0"
  triggers: roblox, roblox studio, export roblox, MeshPart, SurfaceAppearance, studs, collision fidelity
  related-skills: export-pipeline, asset-optimization, lod-pipeline, collision-proxy, texture-workflow, qa-review
---

# Roblox Export

Contrato de exportación entre Blender 4.5 y Roblox Studio. Todo lo que no esté confirmado en Studio lleva la marca `VERIFICAR EN STUDIO`. No lo des por válido hasta probarlo.

## 1. Escala y orientación
- Trabaja en Blender en metros (1 unidad = 1 m) y aplica la escala (`Ctrl+A` → Scale) antes de exportar.
- Roblox mide en studs. Referencia orientativa: 1 stud ≈ 0.28 m. `VERIFICAR EN STUDIO`: importa un cubo de referencia y comprueba su tamaño antes de producir en serie.
- Pivote: en la base (contacto con el suelo) para personajes, enemigos y props. En el centro para pickups y proyectiles.
- Ejes según `export-pipeline`: forward `-Z`, up `Y`.

## 2. Formato
- Formato por defecto: **FBX**, con los ajustes de `export-pipeline` (Apply Scalings = FBX All, Apply Unit ON, Path Mode = Copy).
- GLB/glTF: `VERIFICAR EN STUDIO` si el importador de tu versión lo acepta. Si no, FBX.
- Un asset, un archivo. Fuente `.blend` en `assets/src/`; exportaciones en `assets/export/`.

## 3. Nombres (obligatorio)
| Elemento | Patrón | Ejemplo |
|---|---|---|
| Colección de exportación | `COL_Export` | `COL_Export` |
| Malla visible | `SM_<Nombre>_LOD0` | `SM_Enemigo_Perseguidor_LOD0` |
| Malla reducida | `SM_<Nombre>_LOD1` | `SM_Enemigo_Perseguidor_LOD1` |
| Colisión | `COL_<Nombre>` | `COL_Enemigo_Perseguidor` |
| Material | `MAT_<Nombre>` | `MAT_Enemigo_Rojo` |
| Textura | `T_<Nombre>_BC` / `_N` / `_MR` | `T_Heroe_BC` |

## 4. Presupuestos (orientativos; `VERIFICAR EN STUDIO` contra límites y rendimiento reales)
| Tier | Uso típico | Triángulos LOD0 | Triángulos LOD1 | Textura |
|---|---|---|---|---|
| Héroe jugador | 1 por personaje | ≤ 5 000 | ≤ 2 500 | 1024 |
| Enemigo común | Decenas en pantalla | ≤ 1 200 | ≤ 400 | Atlas 512 o 1024 |
| Élite / jefe | 1 a 3 | ≤ 8 000 | ≤ 3 000 | 1024 |
| Prop de escenario | Muchas copias | ≤ 500 | — | Atlas 1024 |
| Pieza de nave | 4 piezas del dossier | < 5 000 | ≤ 2 000 | 1024 |

Reglas: máximo 3 materiales por modelo. Un atlas por tier cuando sea posible, para reducir draw calls.

## 5. Colisión
- Malla `COL_<Nombre>` separada: caja o convexa, sin materiales, con transformaciones aplicadas y oculta en el render.
- En Studio, usa `CollisionFidelity` `Box` o `Hull` para enemigos, proyectiles y props dinámicos. Evita mallas de colisión precisas en objetos que se mueven. `VERIFICAR EN STUDIO` (nombres exactos de la propiedad en tu versión).

## 6. Materiales y texturas
- Un `SurfaceAppearance` por material, con `ColorMap` (BC), `NormalMap` (N), `MetalnessMap` y `RoughnessMap` (MR, empaquetado o por separado). `VERIFICAR EN STUDIO` cómo se asigna el canal empaquetado.
- Emisivos (luces de enemigos, ojos, núcleos): no van en `SurfaceAppearance`. Usa color en el modelo más efectos de Studio (`PointLight`, `ParticleEmitter`, material `Neon`). `VERIFICAR EN STUDIO`.
- Texturas de potencia de 2 y 1024 px como máximo, salvo jefes o pieza de nave hero.

## 7. LOD y rendimiento en Roblox
- En este flujo, Roblox no genera LOD automático: crea `LOD0` y `LOD1` como mallas separadas y cambia entre ellas por distancia en Luau.
- `VERIFICAR EN STUDIO`: la propiedad `RenderFidelity` de `MeshPart` y su efecto sobre el nivel de detalle.
- Para hordas usa modelos de bajo coste y pooling. Nunca clones un modelo pesado por enemigo.

## 8. Validación en Studio (checklist por asset)
1. Escala: el héroe mide lo previsto frente a un avatar de referencia (`VERIFICAR EN STUDIO`).
2. Pivote: ni flota ni se hunde en el suelo.
3. Normales y sombras correctas con iluminación Future.
4. Colisión: el jugador no se engancha ni atraviesa el objeto.
5. Estadísticas: número de partes y draw calls anotados en `docs/perf/`.
6. Salida (Output): sin advertencias ni errores al cargar.
7. Prueba en PC y en un móvil de referencia.

## 9. Entregable por asset
Archivo `docs/assets/<Nombre>.md` con:
- Archivo exportado y fecha.
- Escala y pivote.
- Triángulos por LOD y materiales.
- Colisión usada.
- Resultado de validación (PASS o FAIL, con evidencia).

## 10. Prohibido
- Exportar con escala sin aplicar, o con modificadores activos sin documentar.
- Nombres sin prefijo o fuera de la convención.
- Afirmar que algo funciona en Roblox sin haberlo probado en Studio.
- Usar assets de terceros sin licencia verificada.
```

## sci-fi-punk-worlds

- **Ruta:** `.claude/skills/sci-fi-punk-worlds`
- **Descripción:** Sci-fi and punk world art direction for Blender including hard sci-fi, space, cyberpunk, steampunk, dieselpunk, atompunk, solarpunk, biopunk, and clockpunk.
- **Archivos incluidos:** 6

### `SKILL.md`

```markdown
---
name: sci-fi-punk-worlds
description: Sci-fi and punk world art direction for Blender including hard sci-fi, space, cyberpunk, steampunk, dieselpunk, atompunk, solarpunk, biopunk, and clockpunk.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: sci-fi, hard sci-fi, space, cyberpunk, steampunk, dieselpunk, atompunk, solarpunk, biopunk, clockpunk, retrofuturism
  related-skills: hard-surface, environment-artist, vehicle-artist, materials, vfx-fx, neon-retrofuturism
---

# Sci-Fi / Punk Worlds

Choose one punk/sci-fi lane. Don’t mix chrome cyber with brass steam unless intentional mashup.

## Lanes
Hard sci-fi · Space opera · Cyberpunk · Steampunk · Dieselpunk · Atompunk · Solarpunk · Biopunk · Clockpunk
```

### `references/cyberpunk.md`

```markdown
# Cyberpunk
Dense verticality, neon signage, rain, cables, megacorp branding, street vs tower contrast.
```

### `references/diesel-atom.md`

```markdown
# Dieselpunk / Atompunk
Diesel: WWII-ish machines, heavy panels. Atompunk: 1950s future, chrome, atomic motifs, pastel+chrome.
```

### `references/hard-space.md`

```markdown
# Hard Sci-Fi / Space
Functional panels, readable modules, zero-g cues, subdued materials, realistic wear.
```

### `references/solar-bio-clock.md`

```markdown
# Solarpunk / Biopunk / Clockpunk
Solarpunk: green cities, warm sun, integrated plants. Biopunk: flesh-tech, wet labs. Clockpunk: gears, clockwork, pre-steam precision.
```

### `references/steampunk.md`

```markdown
# Steampunk
Brass, copper, rivets, gauges, steam vents, Victorian silhouettes + machines.
```

## stylized-style

- **Ruta:** `.claude/skills/stylized-style`
- **Descripción:** Stylized art direction for Blender with shape language, exaggeration, color harmony, NPR rendering, and hand-painted asset workflows. Use for non-photorealistic game and animation projects.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: stylized-style
description: Stylized art direction for Blender with shape language, exaggeration, color harmony, NPR rendering, and hand-painted asset workflows. Use for non-photorealistic game and animation projects.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: stylized, NPR, hand-painted, toon, cartoon, exaggerated, shape language, cel shading
  related-skills: materials, rendering, lowpoly-style, environment-artist
---

# Stylized Style Specialist

Deliberate shape language. Exaggerated proportions. Color harmony. NPR rendering.

## When to Use

- Non-photorealistic games
- Hand-painted texture workflows
- Animated/stylized characters
- Fantasy environments with art direction
- Toon/cel-shaded rendering

## Core Principles

1. **Shape language** — Circles=friendly, squares=stable, triangles=danger
2. **Exaggeration** — Push proportions beyond realistic
3. **Color harmony** — Limited palette; intentional accent colors
4. **Silhouette clarity** — Strong readable shapes
5. **Detail in texture** — Not micro-geometry

## Shape Language

| Shape | Association | Use |
|-------|-------------|-----|
| Circle/Oval | Friendly, approachable | Heroes, cute creatures |
| Square/Rectangle | Stable, reliable | Architecture, guards |
| Triangle | Dynamic, dangerous | Villains, spikes, roofs |

Combine shapes consistently per character/faction.

## Proportion Exaggeration

| Feature | Stylized Approach |
|---------|-------------------|
| Head | 25–40% of height (chibi to semi-realistic) |
| Hands | Larger for expressiveness |
| Eyes | Enlarged for emotion |
| Limbs | Tapered; simplified joints |
| Weapons | Oversized for readability |

## Color Harmony

**Triadic:** Three equidistant hues — vibrant, balanced
**Complementary:** Opposite hues — high contrast accents
**Analogous:** Adjacent hues — harmonious environments

Rules:
- Limit palette to 3–5 core colors + neutrals
- Reserve saturated accents for interactive elements
- Desaturate backgrounds; saturate foreground subjects

## Material Approach

- Hand-painted albedo priority over PBR accuracy
- Flat or stepped roughness (not continuous PBR)
- Rim lighting built into texture (not just shader)
- Subsurface on skin: exaggerated warm tones
- No photoreal micro-detail

## NPR Rendering

Coordinate with rendering skill:
- Toon BSDF or Shader to RGB setups
- Stepped lighting (2–3 bands)
- Outline pass: inverted hull or Freestyle
- Bloom on emissive accents
- Flat ambient forbidden — maintain form readability

## Hand-Painted Texture Workflow

```
1. Flat base color blocks
2. Define light/shadow shapes (not gradients from bake)
3. Edge highlights (warm) and shadows (cool)
4. Detail pass: minimal; suggestive not literal
5. Ambient occlusion painted, not baked
```

## Character Stylization

- Simplified anatomy; avoid uncanny valley
- Hair as solid shapes or card clusters
- Clothing folds: painted, not simulated
- Facial features: large eyes, small nose (style dependent)

## Environment Stylization

- Exaggerated verticality in forests/mountains
- Architecture: oversized elements (doors, windows)
- Vegetation: puff/cloud shapes (not botanical accuracy)
- Water: stylized foam patterns

## MCP Integration

1. Block exaggerated proportions via MCP
2. Assign stylized materials via MCP
3. Configure NPR render settings via MCP
4. Validate silhouette with flat shading via MCP
5. Limit geometry detail per stylized budgets

## Constraints

### MUST DO
- Define shape language per asset/faction
- Maintain color palette consistency
- Exaggerate intentionally, not accidentally
- Paint detail in textures
- Test NPR render early

### MUST NOT DO
- Mix photoreal PBR with stylized shapes without intent
- Micro-detail geometry (use texture)
- Realistic proportions unless semi-stylized target
- Full PBR roughness accuracy
- Skip outline/rim if NPR project requires

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| NPR shader setup | `references/npr-shaders.md` | Rendering setup |
| Color palettes | `references/palette-examples.md` | Art direction |

## Related Style Packs
- `cartoon-style`, `anime-style`, `comic-book-style`, `manga-style`, `hand-painted-style`, `painterly-style`
- `chibi-style`, `pixel-art-style`, `hd-2d-style`, `stop-motion-craft-style`
````

### `references/npr-shaders.md`

````markdown
# NPR Shader Setups

## Cel Shader (Eevee/Cycles)

```
[Layer Weight or Fresnel] → [ColorRamp 3 stops] → [Mix with Base Color] → Output
Stops: Shadow (dark), Mid, Highlight (bright)
```

## Toon BSDF (If Available)

Direct toon shading with size parameter for light band width.

## Outline Pass

**Inverted Hull:**
```
Solidify: -0.02m
Flip Normals
Material: Emission black, backface culling off
```

Render as separate pass; composite over beauty.

## Rim Light Node

```
Fresnel (1.5) → Multiply → Add to Emission
Color: warm (#FFAA66) for heroes, cool for villains
```

## Specular Control

Reduce specular to 0–0.2 for flat stylized look.
Or use hard ColorRamp on specular output.

## Shadow Hardness

Sun size: 0° (hard shadow) for toon.
Area light size: small for sharp terminator.

## Stylized Skin

```
Base color (warm)
+ Subsurface (high radius, low weight)
+ Painted blush in vertex colors
+ Hard shadow terminator (ColorRamp on Lambert)
```

## Export to Game Engine

Bake NPR result to texture set if target engine lacks toon shaders.
Or export shader graph documentation for engine recreation.
````

### `references/palette-examples.md`

```markdown
# Palette Examples

## Heroic Fantasy (Triadic)

| Role | Color | Hex |
|------|-------|-----|
| Primary | Royal Blue | #2E5090 |
| Secondary | Gold | #D4A843 |
| Accent | Crimson | #8B2030 |
| Neutral | Warm Gray | #6B6560 |

## Cozy Stylized (Analogous)

| Role | Color | Hex |
|------|-------|-----|
| Primary | Sage Green | #7A9E7E |
| Secondary | Cream | #F0E6D3 |
| Accent | Terracotta | #C4724E |
| Shadow | Deep Green | #3D5A40 |

## Sci-Fi (Complementary)

| Role | Color | Hex |
|------|-------|-----|
| Primary | Cool Gray | #8899AA |
| Secondary | Orange Accent | #E87830 |
| Emissive | Cyan | #00DDFF |
| Background | Dark Blue-Gray | #1A2233 |

## Horror (Desaturated + Accent)

| Role | Color | Hex |
|------|-------|-----|
| Base | Gray-Green | #5A6058 |
| Shadow | Near Black | #0A0C0A |
| Accent (blood) | Dried Red | #4A1515 |
| Light | Sick Yellow-Green | #B8C4A0 |

## Usage Rules

- 70% neutral/dominant
- 20% secondary
- 10% accent (interactive elements, threats)
- Background desaturated vs foreground saturated
```

## texture-workflow

- **Ruta:** `.claude/skills/texture-workflow`
- **Descripción:** Production texture workflow for atlases, baking AO/curvature/normal/roughness maps, decals, and texture memory optimization. Use for game-ready texture pipelines in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: texture-workflow
description: Production texture workflow for atlases, baking AO/curvature/normal/roughness maps, decals, and texture memory optimization. Use for game-ready texture pipelines in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: texture, bake, normal map, AO, curvature, roughness, metallic, height, atlas, decal, emission
  related-skills: uv-workflow, materials, asset-optimization
---

# Texture Workflow

Bake high-poly detail to efficient texture sets. Optimize memory. Engine-ready outputs.

## When to Use

- Baking sculpt detail to normal maps
- Creating texture atlases for modular kits
- PBR texture set generation
- Decal placement and blending
- Texture memory optimization

## Workflow

```
High/Low Poly Setup → Cage Setup → Bake Maps → Composite
    → Atlas Pack → Engine Format Export → Validation
```

## Standard PBR Texture Set

| Map | Format | Notes |
|-----|--------|-------|
| Base Color | sRGB PNG | No embedded AO |
| Normal | Linear PNG | OpenGL convention unless engine specifies |
| Roughness | Linear PNG | Single channel |
| Metallic | Linear PNG | Single channel |
| AO | Linear PNG | Multiply in shader, not base color |
| Height | Linear PNG | Optional parallax |
| Emission | sRGB PNG | Mask-based |
| ORM Packed | Linear PNG | R=AO, G=Roughness, B=Metallic (Unreal) |

Naming: `T_[Asset]_[Map]` per `../references/naming-conventions.md`

## Bake Setup

```
1. Low-poly mesh with UVs (active)
2. High-poly mesh (sculpt or detail) — selected
3. Cage extrusion: 0.01–0.05m (adjust per asset scale)
4. Ray distance: match cage
5. Bake margin: 16px minimum
6. Anti-aliasing: enabled
```

## Maps to Bake

| Map | Source | Priority |
|-----|--------|----------|
| Normal | High→Low | Required |
| AO | High or low (cavity) | Required |
| Curvature | High sculpt | Wear masks |
| Position | High | Optional (blending) |
| Thickness | Subsurface meshes | Characters |

## Texture Atlas Strategy

Modular kits share one atlas:
```
1. All modules UV'd to shared 0–1 or UDIM space
2. Bake each module to atlas regions
3. Trim sheet areas for repeating detail
4. Single material references atlas
5. Document region map for artists
```

## Decals

- Decal mesh projected on surface
- Separate UV channel or atlas region
- Blend via alpha mask
- Limit decal overdraw in engine

## Memory Optimization

| Technique | Savings |
|-----------|---------|
| ORM packing | 3 textures → 1 |
| Shared atlas | N materials → 1 texture |
| Lower res on hidden surfaces | 50%+ memory |
| BC compression in engine | 4:1 or 6:1 |
| Trim sheets | Reuse detail across assets |

## Resolution Guidelines

See `../references/polycount-budgets.md` texture section.

## MCP Integration

1. Setup bake objects via MCP
2. Configure bake settings via MCP if supported
3. Export baked images via MCP
4. Assign baked textures to materials via MCP
5. Query texture count and resolution

## Validation Checklist

- [ ] Normal map correct orientation (test in engine)
- [ ] No UV seams visible in bake
- [ ] AO not baked into base color
- [ ] Consistent texel density in final textures
- [ ] Texture resolution within budget
- [ ] Files named per convention
- [ ] sRGB vs Linear correctly assigned

## Constraints

### MUST DO
- Bake high-poly detail before discarding sculpt
- Use cage for clean normal bakes
- Pack ORM for engine efficiency
- Test normal map orientation in target engine
- Document atlas regions for modular kits

### MUST NOT DO
- Bake without cage on complex shapes
- Embed AO in base color (PBR standard)
- Exceed texture budget without LOD justification
- Use inconsistent normal map conventions
- Skip margin in bake settings

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Bake troubleshooting | `references/bake-troubleshooting.md` | Bake artifacts |
| ORM packing | `references/orm-packing.md` | Unreal/Unity export |
````

### `references/bake-troubleshooting.md`

````markdown
# Bake Troubleshooting

## Normal Map Artifacts

| Artifact | Cause | Fix |
|----------|-------|-----|
| Seams visible | Cage too tight/loose | Adjust cage extrusion 0.01–0.05m |
| Black spots | Overlapping high-poly | Fix intersecting geometry |
| Inverted normals | Flipped faces on high/low | Recalculate outside |
| Blurry detail | Low bake resolution | Increase to 2048+; increase margin |
| Stripes | Bad UV seams | Reposition seams to hidden edges |

## AO Issues

| Issue | Fix |
|-------|-----|
| Too dark | Reduce AO strength in shader; don't bake into albedo |
| Missing contact | Increase ray distance |
| Noise | Smooth AO in post or increase samples |

## Cage Setup

```
1. Duplicate low-poly → name SM_Asset_Cage
2. Solidify or shrinkwrap expand 0.02m outward
3. Select as cage object in bake settings
4. Delete cage after successful bake
```

## Ray Distance

Start at 0.01m for small props; 0.05m for characters. Increase if missing detail; decrease if artifacts.

## Margin

Minimum 16px at target resolution. Hero assets: 32px at 4K bake.

## Test Workflow

Bake single tile/region first before full atlas bake.
````

### `references/orm-packing.md`

````markdown
# ORM Packing

Pack Occlusion, Roughness, Metallic into single texture for engine efficiency.

## Channel Assignment (Unreal Standard)

| Channel | Map |
|---------|-----|
| R | Ambient Occlusion |
| G | Roughness |
| B | Metallic |

## Blender Compositing

```
1. Bake or import AO, Roughness, Metallic as separate grayscale
2. Compositor: Combine RGB
   - R ← AO
   - G ← Roughness
   - B ← Metallic
3. Export as T_Asset_ORM.png (linear, no sRGB)
```

## Unity HDRP/URP

Similar ORM packing; verify shader expects same channel order.
Some Unity shaders use Metallic(R) + AO(B) — check target shader docs.

## Naming

`T_[Asset]_ORM` per naming conventions.

## Notes

- All channels linear color space
- AO should not be multiplied into albedo if using ORM shader
- Default roughness: 0.5 where no map painted
- Metallic: binary 0 or 1 for most surfaces; blend only at transitions
````

## uv-workflow

- **Ruta:** `.claude/skills/uv-workflow`
- **Descripción:** Production UV unwrapping for seam placement, UV packing, texel density, UDIM, lightmap UVs, and modular UV layouts. Use when preparing meshes for texturing and engine export in Blender via MCP.
- **Archivos incluidos:** 3

### `SKILL.md`

````markdown
---
name: uv-workflow
description: Production UV unwrapping for seam placement, UV packing, texel density, UDIM, lightmap UVs, and modular UV layouts. Use when preparing meshes for texturing and engine export in Blender via MCP.
license: MIT
metadata:
  author: https://github.com/arjun988
  version: "1.0.0"
  domain: blender
  role: specialist
  triggers: UV, unwrap, seam, texel density, UV pack, UDIM, lightmap UV, UV layout
  related-skills: texture-workflow, materials, export-pipeline
---

# UV Workflow

Efficient UV layouts with consistent texel density. Seams at hidden edges. Engine-ready.

## When to Use

- After topology locked, before texturing
- Modular kit UV atlas planning
- Lightmap UV channel setup
- UDIM workflows for hero assets

## Workflow

```
UV Planning → Seam Marking → Unwrap → Texel Density Check
    → Pack → Mirror/Overlap Decision → Lightmap UV (if needed) → Validation
```

## Seam Placement Rules

Place seams at:
- Back of head, spine centerline
- Inner arms, inner legs
- Bottom of chin, underside of objects
- Panel edges on hard surface (construction seams)
- Hidden areas under clothing/overlaps

Never place seams on:
- Face (front)
- Primary gameplay-visible surfaces
- Deforming joint centers (relocate to nearby hidden area)

## Texel Density

**Formula:** `Texel Density = Texture Resolution / UV Island Size in UV space`

Target consistency across visible surfaces:

| Asset Tier | Target TD (px/m) |
|------------|------------------|
| Hero | 512–1024 px/m |
| Standard | 256–512 px/m |
| Background | 128–256 px/m |

Use same density for modular kit pieces sharing atlas.

## Unwrap Methods

| Method | Use When |
|--------|----------|
| Smart UV Project | Quick blockout UVs only |
| Follow Active Quads | Strip UVs (roads, limbs) |
| Cube Project | Boxy hard surface |
| Lightmap Pack | Lightmap channel |
| Manual seam + Unwrap | Production default |

## UV Packing

- Margin: 0.002–0.01 UV units (engine dependent)
- Rotate islands for maximum packing efficiency
- Group islands by material ID
- Keep related islands near each other in UV space
- Use UVPackmaster or native pack for production

## Mirrored UVs

- Mirror UVs for symmetrical characters (save texture space)
- Offset mirrored islands slightly if engine requires unique bakes
- Mark mirrored halves in object naming: `_L` / `_R` meshes if separate

## UDIM Workflow

For hero assets exceeding single 4K texture:
- Tile 1001: head
- Tile 1002: torso
- Tile 1003: limbs
- Document tile assignment in production brief

## Lightmap UVs

Second UV channel requirements:
- No overlapping islands
- Consistent texel density less critical
- Larger margin (0.02+) for light bleed prevention
- Pack separately from texture UVs

## Modular UV Atlas

```
1. Plan shared atlas resolution (2048/4096)
2. Assign UV islands per module to atlas regions
3. Trim sheet regions for repeating detail
4. Vertex color variation for module differentiation
5. Document atlas layout for texture artist
```

## MCP Integration

1. Mark seams via MCP if supported
2. Execute unwrap via MCP
3. Query UV island count and pack efficiency
4. Assign UV channels via MCP
5. Validate no overlapping UVs (except intentional mirror)

## Validation Checklist

- [ ] No unintended overlapping UVs
- [ ] Consistent texel density on visible surfaces
- [ ] Seams hidden at gameplay angles
- [ ] UV islands within 0–1 (or UDIM tiles assigned)
- [ ] Lightmap channel separate if required
- [ ] Pack efficiency > 75%

## Constraints

### MUST DO
- Plan UVs before final modeling (topology informed by UV needs)
- Maintain texel density consistency
- Hide seams at logical construction edges
- Create lightmap UVs for baked lighting pipelines
- Document atlas layout for modular kits

### MUST NOT DO
- Smart UV Project as final production UVs
- Overlapping UVs on unique surface detail (unless mirrored)
- Inconsistent texel density on same asset tier
- Seams across faces or primary visible surfaces
- Skip packing margins

## Reference Guide

| Topic | Reference | Load When |
|-------|-----------|-----------|
| Texel density calc | `references/texel-density.md` | Hero assets |
| Trim sheets | `references/trim-sheets.md` | Modular kits |
````

### `references/texel-density.md`

````markdown
# Texel Density

## Calculation

```
Texel Density (px/m) = Texture Resolution / Physical Size (m)

Example: 2048px texture over 2m wall = 1024 px/m
```

## Matching Density

1. Select UV island for reference object
2. Scale all islands to match reference TD
3. Use UV sync tools or manual scaling from known UV-to-world ratio

## Hero vs Background

Same kit: hero modules 1024 px/m, background modules 512 px/m — acceptable if not adjacent in scene.

## UDIM

Each tile maintains independent TD. Document tile assignment per body region.
````

### `references/trim-sheets.md`

````markdown
# Trim Sheets

## Layout Strategy

Single 2048 or 4096 texture shared across modular kit:

```
[Top edge trim | Corner trim | Panel fill | Window frame | Damage variants | Bolts/rivets]
```

## UV Assignment

- Each module UVs to assigned trim region
- Maintain consistent texel density across modules
- Leave 2–4px margin between trim regions

## Modeling Trim Geometry

- Bevel profile matches trim sheet cross-section
- Extrude along edges using trim UV coordinates
- Avoid unique trim geo per module — reuse UV regions

## Variation

| Method | Use |
|--------|-----|
| UV offset | Same trim, different region |
| Vertex color | Tint without new texture |
| Material instance | Roughness variation |

## Export Notes

Document trim sheet regions in production brief:

```
Region A (0.0–0.25 U): Wall panel standard
Region B (0.25–0.5 U): Wall panel damaged
Region C (0.5–0.75 U): Corner trim
Region D (0.75–1.0 U): Window surround
```
````

## references (compartidas)

- **Ruta:** `.claude/skills/references`
- **Descripción:** Documentos de referencia compartidos por las skills del proyecto (carpeta references).
- **Archivos incluidos:** 9

### `references/asset-pipeline.md`

````markdown
# Universal Asset Pipeline

Every Blender asset follows this sequence. **Never skip planning.**

```
Reference Collection
        ↓
     Planning
        ↓
  Scale Planning
        ↓
  Primary Shapes
        ↓
 Secondary Shapes
        ↓
 Silhouette Review
        ↓
 Topology Strategy
        ↓
     Modeling
        ↓
      Cleanup
        ↓
    UV Planning
        ↓
  UV Unwrapping
        ↓
    Materials
        ↓
  Optimization
        ↓
 Rigging (if required)
        ↓
Animation (if required)
        ↓
Collision Planning (if game asset)
        ↓
      Export
        ↓
   Validation
```

## Phase Details

### Reference Collection
- Gather orthographic views, real-world dimensions, style references
- **If user attached a photo/concept:** run `reference-image-match.md` — write Reference Analysis (`reference-analysis-template.md`) before modeling
- Extract color palette (5–8 hex), camera angle, key light direction, hero features
- Identify modular pieces, hero vs background detail levels
- Note manufacturing/construction logic for hard surface

### Planning
- Define asset purpose: hero prop, modular kit piece, background filler
- Target platform: mobile, console, PC, cinematic-only
- Document polycount, texture resolution, LOD requirements
- Choose style skill: horror, lowpoly, stylized, realistic

### Scale Planning
- Establish scene scale (1 Blender unit = 1 meter default)
- Place human-scale reference (1.8m capsule or mannequin)
- Lock pivot/origin strategy before modeling

### Primary Shapes
- Block out largest readable forms first
- Focus on silhouette, not detail
- Use primitives, mirror, array, non-destructive modifiers

### Secondary Shapes
- Add functional subdivisions: panels, edges, structural breaks
- Maintain shape hierarchy: primary > secondary > tertiary

### Silhouette Review
- Rotate camera at 45° increments
- **Match hero camera to reference** if image was provided (`CAM_*` + target empty)
- Check readability at gameplay/camera distance
- Fix silhouette before adding micro-detail
- **Tier 2 panel breaks** (ribs, belts, recesses) before tier 3 greebles

### Topology Strategy
- Plan edge flow for deformation (characters) or bevels (hard surface)
- Decide triangulation tolerance for target engine
- Plan UV islands before committing topology

### Modeling
- Execute discipline-specific workflow (hard surface, organic, modular)
- Prefer modifier stack over destructive edits
- Keep naming and collections organized from start

### Cleanup
- Merge by distance (threshold appropriate to scale)
- Remove doubles, loose geometry, interior faces
- Apply transforms before export prep
- Verify normals (weighted normals for hard surface)

### UV Planning
- Mark seams at hidden/construction edges
- Plan texel density relative to screen size
- Separate material IDs if needed for engine

### UV Unwrapping
- Unwrap with consistent texel density
- Pack efficiently; minimize wasted space
- Create lightmap UVs for baked lighting if required

### Materials
- PBR or stylized per art direction
- **Match palette from reference analysis** when applicable
- Reuse master materials; instance variations
- **Emissive lights: per-object materials only** — never animate shared hull mats
- Limit unique material count for game assets

### Look Dev & Reference Compare
- Lighting pass before declaring materials done
- `get_viewport_screenshot` at hero camera vs reference
- Run `visual-match-checklist.md` when reference was provided

### Optimization
- Run asset-optimization validation
- Create LODs if required
- Collapse unnecessary subdivisions

### Rigging / Animation
- Only when asset requires deformation or motion
- Mechanical assets: constraints over weight painting
- Characters: animation-ready topology prerequisite

### Collision Planning
- Simple proxy meshes: box, capsule, convex hull
- Separate `COL_` collection; never export render mesh as collision

### Export
- Apply export-pipeline skill for target format
- Verify scale, axis, pivot, normals, animation

### Validation
- Run full checklist in `validation-checklist.md`
- **If reference image was used:** run `visual-match-checklist.md`
- Capture viewport renders from multiple angles
- Confirm game-ready status before delivery

## Pipeline by Asset Type

| Asset Type | Critical Phases | Typical Skills |
|------------|-----------------|----------------|
| Hard surface prop | Scale → Silhouette → Bevel → UV → PBR | hard-surface, materials, export-pipeline |
| Environment modular | Modular planning → Instances → Texel density | environment-artist, geometry-nodes, uv-workflow |
| Character | Anatomy → Topology → Retopo → Rig | character-artist, retopology, rigging |
| Creature | Anatomy → Sculpt → Retopo → Rig | creature-artist, sculpting, retopology |
| Procedural kit | Node design → Variation → Optimization | geometry-nodes, procedural-modeling |
| Cinematic set | Composition → Lighting → Rendering | lighting, rendering, realistic-style |
| **Reference image match** | Analysis → Camera → Tiers → Materials → Lighting → Compare | reference-image-match, blender-director, rendering |
````

### `references/mcp-integration.md`

````markdown
# Blender MCP Integration Rules

When Blender MCP is available, **execute operations through MCP** instead of describing manual UI steps.

**Setup:** See repo `docs/BLENDER_MCP_SETUP.md`. Project config: `.cursor/mcp.json` (Cursor) or `.mcp.json` (Claude Code).

**Tool catalog:** See `mcp-tools.md` for BlenderMCP capabilities and bpy fallbacks.

## Priority Order

1. Check MCP tool descriptors before any Blender operation
2. Read tool schemas for required parameters
3. Execute via MCP tools
4. Validate results via MCP scene queries
5. Only fall back to UI instructions if MCP lacks the capability

## MCP-First Operations

| Task | MCP Approach |
|------|--------------|
| Create objects | Use MCP object creation tools |
| Modify geometry | Use MCP mesh/edit tools |
| Apply modifiers | Use MCP modifier tools |
| UV operations | Use MCP UV tools if supported |
| Materials | Create/assign materials via MCP |
| Collections | Organize scene hierarchy via MCP |
| Export | Use MCP export tools |
| Validation | Query scene stats via MCP |

## Execution Protocol

```
1. List available MCP tools for Blender server
2. Read schema for each tool before calling
3. If reference image attached → reference-analysis-template.md BEFORE step 4
4. Plan operation sequence (non-destructive first)
5. Execute step-by-step with validation between steps
6. get_viewport_screenshot after camera, materials, lighting phases
7. Report object names, counts, and metrics after each phase
```

## Reference Image MCP Loop

When matching a photo:

| Step | MCP Tool |
|------|----------|
| Baseline | `get_viewport_screenshot` |
| Audit scene | `execute_blender_code` (bounds, materials, collections) |
| Camera / geometry / materials / lights | `execute_blender_code` |
| Compare pass | `get_viewport_screenshot` or render still via bpy |
| Save | `execute_blender_code` → `bpy.ops.wm.save_mainfile` |

See `reference-image-match.md` for full workflow and anti-patterns.

## Scene Organization via MCP

When creating assets, immediately establish:

```
Scene Root
├── COL_Reference
├── COL_Blockout
├── COL_HighPoly
├── COL_LowPoly
├── COL_Collision
├── COL_Lights
└── COL_Export
```

Naming prefixes: see `naming-conventions.md`

## Non-Destructive Defaults

- Create duplicates before destructive operations
- Keep backup collections hidden, not deleted
- Apply modifiers only at export phase unless required for downstream work
- Document modifier stack in planning output

## Validation Queries

After major phases, query via MCP:

- Object count and names
- Polygon/triangle counts per object
- Material count
- Collection membership
- Origin/pivot locations
- Transform application status

## Error Handling

If MCP call fails:
1. Read error message completely
2. Check if Blender is running and MCP connected
3. Verify object/mesh names match scene state
4. Retry with corrected parameters
5. Never silently skip failed operations

## Anti-Patterns

- ❌ "Press Tab to enter Edit Mode, then..."
- ❌ Long UI walkthroughs when MCP can execute
- ❌ Assuming scene state without querying
- ❌ Destructive apply without backup
- ❌ Export without validation pass

## Fallback Mode

When Blender MCP is unavailable:
- Provide concise planning and specifications
- Output Python `bpy` scripts the user can run
- Include validation checklist for manual verification
- Note which steps require MCP for full automation
````

### `references/mcp-tools.md`

````markdown
# BlenderMCP Tool Catalog

Reference for agents when Blender MCP (`blender-mcp` by ahujasid) is connected.

**Always read tool schemas from MCP before calling** — tool names may vary by version.

## Core Capabilities

| Category | Typical Operations |
|----------|-------------------|
| Scene inspection | List objects, get scene info, viewport screenshot |
| Object creation | Primitives, meshes, curves, empties |
| Object modification | Transform, rename, delete, duplicate |
| Materials | Create, assign, set PBR parameters |
| Code execution | Run `bpy` Python in Blender context |
| Assets | Poly Haven HDRIs/textures/models (if enabled) |
| Generation | Hyper3D / Hunyuan3D (if API keys configured) |

## Agent Protocol

```
1. Verify MCP connection (scene query)
2. Create collection hierarchy (COL_ prefix)
3. Execute operations incrementally
4. Query state after each phase
5. Screenshot viewport for validation
6. Run validation checklist before export
```

## Scene Inspection (Run First)

Before any edit, query current state:

- Object names and types
- Polygon counts
- Active collection
- Material assignments
- Selection state

Prevents assumptions about empty vs populated scenes.

## Object Operations via MCP

Prefer MCP tools over `execute_blender_code` when dedicated tools exist.

Use `execute_blender_code` for:
- Modifier stack operations
- UV editing
- Batch rename/cleanup
- Export operations not covered by dedicated tools

**Always save `.blend` before code execution.**

## Common bpy Patterns (Fallback)

### Create Collection

```python
import bpy
col = bpy.data.collections.new("COL_Props")
bpy.context.scene.collection.children.link(col)
```

### Rename Object

```python
obj.name = "SM_Crate_01"
obj.data.name = "SM_Crate_01"
```

### Apply Transforms

```python
bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
```

### Merge by Distance

```python
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.0001)
bpy.ops.object.mode_set(mode='OBJECT')
```

## Poly Haven Integration

When enabled in Blender addon:
- Search and import HDRIs for lighting
- Download PBR textures
- Import free 3D models

Use for rapid look-dev; verify license (CC0) for shipping assets.

## Viewport Screenshots

Request viewport captures to validate:
- Silhouette at gameplay angle
- Material appearance
- Lighting mood
- Scale vs reference object

## Export via Code (When No Export Tool)

```python
import bpy
bpy.ops.export_scene.fbx(
    filepath="C:/export/SM_Asset.fbx",
    use_selection=True,
    apply_scale_options='FBX_SCALE_ALL',
    axis_forward='-Z',
    axis_up='Y',
    object_types={'MESH', 'ARMATURE'},
    bake_anim=False
)
```

Adjust axis settings per target engine — see `export-pipeline` skill.

## Error Recovery

| Error | Action |
|-------|--------|
| Connection lost | Reconnect addon in Blender |
| Timeout | Break operation into smaller steps |
| Object not found | Re-query scene; verify name |
| Code execution error | Read traceback; fix; retry |

## Version Note

BlenderMCP evolves frequently. Tool names and parameters may differ from this reference. **MCP tool descriptors are authoritative.**

Source: [ahujasid/blender-mcp](https://github.com/ahujasid/blender-mcp)
````

### `references/naming-conventions.md`

````markdown
# Naming Conventions

Consistent naming enables pipeline automation, engine import, and team collaboration.

## Prefix Standards

| Type | Prefix | Example |
|------|--------|---------|
| Collections | `COL_` | `COL_Environment`, `COL_Props_Hero` |
| Meshes | `SM_` | `SM_Console_Panel_A` |
| Materials | `MAT_` | `MAT_Metal_Brushed_Steel` |
| Textures | `T_` | `T_Console_N`, `T_Console_BC` |
| Animations | `AN_` | `AN_Door_Open` |
| Armatures | `ARM_` | `ARM_Robot_Loader` |
| Geometry Node Groups | `GN_` | `GN_Scatter_Rocks` |
| Render Cameras | `CAM_` | `CAM_Hero_Shot_01` |
| Lights | `LGT_` | `LGT_Key_Main` |

## Mesh Naming Pattern

```
SM_[Category]_[Descriptor]_[Variant]

Examples:
SM_Weapon_Rifle_A
SM_Prop_Crate_Wood_01
SM_Env_Wall_Module_2m
SM_Char_Hero_Body
```

## Material Naming Pattern

```
MAT_[SurfaceType]_[Descriptor]

Examples:
MAT_Metal_Painted_Red
MAT_Fabric_Canvas_Dirty
MAT_Glass_Frosted
MAT_Emissive_Screen_Green
```

## Texture Naming Pattern

```
T_[Asset]_[MapType]

Map suffixes:
_BC  Base Color / Albedo
_N   Normal
_ORM Occlusion/Roughness/Metallic packed
_R   Roughness
_M   Metallic
_AO  Ambient Occlusion
_E   Emission
_H   Height
```

## Collection Hierarchy

```
COL_ProjectName
├── COL_Reference
├── COL_Blockout
├── COL_Geo
│   ├── COL_Geo_Hero
│   ├── COL_Geo_Background
│   └── COL_Geo_LOD
├── COL_Collision
├── COL_Lights
├── COL_Cameras
└── COL_Export
```

## LOD Naming

```
SM_AssetName_LOD0   (highest detail)
SM_AssetName_LOD1
SM_AssetName_LOD2
SM_AssetName_LOD3   (lowest / impostor)
```

## Collision Naming

```
SM_AssetName_COL     (simple proxy)
SM_AssetName_COL_UBX (Unreal box convention)
SM_AssetName_COL_UCX (Unreal convex)
```

## Rules

- Use PascalCase after prefix with underscores as separators
- No spaces; use underscores
- Sequential numbers: `_01`, `_02` not `_1`, `_2`
- Descriptive, not generic (`SM_Thing` is invalid)
- Match mesh name to material instance where 1:1
- Keep names under 64 characters for engine compatibility
````

### `references/polycount-budgets.md`

```markdown
# Polycount Budgets

Reference targets for game-ready assets. Adjust per project spec; these are AAA-informed defaults.

## Props

| Tier | Triangles | Use Case |
|------|-----------|----------|
| Hero | 15,000–50,000 | Player-held, close-up interactive |
| Standard | 5,000–15,000 | Scene props, mid-distance |
| Background | 500–5,000 | Distant filler, clutter |
| Small | 100–500 | Coins, bolts, small debris |

## Characters

| Tier | Triangles | Use Case |
|------|-----------|----------|
| Hero | 50,000–100,000 | Player character, cutscenes |
| Standard NPC | 20,000–40,000 | Background characters |
| Crowd | 5,000–10,000 | Distant crowds, impostors |
| Mobile hero | 15,000–30,000 | Mobile/ Switch targets |

## Environment

| Asset | Triangles | Notes |
|-------|-----------|-------|
| Modular wall (2m) | 200–800 | Repeats frequently |
| Modular floor tile | 100–400 | Instanced |
| Hero building section | 5,000–20,000 | Landmark structures |
| Rock (hero) | 1,000–5,000 | Scatter dependent |
| Tree (realistic) | 5,000–15,000 | Use cards/impostors at distance |
| Tree (stylized/lowpoly) | 200–2,000 | Style dependent |

## Vehicles

| Type | Triangles |
|------|-----------|
| Hero vehicle | 80,000–200,000 |
| Drivable (gameplay) | 30,000–80,000 |
| Background vehicle | 5,000–15,000 |

## Weapons

| Type | Triangles |
|------|-----------|
| First-person hero | 10,000–30,000 |
| Third-person | 5,000–15,000 |
| Background | 500–2,000 |

## Style Modifiers

| Style | Budget Adjustment |
|-------|-------------------|
| Lowpoly (PS1/PS2) | 50–90% reduction |
| Horror (sparse detail) | 30–50% reduction |
| Stylized | Similar to standard; detail in texture |
| Realistic AAA | Upper range; LODs mandatory |

## LOD Guidelines

| LOD | Triangle % | Distance Multiplier |
|-----|------------|---------------------|
| LOD0 | 100% | 0–10m |
| LOD1 | 50% | 10–25m |
| LOD2 | 25% | 25–50m |
| LOD3 | 10% | 50m+ |

## Texture Budgets

| Asset Tier | Resolution |
|------------|------------|
| Hero | 2048–4096 |
| Standard | 1024–2048 |
| Background | 512–1024 |
| Tiling surfaces | 1024–2048 (tiling) |
| Trim sheets | 2048–4096 shared |

## Validation

When polycount exceeds budget:
1. Remove unseen backfaces/interior geometry
2. Bake detail to normal maps
3. Reduce bevel segments on distant edges
4. Replace geometry with normal map detail
5. Create LOD chain before final approval
```

### `references/reference-analysis-template.md`

````markdown
# Reference Analysis Template

Copy and fill this **before any Blender MCP operations** when a reference image is provided.

```markdown
## Reference Analysis: [Asset Name]

**Reference:** [attached image / URL / description]
**Existing file:** [path or "new scene"]
**Target:** [game hero / cinematic / portfolio]
**Match goal:** [similar / close match / specific features only]

---

### 1. Subject Identification
- **Type:** [spaceship / prop / character / environment]
- **Style:** [realistic AAA / horror / stylized / lowpoly]
- **Forward axis:** [+Y / +X / other]
- **Scale estimate:** [L × W × H in meters]

### 2. Silhouette & Proportions
- **Primary masses:** [list 3–5 major forms]
- **Proportion notes:** [nose %, mid %, engine % of total length]
- **Shape language:** [blocky modular / curved / tapered / asymmetric]

### 3. Camera (match first)
- **Angle:** [3/4 starboard / side / low hero / top-down]
- **Lens feel:** [~24mm wide / ~35mm / ~50mm portrait]
- **Subject fill:** [% of frame width/height]
- **Planned setup:** `CAM_*` at [position estimate], target at [point]

### 4. Lighting
- **Key light:** [direction, color temp, hardness]
- **Fill:** [level — crushed shadows vs visible detail]
- **Rim/back:** [yes/no, direction]
- **Environment:** [black space / planet / studio / interior]
- **Planned lights:** [LGT_Key_Sun, LGT_Rim_*, etc.]

### 5. Color Palette (hex)
| Role | Hex | Notes |
|------|-----|-------|
| Hull light | # | |
| Hull dark | # | |
| Recess | # | |
| Trim / metal | # | |
| Glass | # | |
| Emissive warm | # | |
| Emissive cool | # | |
| Ambient / sky | # | |

### 6. Materials
- **Surface types:** [brushed metal / painted / rubber / glass]
- **Roughness range:** [matte 0.5+ / satin / gloss]
- **Weathering:** [none / light edge wear / heavy grime]
- **Unique shaders:** [emissive sensors, decals, glow windows]

### 7. Hero Features (must include)
- [ ] [feature 1 — e.g. QUADRILLION decal forward starboard]
- [ ] [feature 2 — e.g. red forward sensor]
- [ ] [feature 3]

### 8. Gap vs Current Scene (if upgrading existing .blend)
| Area | Reference | Current | Priority |
|------|-----------|---------|----------|
| | | | P0/P1/P2 |

### 9. Active Skills
1. blender-director
2. [discipline skill]
3. [style skill]
4. materials → lighting → rendering

### 10. MCP Phase Plan
1. Audit scene + baseline screenshot
2. Camera match
3. Geometry tier 1→2→3
4. Materials from palette
5. Lighting + world
6. Grading + render test
7. Screenshot compare → fix gaps (×3 max)
8. Save + validation
```

## Usage Rules

- **Do not skip** — even if the user says "just fix it quickly"
- **Palette hex values** are required — do not use generic grey without sampling reference
- **Gap table** is required when editing an existing file
- Keep analysis concise; execution matters more than long prose
````

### `references/reference-image-match.md`

````markdown
# Reference Image Match Workflow

**Mandatory when the user attaches a photo, concept art, or render and asks to match, recreate, or build "like this."**

Goal: produce a Blender result that is **visually similar** to the reference — silhouette, proportions, materials, lighting, camera, and mood. "Exact" pixel match is not realistic; **iterative visual convergence** is.

## Golden Rules

1. **Analyze the reference BEFORE any Blender operations** — output a Reference Analysis (see template below).
2. **Never skip the screenshot comparison loop** — render/viewport capture after every major phase.
3. **Execute via Blender MCP** — do not narrate UI steps when MCP is connected.
4. **Upgrade in place** when a `.blend` already exists — do not rebuild from scratch unless asked.
5. **Separate emissive lights from hull materials** — never keyframe shared structural materials (causes blown-out white hull).
6. **Match camera early** — wrong framing makes every other pass look wrong.
7. **Depth before micro-detail** — panel breaks, recesses, ribs, and silhouette tiers before tiny greebles.

## Workflow Overview

```
REFERENCE ANALYSIS (written brief)
        ↓
CAMERA + FRAMING MATCH
        ↓
SILHOUETTE + PROPORTION BLOCKOUT
        ↓
PRIMARY SHAPES + SECONDARY PANEL BREAKS
        ↓
TERTIARY GREEBLES + FEATURES
        ↓
MATERIALS + COLOR PALETTE
        ↓
LIGHTING + ENVIRONMENT
        ↓
RENDER SETTINGS + COLOR GRADING
        ↓
SCREENSHOT COMPARE → FIX GAP LIST → REPEAT (max 3 passes)
        ↓
VALIDATION (visual-match-checklist.md)
```

## Phase 0 — Reference Analysis (Required)

Before MCP execution, document:

| Category | Extract from image |
|----------|-------------------|
| **Subject** | Asset type, hero vs background, forward axis |
| **Silhouette** | Overall shape language (blocky, curved, tapered), major masses |
| **Proportions** | Length/width/height ratios, nose/tail/engine balance |
| **Camera** | Angle (3/4, side, low, high), lens feel (wide/normal/tele), subject fill % |
| **Lighting** | Key direction, fill level, rim/back light, ambient color |
| **Materials** | Metal vs paint vs glass; roughness (matte/satin/gloss); weathering level |
| **Color palette** | 5–8 hex values: hull light, hull dark, recess, trim, emissive, sky/ambient |
| **Unique features** | Decals, windows, antennas, planet/env, volumetrics |
| **Mood** | Industrial, horror, cinematic, retro, clean sci-fi |

Output format: use `reference-analysis-template.md`.

## Phase 1 — Camera Match

Match the reference framing before detailing geometry.

```
CAM_[Asset]_Hero  +  EMPTY_CamTarget_[Subject]
```

| Reference signal | Camera setup |
|------------------|--------------|
| Full vehicle in frame | Wide lens (24–32mm), TRACK_TO ship center/midship |
| Nose/bridge close-up | 40–50mm, target forward section (+Y forward ships) |
| Low orbit cinematic | Elevated 3/4, key light from upper-left |
| Side profile | Orthographic feel: camera perpendicular to longest axis |

**MCP validation:** `get_viewport_screenshot` at Numpad 0 camera view. Compare subject size and angle to reference.

## Phase 2 — Geometry Match (Least → Most Detail)

Build in three tiers so the asset stops looking "boxy" early:

### Tier 1 — Silhouette (blockout)
- Primary masses only; correct proportions vs reference
- Forward axis and scale locked (1 unit = 1 meter)
- Screenshot: silhouette overlay check at reference camera angle

### Tier 2 — Panel breaks (depth)
- Horizontal ribs, vertical stiffeners, belt lines, keel strips
- Recessed bays, inset panels, stepped noses
- Raised spine segments, module offsets
- **Use cylinders, torus, chamfered boxes** — break 90° corners

### Tier 3 — Greebles + hero features
- Pipes, vents, antennas, windows, lights, decals
- Reference-specific features (logo, sensor, dish, planet placeholder)

**Anti-pattern:** 200 identical tiny cubes at origin. **Pattern:** Named, positioned, parented parts on hull surfaces.

## Phase 3 — Materials Match

Extract palette from reference analysis. Limit unique materials (8–12 hero assets).

| Reference look | Shader approach |
|--------------|-----------------|
| Matte weathered metal | Principled: metallic 0.85–1.0, roughness 0.45–0.65, noise variation |
| Dark recesses | Separate `MAT_*_Recess`, very low base color, roughness 0.7+ |
| Panel contrast | Light/dark hull pair, ΔL ≥ 15% between adjacent panels |
| Glass / windows | Transmission + low emission; static strength (no shared blink) |
| Emissive lights | **Per-object** `MAT_LightInst_*` materials only |
| Decals | Emission or transparent BSDF; white/industrial lettering |

See `realistic-style/references/pbr-values.md` and `materials/references/surface-recipes.md`.

**Never:** animate `Emission Strength` on `MAT_Hull_*` or other multi-user structural materials.

## Phase 4 — Lighting Match

| Reference lighting | Setup |
|-------------------|--------|
| Strong sun, hard shadows | `LGT_Key_Sun` SUN, energy 3–8, angle 2–5° |
| Space / orbit | Dark world (strength 0.08–0.15), no flat gray background |
| Rim separation | `LGT_Rim_*` area/spot from behind-above |
| Fill in shadows | Low `LGT_Fill_*` or slight world ambient — avoid pure black crush |
| Planet / nebula | World shader or `SM_Env_*` placeholder sphere |

Activate **lighting** skill. Match key direction first; tune energy second.

## Phase 5 — Rendering + Grading Match

| Task | Preview (playback) | Final quality |
|------|-------------------|---------------|
| Engine | EEVEE — sharp animation preview | Cycles or EEVEE per target |
| Motion blur | Off during preview | On only if reference shows blur |
| DOF | Off unless reference is shallow | Match focus subject |
| Color management | AgX | Match reference contrast |
| Exposure | 0.2–0.45 typical space scenes | Adjust until hull readable |
| Look | AgX Base Contrast default | High Contrast if reference is punchy |

**Playback blur fix:** EEVEE + `taa_samples` 1–8 + motion blur off + no Cycles viewport during animation scrub.

Activate **rendering** skill for pass output and final stills.

## Phase 6 — Screenshot Comparison Loop

After each phase, capture and compare:

```
1. get_viewport_screenshot (or render still at hero camera)
2. List GAPS vs reference (max 5 prioritized items)
3. Fix gaps via MCP
4. Re-screenshot
5. Repeat until PASS or 3 iterations
```

### Gap categories (prioritize top-down)

1. Camera / framing wrong
2. Silhouette / proportions wrong
3. Too flat / boxy (missing tier-2 breaks)
4. Materials too uniform / wrong value range
5. Lighting direction or exposure wrong
6. Missing hero features (decals, windows, env)
7. Micro-detail density mismatch

## Skill Routing (Reference Tasks)

```
blender-director
  → reference-image-match (this doc)
  → [discipline: hard-surface | environment-artist | character-artist]
  → [style: realistic-style | horror-style | stylized-style | lowpoly-style]
  → materials → lighting → rendering
  → visual-match-checklist → validation-checklist
```

## MCP Execution Checklist

- [ ] `get_scene_info` or audit script — bounds, collections, materials
- [ ] `get_viewport_screenshot` — baseline before changes
- [ ] Reference analysis written
- [ ] Camera + target empty positioned
- [ ] Geometry tiers 1→2→3
- [ ] Materials from extracted palette
- [ ] Lights + world
- [ ] Grading (AgX exposure/look)
- [ ] Comparison screenshot vs reference
- [ ] Gap list + fixes
- [ ] `save_mainfile`
- [ ] Validation report

## Common Failures (Fix Immediately)

| Symptom | Cause | Fix |
|---------|-------|-----|
| Entire ship white when animating | Emission keyed on shared hull material | Per-light materials; clear structural mat animation |
| Black camera view | Camera inside mesh or no lights | Reposition CAM; boost key + world |
| Boxy, toy-like | Tier-2 panel breaks skipped | Ribs, belts, recesses, chamfers before greebles |
| Reference angle wrong | Camera not matched first | TRACK_TO target; match lens and position |
| Blurry on spacebar | Cycles viewport + low samples | EEVEE preview; motion blur off |
| Flat grey clay | No lighting / no material contrast | Sun + rim; light/dark panel pair |
| Details float at origin | Parent/position not set | Parent to root; place on hull surface |

## Good User Prompts

- "Match this photo — industrial freighter, matte grey hull, strong upper-left sun, full ship in frame"
- "Upgrade existing ship in `spacecraft.blend` to match attached reference; do not rebuild"
- "Reference attached. Analyze first, then camera match, then materials and lighting"
- "Iterate until viewport matches reference — screenshot compare after each pass"

## Delivery

Include in completion message:

- Reference analysis summary (palette + camera + lighting)
- Before/after screenshot description
- Remaining gaps (if any) with honest assessment
- File path saved
- Active skills used
````

### `references/validation-checklist.md`

````markdown
# Asset Validation Checklist

Run before marking any asset complete. Query scene via Blender MCP when available.

## Scale & Transform

- [ ] Correct real-world scale (1 unit = 1 meter unless project specifies otherwise)
- [ ] Origin at logical pivot (floor contact, grip point, hinge axis)
- [ ] All transforms applied (scale 1,1,1 / rotation 0,0,0 where required)
- [ ] Object faces correct forward axis for target engine (typically -Y or +X)

## Topology

- [ ] Clean topology; no n-gons on deforming areas
- [ ] Quad-dominant mesh
- [ ] No duplicate vertices (merge threshold verified)
- [ ] No loose vertices/edges/faces
- [ ] No internal faces or non-manifold geometry
- [ ] Correct normals (no inverted faces)
- [ ] Hard edges use weighted normals or sharp edges as appropriate

## UVs

- [ ] Efficient UV layout; minimal wasted space
- [ ] Consistent texel density across visible surfaces
- [ ] Seams placed at hidden/construction edges
- [ ] No overlapping UVs (unless intentional mirroring)
- [ ] Lightmap UV channel if engine requires baked lighting

## Materials & Textures

- [ ] Minimal material count (target: 1-3 for props, per project spec)
- [ ] PBR values physically plausible or intentionally stylized
- [ ] Texture resolution matches budget (512/1024/2048/4096)
- [ ] No unused material slots
- [ ] Material names follow `MAT_` convention

## Organization

- [ ] Collections organized per `naming-conventions.md`
- [ ] Meaningful object names with `SM_` prefix
- [ ] Modifier stack documented or collapsed per export requirements
- [ ] Reference/blockout geometry in separate collections
- [ ] Collision meshes in `COL_Collision`

## Performance

- [ ] Polycount within budget (see `polycount-budgets.md`)
- [ ] Triangle count verified
- [ ] LODs created if required
- [ ] Instances used for repeated geometry
- [ ] Geometry nodes baked if runtime performance requires

## Export Readiness

- [ ] Export format confirmed (FBX/GLTF/USD/etc.)
- [ ] Animation/armature export tested if applicable
- [ ] Materials export or texture paths documented
- [ ] Pivot and scale verified in target engine
- [ ] Naming compatible with import pipeline

## Game Ready

- [ ] Readable silhouette at gameplay distance
- [ ] Collision proxy created and simplified
- [ ] No unnecessary high-poly detail on hidden surfaces
- [ ] Asset modular/reusable if part of kit
- [ ] Style consistent with project art direction

## Visual Match (Reference Image Tasks)

When user provided a reference photo/concept, also run `visual-match-checklist.md`.

- [ ] Reference analysis documented before execution
- [ ] Hero camera angle matches reference (Match or Close)
- [ ] Silhouette and proportions Match or Close
- [ ] Panel depth / not boxy (tier-2 breaks present)
- [ ] Palette matches reference value range
- [ ] Key light direction matches reference
- [ ] Grading/exposure: hull readable, not blown white
- [ ] Screenshot comparison performed (≥1 iteration)
- [ ] No shared structural material emission animation
- [ ] Animation playback sharp (EEVEE preview if animating)

## Validation Output Template

```markdown
## Validation Report: [Asset Name]

**Status:** PASS / FAIL
**Polycount:** [tris] (budget: [target])
**Materials:** [count]
**UV Efficiency:** [%]
**Scale:** [dimensions]

### Issues Found
- [issue + fix applied]

### Screenshots
- Front / Side / Top / 3/4 views verified
```
````

### `references/visual-match-checklist.md`

````markdown
# Visual Match Checklist

Run after geometry, materials, lighting, and grading when a **reference image** was provided. Use with `get_viewport_screenshot` or hero camera render.

**Pass threshold:** ≥ 8/10 categories rated "Match" or "Close". Document remaining gaps honestly.

## Comparison Method

1. Place reference image beside viewport screenshot (same camera angle).
2. Rate each category: **Match** / **Close** / **Miss**
3. For each **Miss**, add one actionable fix to the gap list.
4. Re-run after fixes (max 3 iterations).

---

## Camera & Composition

- [ ] Subject faces same general direction as reference
- [ ] Same viewing angle (3/4, side, low, high) — not reversed or top-down mismatch
- [ ] Subject occupies similar % of frame
- [ ] Horizon / vanishing consistent with reference
- [ ] Numpad 0 hero camera usable for review

## Silhouette & Proportions

- [ ] Overall length/width/height ratio reads similarly
- [ ] Major masses in correct positions (nose, mid, tail, engines)
- [ ] No missing large forms visible in reference
- [ ] No extra masses that contradict reference
- [ ] Readable at gameplay/mid distance (not only close-up)

## Depth & Surface Breakup

- [ ] Not a single flat box — panel lines, ribs, or steps visible
- [ ] Recessed vs raised areas create value contrast
- [ ] Chamfers/cylinders break 90° corners where reference shows them
- [ ] Greeble density in same ballpark (not empty or overcrowded)
- [ ] Windows, ports, vents placed on hull surfaces (not floating)

## Materials & Color

- [ ] Hull value range matches (dark enough, not blown white)
- [ ] Light/dark panel contrast present
- [ ] Metal reads as metal (roughness/specular appropriate)
- [ ] Glass/windows distinct from hull
- [ ] Emissive lights correct color (red nav, green starboard, etc.)
- [ ] Decals/logos present if in reference
- [ ] No shared-material animation blowing out hull

## Lighting

- [ ] Key light from same general direction as reference
- [ ] Shadow side not pure black unless reference is
- [ ] Rim/separation on subject edge if reference shows it
- [ ] Emissive elements visible but not overpowering
- [ ] Environment mood matches (space black vs studio vs planet glow)

## Rendering & Grading

- [ ] AgX (or project) color management active
- [ ] Exposure: hull detail visible, highlights not clipped
- [ ] Contrast level similar to reference
- [ ] Animation playback sharp (EEVEE preview settings)
- [ ] Final still acceptable at 1280×720+ hero camera

## Feature Checklist (customize per asset)

- [ ] _[Hero feature 1 from reference analysis]_
- [ ] _[Hero feature 2]_
- [ ] _[Hero feature 3]_

---

## Visual Match Report Template

```markdown
## Visual Match Report: [Asset Name]

**Reference:** [description]
**File:** [path]
**Iteration:** [1/2/3]
**Overall:** PASS / PARTIAL / FAIL

| Category | Rating | Notes |
|----------|--------|-------|
| Camera | Match/Close/Miss | |
| Silhouette | | |
| Depth | | |
| Materials | | |
| Lighting | | |
| Grading | | |

### Top Gaps (fix next)
1. 
2. 
3. 

### Screenshots
- Hero camera render captured: yes/no
- Compared to reference: yes/no
```

## Auto-Fail Conditions

Fail immediately and fix before delivery if any are true:

- Camera shows wrong side of subject (e.g. rear instead of hero 3/4)
- Hull turns fully white during animation playback
- Reference requested full ship but camera shows only a small section
- Structural materials have emission keyframes
- Export mesh visible in viewport blocking review
````
