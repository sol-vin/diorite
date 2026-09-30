# Diorite 💎
### High-Performance 2D & 3D Debug Drawing Plugin & Frame DSL for Godot Engine 4.8+

[![CI](https://github.com/sol-vin/diorite/actions/workflows/ci.yml/badge.svg)](https://github.com/sol-vin/diorite/actions/workflows/ci.yml)
[![Docs](https://github.com/sol-vin/diorite/actions/workflows/docs.yml/badge.svg)](https://sol-vin.github.io/diorite/)
[![Crystal](https://img.shields.io/badge/Crystal-1.21.0-blue.svg)](https://crystal-lang.org)
[![Godot](https://img.shields.io/badge/Godot-4.8--dev6-478cbf.svg)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Diorite** is a debug drawing plugin and immediate-mode DSL for **Godot 4.8+** powered by the **Lapis** Crystal toolchain. Inspired by tools like Godot's DebugDraw3D and Raylib's immediate drawing functions, Diorite provides **both** a node-based scene workflow and a zero-allocation frame-based DSL for real-time visualization.

📖 **Full API & Architecture Documentation**: [https://sol-vin.github.io/diorite/](https://sol-vin.github.io/diorite/)

All debug primitives render with **highest visual priority**:
- **3D**: Unshaded `StandardMaterial3D` with depth testing disabled (`FlagDisableDepthTest = true`) and `render_priority = 127`.
- **2D**: Rendered onto an overlay `CanvasLayer` at `layer = 128` with `z_index = 4096` (`z_as_relative = false`).

---

## ⚡ Performance Benchmarks

Diorite was engineered from the ground up for extreme throughput and zero-allocation runtime performance. Benchmarks measured on Crystal 1.21.0:

| Category | Benchmark Routine | Throughput | Latency | Allocation |
|---|---|---|---|---|
| **Vector Transforms** | `MathHelpers.find_perpendicular` | **15.02 M ops/sec** | 66.56 ns | **0.0 B/op** |
| **Vector Transforms** | `MathHelpers.orthonormal_plane` | **7.15 M ops/sec** | 139.85 ns | **0.0 B/op** |
| **Vector Transforms** | `MathHelpers.rotate_around_axis` | **8.76 M ops/sec** | 114.21 ns | **0.0 B/op** |
| **3D Primitives** | `3D Line` | **7.90 M ops/sec** | 126.63 ns | **0.0 B/op** |
| **3D Primitives** | `3D Arrow` | **669.85 k ops/sec** | 1.49 µs | 96.0 B/op |
| **3D Primitives** | `3D Box (12 edges)` | **769.05 k ops/sec** | 1.30 µs | **0.0 B/op** |
| **3D Primitives** | `3D Camera Frustum` | **628.66 k ops/sec** | 1.59 µs | **0.0 B/op** |
| **3D Primitives** | `3D Sphere (16 rings)` | **146.31 k ops/sec** | 6.83 µs | **0.0 B/op** |
| **3D Primitives** | `3D Grid (10x10 subs)` | **288.30 k ops/sec** | 3.47 µs | **0.0 B/op** |
| **3D Primitives** | `3D Trajectory Arc (20 steps)` | **138.04 k ops/sec** | 7.24 µs | **0.0 B/op** |
| **2D Primitives** | `2D Line` | **9.26 M ops/sec** | 108.04 ns | **0.0 B/op** |
| **2D Primitives** | `2D Arrow` | **2.76 M ops/sec** | 361.94 ns | **0.0 B/op** |
| **2D Primitives** | `2D Rect` | **2.81 M ops/sec** | 356.13 ns | **0.0 B/op** |
| **2D Primitives** | `2D Circle (24 segs)` | **210.34 k ops/sec** | 4.75 µs | **0.0 B/op** |
| **Queue Operations** | Batch Enqueue 10,000 Commands | **2.01 M cmds/sec** | 4.95 ms / 10k | Fast Push |
| **Queue Operations** | Step & Decay 10,000 Commands | **20.04 M cmds/sec** | 0.49 ms / 10k | Fast Reject |
| **Queue Operations** | Clear Queue | **250.0 M ops/sec** | 4.0 µs / 10k | Instant |
| **Telemetry Ingestion** | `TelemetryGraph#add_sample` | **24.20 M ops/sec** | 41.33 ns | **0.0 B/op** |
| **Telemetry Render** | `TelemetryGraph#build_geometry` | **63.84 k fps** | 15.66 µs | **0.0 B/op** |
| **Heavy Simulation** | **700 Mixed Shapes per Frame** | **4,590 frames/sec** | **0.21 ms / frame** | 108 kB / frame |

> In a 60 FPS frame budget (16.6 milliseconds), drawing 700 mixed 2D and 3D shapes takes only **0.21 ms (~1.3% of the frame budget)**.

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
24. **Distance Measurement Ruler** (`ruler_3d`): Calibrated measurement bar with tick marks and automatic midpoint readout.
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
  max_time: 2.0,
  steps: 25
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
│   ├── ci.yml               # Multi-platform CI (Specs, Benchmarks, Godot Headless Smoke Test)
│   └── docs.yml             # Automatic Lapis documentation generation & GitHub Pages deployment
├── addons/
│   ├── crystal_integration/ # Lapis Crystal GDExtension integration
│   └── diorite/             # Diorite Godot addon manifest & plugin
│       ├── plugin.cfg
│       ├── diorite.gd
│       └── diorite.gdextension
├── bench/
│   └── benchmark_suite.cr   # Comprehensive benchmark suite (IPS & Benchmark.bm)
├── docs_src/                # Source documentation in YAML for lapis docs compiler
├── docs/                    # Compiled static documentation site
├── scenes/
│   └── main.tscn            # Showcase test scene demonstrating all 26 items
├── spec/                    # Pure Crystal unit test suite (37 specs across 5 suites)
│   ├── geometry_builder_spec.cr
│   ├── math_helpers_spec.cr
│   ├── dsl_spec.cr
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

## 🧪 Testing & Benchmarking

### Running Unit Specs (37 specs)
Diorite contains comprehensive unit specs covering all 26 geometric builders, vertex counts, color assignments, telemetry ring buffers, math helpers, edge cases, and command queue duration decay:

```bash
crystal spec
```

### Running Benchmark Suite
```bash
crystal run bench/benchmark_suite.cr
```

### Building Documentation via `lapis docs`
```bash
lapis docs --github=sol-vin/diorite
```

### Running Headless Godot Smoke Test
```bash
lapis run -q 5
```

---

## 📄 License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
