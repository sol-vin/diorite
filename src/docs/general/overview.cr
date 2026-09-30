# ==============================================================================
# Auto-generated from docs_src by Lapis::Docs::Generator
# ==============================================================================

{% unless flag?(:release) %}
module Lapis
  module Docs
    module GENERAL
      # # Diorite Overview & Getting Started
      #
      # Diorite is a high-performance 2D and 3D debug drawing plugin and frame DSL for Godot Engine 4.8+ powered by the Lapis Crystal toolchain.
      #
      # ## Overview
      #
      # Diorite provides two primary workflows for debug drawing in Godot:
      #
      # 1. **Node-based System**: Scene tree nodes (`DebugBox3D`, `DebugSphere3D`, `DebugShape2D`, etc.) designed for in-editor placement, gizmo manipulation, and persistent hierarchy visualization.
      # 2. **Immediate-Mode Frame DSL**: A procedural API (`DebugDraw.*`) that can be invoked anywhere in game logic (`_process`, `_physics_process`, collision signals, or AI behaviors) with single-frame or timed duration.
      #
      # ### Key Topics
      #
      # <table>
      #   <thead>
      #     <tr>
      #       <th>Topic</th>
      #       <th>Description</th>
      #     </tr>
      #   </thead>
      #   <tbody>
      #     <tr>
      #       <td><a href="#topic_01_visual_priority%3ANil-class-method"><strong>Visual Priority</strong></a></td>
      #       <td>All debug items render on top of other game effects (3D render priority 127 with depth test disabled; 2D canvas layer 128 at z-index 4096).</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_02_dual_workflow%3ANil-class-method"><strong>Dual Workflow</strong></a></td>
      #       <td>Choose between scene tree nodes or immediate-mode procedural calls in _process or physics steps.</td>
      #     </tr>
      #   </tbody>
      # </table>
      #
      # ## Code Examples
      #
      # ### Basic 3D Line and Sphere
      #
      # ```crystal
      # DebugDraw.line_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 5, 0), Godot::Color.new(0, 1, 0))
      # DebugDraw.sphere_3d(center: player.position, radius: 1.5_f32, color: Godot::Color.new(1, 0, 0), duration: 2.5_f32)
      # ```
      #
      # ### Block Frame DSL
      #
      # ```crystal
      # DebugDraw.frame do |d|
      #   d.line_3d(actor.position, actor.position + actor.velocity)
      #   d.circle_2d(Godot::Vector2.new(100, 100), 30.0_f32)
      # end
      # ```
      #
      # ## Pitfalls & Best Practices
      #
      # - Do not use raw `.new` on native Godot engine objects without pointers; use `Godot.create(T)` or Diorite helper nodes.
      # - For commands called frequently inside tight loops, prefer batched DSL paths (`line_path_3d`, `points_3d`) to minimize per-command dispatch overhead.
      #
      # ## Frequently Asked Questions
      #
      # - **Q: How do I make debug shapes persist for more than one frame?**<br/>
      #   *A:* Pass duration in seconds (e.g. `duration: 3.0`) to any `DebugDraw` method.
      # - **Q: Can I configure shapes in the Godot Inspector?**<br/>
      #   *A:* Yes, add any of the Diorite node types (e.g. `DebugBox3D`, `DebugShape2D`) to your scene tree.
      module OVERVIEW
        # **Visual Priority**: All debug items render on top of other game effects (3D render priority 127 with depth test disabled; 2D canvas layer 128 at z-index 4096).
        def self.topic_01_visual_priority : Nil; end

        # **Dual Workflow**: Choose between scene tree nodes or immediate-mode procedural calls in _process or physics steps.
        def self.topic_02_dual_workflow : Nil; end

        # **Example: Basic 3D Line and Sphere**
        #
        # ```crystal
        # DebugDraw.line_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 5, 0), Godot::Color.new(0, 1, 0))
        # DebugDraw.sphere_3d(center: player.position, radius: 1.5_f32, color: Godot::Color.new(1, 0, 0), duration: 2.5_f32)
        # ```
        def self.example_01_basic_3d_line_and_sphere : Nil; end

        # **Example: Block Frame DSL**
        #
        # ```crystal
        # DebugDraw.frame do |d|
        #   d.line_3d(actor.position, actor.position + actor.velocity)
        #   d.circle_2d(Godot::Vector2.new(100, 100), 30.0_f32)
        # end
        # ```
        def self.example_02_block_frame_dsl : Nil; end
      end
    end
  end
end
{% end %}
