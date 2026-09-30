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
| **3D Sweeps** | `SphereCast (12 rings + rays)` | **110.45 k ops/sec** | 9.05 µs | **0.0 B/op** |
| **3D Sweeps** | `BoxCast (2 boxes + 8 edges)` | **452.10 k ops/sec** | 2.21 µs | **0.0 B/op** |
| **3D Splines** | `Cubic Bézier (32 segs)` | **195.40 k ops/sec** | 5.12 µs | **0.0 B/op** |
| **3D Splines** | `Catmull-Rom Spline (20 pts)` | **68.20 k ops/sec** | 14.66 µs | **0.0 B/op** |
| **2D Primitives** | `2D Line` | **9.26 M ops/sec** | 108.04 ns | **0.0 B/op** |
| **2D Primitives** | `2D Arrow` | **2.76 M ops/sec** | 361.94 ns | **0.0 B/op** |
| **2D Primitives** | `2D Rect` | **2.81 M ops/sec** | 356.13 ns | **0.0 B/op** |
| **2D Primitives** | `2D Circle (24 segs)` | **210.34 k ops/sec** | 4.75 µs | **0.0 B/op** |
| **Data Charts** | `2D Pie Chart (3 slices)` | **215.80 k ops/sec** | 4.63 µs | **0.0 B/op** |
| **Data Charts** | `3D Donut Chart (3 slices)` | **142.60 k ops/sec** | 7.01 µs | **0.0 B/op** |
| **Data Charts** | `2D Bar Chart (3 bars)` | **340.20 k ops/sec** | 2.94 µs | **0.0 B/op** |
| **Data Charts** | `2D Radial Gauge` | **188.40 k ops/sec** | 5.31 µs | **0.0 B/op** |
| **Queue Operations** | Batch Enqueue 10,000 Commands | **2.01 M cmds/sec** | 4.95 ms / 10k | Fast Push |
| **Queue Operations** | Step & Decay 10,000 Commands | **20.04 M cmds/sec** | 0.49 ms / 10k | Fast Reject |
| **Queue Operations** | Clear Queue | **250.0 M ops/sec** | 4.0 µs / 10k | Instant |
| **Telemetry Ingestion** | `TelemetryGraph#add_sample` | **24.20 M ops/sec** | 41.33 ns | **0.0 B/op** |
| **Telemetry Render** | `TelemetryGraph#build_geometry` | **63.84 k fps** | 15.66 µs | **0.0 B/op** |
| **Heavy Simulation** | **700 Mixed Shapes per Frame** | **4,590 frames/sec** | **0.21 ms / frame** | 108 kB / frame |

> In a 60 FPS frame budget (16.6 milliseconds), drawing 700 mixed 2D and 3D shapes takes only **0.21 ms (~1.3% of the frame budget)**.

---

## ✨ Features & Visualization Suite

Diorite ships with **35+ debug visualization items and developer UX helpers**:

### 1. Standard 3D Items
- **Line 3D** (`line_3d`): Single segment between two 3D vectors.
- **Arrow 3D** (`arrow_3d`): Directional vector with conical arrowhead.
- **Line with Arrow 3D**: Convenience combination line with terminal arrowhead.
- **Line Path 3D** (`line_path_3d`): Continuous polyline through an array of points.
- **Box 3D** (`box_3d`): Axis-aligned wireframe bounding box with configurable center and extents.
- **Sphere 3D** (`sphere_3d`): 3-axis orthogonal ring wireframe sphere.
- **Cylinder 3D** (`cylinder_3d`): Circular top/bottom caps with longitudinal column struts.
- **Capsule 3D** (`capsule_3d`): Hemispherical capped cylinder wireframe.
- **Plane 3D** (`plane_3d`): Oriented rectangular quad grid with normal indicator.
- **Points 3D** (`points_3d`): Collection of 3D point markers (small 3-axis crosshairs).
- **Position 3D** (`position_3d`): 3-axis RGB crosshair indicating world position and scale.
- **Gizmo 3D** (`gizmo_3d`): Basis transform indicator with Red=X, Green=Y, Blue=Z coordinate axes.
- **Grid 3D** (`grid_3d`): Multi-subdivision ground reference plane wireframe.
- **Camera Frustum 3D** (`camera_frustum_3d`): Projected view pyramid with near/far clipping planes.
- **Billboard Opaque Square 3D** (`billboard_square_3d`): Camera-facing quad marker.
- **Text 3D** (`text_3d`): World-positioned 3D billboard text labels with depth priority.

### 2. Game-Dev Spatial Helpers & Swept Shape Casts
- **SphereCast 3D** (`sphere_cast_3d`): Swept collision sphere with tangent boundary rays and impact indicators.
- **CapsuleCast 3D** (`capsule_cast_3d`): Swept character capsule with cylindrical rail connectors.
- **BoxCast 3D** (`box_cast_3d`): Swept bounding box query with 8 corner connector rays.
- **Cubic Bézier 3D** (`bezier_cubic_3d`): Smooth polynomial curve with optional control hull.
- **Catmull-Rom Spline 3D** (`catmull_rom_3d`): Smooth multi-waypoint patrol or trajectory curve.
- **Actor Card 3D** (`actor_card_3d`): Overhead billboard frame with ground anchor pole and key-value stat blocks.
- **Vision Cone 3D** (`cone_3d` / `vision_cone_3d`): Swept spotlight or AI detection cone.
- **Planar Circle 3D** (`circle_3d`): Arbitrarily oriented 3D circular ring.
- **Raycast Hit Visualizer** (`ray_hit_3d`): Ray path + surface hit point + surface normal reflection.
- **Trajectory Arc** (`trajectory_arc_3d`): Ballistic projectile path computed under gravity.
- **Oriented Bounding Box (OBB)** (`obb_3d`): Arbitrarily rotated 3D wireframe box defined by a `Basis`.
- **Motion Trail** (`trail_3d`): Smooth history trail following any moving entity over time.
- **Helical Spring** (`spring_3d`): 3D wire spiral for physics constraints and raycast suspension.
- **Surface Contact Disk** (`surface_disk_3d`): Normal-aligned circular disc indicating contact patches.
- **Distance Measurement Ruler 3D** (`ruler_3d`): Calibrated measurement bar with tick marks and automatic midpoint readout.
- **3D Reticle** (`reticle_3d`): Weapon aim target or lock-on circle with corner brackets.

### 3. Data Visualization & Charting
- **Pie & Donut Charts 2D & 3D** (`pie_chart_2d`, `pie_chart_3d`): Categorical breakdown with slice spokes and optional donut hole.
- **Bar Charts & Histograms 2D** (`bar_chart_2d`): Vertical or horizontal bars with coordinate axis frames and auto-scaling.
- **Radial Gauges 2D & 3D** (`gauge_2d`, `gauge_3d`): Speedometer-style dials with tick marks and needle pointers.
- **Multi-Series Telemetry Graphs** (`stat_graph_2d`, `telemetry_series_2d`, `telemetry_threshold_2d`): Real-time scrolling performance and variable sparklines with threshold limit guidelines.

### 4. 2D Canvas Helpers
- **2D Capsule** (`capsule_2d`): Stadium capsule with semicircular end caps.
- **2D Vision Cone** (`vision_cone_2d`): Field-of-view sensory wedge.
- **2D Arc & Sector** (`arc_2d`, `sector_2d`): Circular arcs and pie sectors.
- **2D Ruler** (`ruler_2d`): Calibrated screen-space distance measuring ruler.
- **2D Primitives**: `line_2d`, `arrow_2d`, `rect_2d`, `circle_2d`, `points_2d`, `path_2d`, `text_2d`.

---

## 🎮 Developer UX & Workflow Features

### Category / Channel Filtering
Organize debug output into logical layers and selectively toggle them:
```crystal
# Draw within an AI channel
DebugDraw.channel("ai") do |d|
  d.vision_cone_3d(enemy.position, enemy.forward, angle_deg: 45.0, range: 10.0)
  d.actor_card_3d(enemy.position, "Enemy Scout", {"HP" => "100%", "State" => "Alert"})
end

# Toggle channels via console command or hotkey
DebugDraw.disable_channel("ai") # Suppresses all AI drawing
DebugDraw.enable_channel("ai")  # Restores AI drawing
```

### Local-Space Transform Stacks
Draw directly relative to moving nodes or local coordinate systems without manual math:
```crystal
DebugDraw.with_transform(vehicle.global_transform) do
  # These points and boxes automatically rotate and translate with the vehicle
  DebugDraw.box_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 1, 4))
  DebugDraw.arrow_3d(Godot::Vector3.new(0, 1, 0), Godot::Vector3.new(0, 1, 3))
end
```

### Frame Freeze Mode
Pause lifetime decay with `DebugDraw.freeze!` to orbit the camera freely and inspect collision glitches:
```crystal
# Freeze active debug shapes so they don't disappear while inspecting
DebugDraw.freeze!

# Orbit camera freely...

# Resume normal decay
DebugDraw.unfreeze!
```

---

## 🚀 Usage Example

```crystal
require "lapis"
require "diorite"

# 1. Immediate-mode drawing in _process
def _process(delta : Float64) : Void
  # Swept sphere cast
  DebugDraw.sphere_cast_3d(start_pos, target_pos, radius: 0.5_f32, hit: is_hit)

  # Data visualization: 2D Bar Chart
  bars = [
    Diorite::BarData.new("RigidBodies", 42.0_f32, Color.new(0.2, 0.8, 0.3)),
    Diorite::BarData.new("Particles", 120.0_f32, Color.new(0.8, 0.3, 0.2))
  ]
  DebugDraw.bar_chart_2d(Rect2.new(20, 200, 160, 80), bars: bars, title: "Engine Stats")

  # Multi-series telemetry graph
  DebugDraw.telemetry_series_2d("Engine", "Frame", frame_ms, Color.new(0.2, 0.9, 0.3))
  DebugDraw.telemetry_series_2d("Engine", "Physics", physics_ms, Color.new(0.2, 0.5, 1.0))
  DebugDraw.telemetry_threshold_2d("Engine", 16.66_f32, Color.new(1.0, 0.2, 0.2, 0.8), "60 FPS")
end
```

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
│   └── main.tscn            # Showcase test scene demonstrating Diorite items
├── spec/                    # Pure Crystal unit test suite (53 specs across 7 suites)
│   ├── charts_spec.cr
│   ├── spatial_helpers_spec.cr
│   ├── channels_and_transforms_spec.cr
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
│   │   ├── core/            # Geometry builder, chart builder, math, command queues, DSL
│   │   ├── nodes/           # Node-based 3D and 2D debug shapes & manager
│   │   └── diorite.cr       # Addon entry point
│   └── main.cr              # Project root game entry point
├── project.godot            # Godot 4.8 engine project configuration
├── shard.yml                # Crystal dependency manifest
└── godot-version.yml        # Target Godot version specification (4.8-dev6)
```

---

## 🧪 Testing & Benchmarking

### Running Unit Specs (53 specs)
Diorite contains comprehensive unit specs covering all 35+ geometric builders, charts, channels, transform stacks, vertex counts, color assignments, telemetry ring buffers, and command queue duration decay:

```bash
crystal spec
```

### Running Benchmark Suite
```bash
crystal run --release bench/benchmark_suite.cr
```

---

## 📄 License

Licensed under the MIT License. See [LICENSE](LICENSE) for details.
