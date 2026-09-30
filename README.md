# Diorite 💎
### High-Performance 2D & 3D Debug Drawing Plugin & Frame DSL for Godot Engine 4.8+

[![CI](https://github.com/sol-vin/diorite/actions/workflows/ci.yml/badge.svg)](https://github.com/sol-vin/diorite/actions/workflows/ci.yml)
[![Crystal](https://img.shields.io/badge/Crystal-1.21.0-blue.svg)](https://crystal-lang.org)
[![Godot](https://img.shields.io/badge/Godot-4.8--dev6-478cbf.svg)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Diorite** is a debug drawing plugin and immediate-mode DSL for **Godot 4.8+** powered by the **Lapis** Crystal toolchain. Inspired by tools like Godot's DebugDraw3D and Raylib's immediate drawing functions, Diorite provides **both** a node-based scene workflow and a zero-allocation frame-based DSL for real-time visualization.

All debug primitives render with **highest visual priority**:
- **3D**: Unshaded `StandardMaterial3D` with depth testing disabled (`FlagDisableDepthTest = true`) and `render_priority = 127`.
- **2D**: Rendered onto an overlay `CanvasLayer` at `layer = 128` with `z_index = 4096` (`z_as_relative = false`).

---

## ✨ Features

Diorite ships with **26 debug visualization items** (16 standard + 10 innovative):

### 1. Standard Items (16)
1. **Line 3D** (`line_3d`): Single segment between two 3D vectors.
2. **Arrow 3D** (`arrow_3d`): Directional vector with conical arrowhead.
3. **Line with Arrow 3D**: Convenience combination line with terminal arrowhead.
4. **Line Path 3D** (`line_path_3d`): Continuous polyline through an array of points.
5. **Box 3D** (`box_3d`): Axis-aligned wireframe bounding box with configurable center and extents.
6. **Sphere 3D** (`sphere_3d`): 3-axis orthogonal ring wireframe sphere.
7. **Cylinder 3D** (`cylinder_3d`): Circular top/bottom caps with longitudinal column struts.
8. **Capsule 3D** (`capsule_3d`): Hemispherical capped cylinder wireframe.
9. **Plane 3D** (`plane_3d`): Oriented rectangular quad grid with normal indicator.
10. **Points 3D** (`points_3d`): Collection of 3D point markers (small 3-axis crosshairs).
11. **Position 3D** (`position_3d`): 3-axis RGB crosshair indicating world position and scale.
12. **Gizmo 3D** (`gizmo_3d`): Basis transform indicator with Red=X, Green=Y, Blue=Z coordinate axes.
13. **Grid 3D** (`grid_3d`): Multi-subdivision ground reference plane wireframe.
14. **Camera Frustum 3D** (`camera_frustum_3d`): Projected view pyramid with near/far clipping planes.
15. **Billboard Opaque Square 3D** (`billboard_square_3d`): Camera-facing quad marker.
16. **Text 3D** (`text_3d`): World-positioned 3D billboard text labels with depth priority.

### 2. Innovative Items (10)
17. **Raycast Hit Visualizer** (`raycast_hit_3d`): Ray path + surface hit disk + surface normal reflection vector.
18. **Trajectory Arc** (`trajectory_arc_3d`): Ballistic projectile path computed under gravity with landing footprint.
19. **Vision / Sensor Cone** (`vision_cone_3d`): Spherical sector cone visualizing AI detection FOV and hearing range.
20. **Oriented Bounding Box (OBB)** (`obb_3d`): Arbitrarily rotated 3D wireframe box defined by a `Basis` transform.
21. **Motion Trail** (`trail_3d`): Smooth history trail following any moving entity over time.
22. **Helical Spring** (`spring_3d`): 3D wire spiral for physics constraints, suspension, and raycast springs.
23. **Surface Contact Disk** (`surface_contact_3d`): Normal-aligned circular disc indicating collision contacts.
24. **Distance Measurement Ruler** (`ruler_3d`): Calibrated measurement bar with tick marks between two points.
25. **3D Reticle** (`reticle_3d`): Circular weapon aim target or lock-on circle with corner brackets.
26. **2D Telemetry Sparkline Graph** (`telemetry_graph_2d`): Real-time scrolling performance and variable graph overlay.

---

## 🚀 Usage

### Mode 1: Frame-Based DSL (`DebugDraw.*`)

Call anywhere in your game logic (e.g. `_process`, `_physics_process`, or event handlers). Primitives redraw every frame or persist for a timed duration:

```crystal
require "lapis"
require "diorite"

# Single-frame draw (cleared next frame)
DebugDraw.line_3d(Vector3.new(0, 0, 0), Vector3.new(0, 5, 0), Color.new(0, 1, 0))
DebugDraw.sphere_3d(center: player.position, radius: 1.5, color: Color.new(1, 0, 0))

# Timed duration (persists in world for specified seconds)
DebugDraw.box_3d(center: hit_pos, size: Vector3.new(1, 1, 1), duration: 3.0)

# Innovative items
DebugDraw.vision_cone_3d(
  origin: guard.position,
  direction: guard.forward,
  angle_deg: 45.0,
  range: 12.0,
  color: Color.new(1, 0.8, 0.2)
)

DebugDraw.trajectory_arc_3d(
  origin: cannon.position,
  velocity: Vector3.new(10, 15, 0),
  gravity: Vector3.new(0, -9.8, 0),
  time_step: 0.05,
  subdivisions: 30
)

# 2D Telemetry sparkline
DebugDraw.telemetry_graph_2d(
  "FPS",
  current_fps,
  rect: Rect2.new(20, 20, 180, 50),
  color: Color.new(0.2, 1.0, 0.4)
)

# Block DSL syntax
DebugDraw.frame do |d|
  d.position_3d(actor.position)
  d.text_3d(actor.position + Vector3.new(0, 2, 0), "Health: 100")
end
```

### Mode 2: Node-Based System

Add Diorite nodes directly into your Godot scene tree. Fully configurable in the Godot Inspector and live-rendered in editor tool mode:

| Node | Description |
|---|---|
| `DebugDrawManager` | Central coordinator node that manages batch `ImmediateMesh` rendering and label pools. |
| `DebugBox3D` | Inspector-configurable wireframe 3D box. |
| `DebugSphere3D` | Inspector-configurable wireframe 3D sphere. |
| `DebugCylinder3D` | Inspector-configurable wireframe 3D cylinder. |
| `DebugCapsule3D` | Inspector-configurable wireframe 3D capsule. |
| `DebugLine3D` | Configurable line vector node. |
| `DebugArrow3D` | Configurable directional arrow node. |
| `DebugAxes3D` | 3-axis position coordinate node. |
| `DebugGrid3D` | Configurable ground grid plane node. |
| `DebugVisionCone3D` | Field-of-view sensor cone node. |
| `DebugSpring3D` | Physics spring visualizer node. |
| `DebugRuler3D` | Calibrated distance ruler node. |
| `DebugShape2D` | Configurable 2D debug shape (Line, Arrow, Rect, Circle). |

---

## 🛠️ Project Structure

```
diorite/
├── .github/workflows/
│   └── ci.yml               # Multi-platform CI (Crystal specs + Godot headless test)
├── addons/
│   ├── crystal_integration/ # Lapis Crystal GDExtension integration
│   └── diorite/             # Diorite Godot addon manifest & plugin
│       ├── plugin.cfg
│       ├── diorite.gd
│       └── diorite.gdextension
├── scenes/
│   └── main.tscn            # Showcase test scene demonstrating all 26 items
├── spec/                    # Pure Crystal unit test suite (24 specs)
│   ├── geometry_builder_spec.cr
│   ├── dsl_queue_spec.cr
│   ├── telemetry_graph_spec.cr
│   └── spec_helper.cr
├── src/
│   ├── demo/                # Showcase demo controller
│   │   └── demo_controller.cr
│   ├── diorite/
│   │   ├── core/            # Geometry builder, math, material, command queues, DSL
│   │   ├── nodes/           # Node-based 3D and 2D debug shapes & manager
│   │   └── diorite.cr       # Addon entry point
│   └── main.cr              # Project root game entry point
├── project.godot            # Godot 4.8 engine project configuration
├── shard.yml                # Crystal dependency manifest
└── godot-version.yml        # Target Godot version specification (4.8-dev6)
```

---

## 🧪 Testing

### Running Unit Specs
Diorite contains comprehensive unit specs covering all 26 geometric builders, vertex counts, color assignments, telemetry ring buffers, and command queue duration decay:

```bash
crystal spec
```

### Running Headless Godot Smoke Test
```bash
lapis run -q 5
```

---

## 📄 License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
