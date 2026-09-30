# ==============================================================================
# Auto-generated from docs_src by Lapis::Docs::Generator
# ==============================================================================

{% unless flag?(:release) %}
module Lapis
  module Docs
    module GENERAL
      # # Diorite Primitives Reference
      #
      # Complete guide to all 26 procedural 2D and 3D debug drawing primitives supported by Diorite.
      #
      # ## Overview
      #
      # Diorite provides 26 high-performance debug primitives spanning standard geometric shapes,
      # camera helpers, physics telemetry indicators, motion trails, and canvas UI overlays.
      # Each primitive is available via procedural `DebugDraw` methods with customizable colors, line widths, and durations.
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
      #       <td><a href="#topic_01_3d_primitives%3ANil-class-method"><strong>3D Primitives</strong></a></td>
      #       <td>Line, Arrow, Box, Sphere, Cylinder, Capsule, Vision Cone, Plane, Grid, Gizmo, Position 3D, Frustum, Points, Path, Spring, Ruler, Reticle, Surface Disk, Ray Hit, Trajectory Arc, Text 3D, and Motion Trails.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_02_2d_primitives%3ANil-class-method"><strong>2D Primitives</strong></a></td>
      #       <td>Line 2D, Arrow 2D, Rect 2D, Circle 2D, Points 2D, Path 2D, Text 2D, and Real-time Telemetry Graphs.</td>
      #     </tr>
      #   </tbody>
      # </table>
      #
      # ## Code Examples
      #
      # ### Drawing 3D Primitives
      #
      # ```crystal
      # DebugDraw.line_3d(v0, v1, Godot::Color.new(1, 0, 0))
      # DebugDraw.arrow_3d(from, to, Godot::Color.new(0, 1, 0), head_size: 0.3_f32)
      # DebugDraw.sphere_3d(center, radius: 1.5_f32, rings: 16)
      # DebugDraw.camera_frustum_3d(pos, basis, fov: 60.0_f32, near: 0.1_f32, far: 50.0_f32, aspect: 1.777_f32)
      # DebugDraw.trajectory_arc_3d(origin, velocity, gravity, max_time: 2.0_f32, steps: 25)
      # DebugDraw.ruler_3d(ptA, ptB, tick_size: 0.2_f32)
      # ```
      #
      # ### Drawing 2D Primitives and Telemetry
      #
      # ```crystal
      # DebugDraw.line_2d(Godot::Vector2.new(0, 0), Godot::Vector2.new(100, 100))
      # DebugDraw.circle_2d(Godot::Vector2.new(200, 200), radius: 30.0_f32)
      # DebugDraw.rect_2d(Godot::Rect2.new(10, 10, 100, 50))
      # DebugDraw.stat_graph_2d("Player Speed", player.velocity.length)
      # ```
      #
      # ## Pitfalls & Best Practices
      #
      # - When rendering many continuous line segments, prefer `line_path_3d` over multiple `line_3d` calls for better cache locality.
      # - Ruler 3D automatically creates an associated 3D midpoint distance text readout; you do not need to call `text_3d` separately.
      #
      # ## Frequently Asked Questions
      #
      # - **Q: What is the coordinate orientation for camera frustums?**<br/>
      #   *A:* Frustums look along the negative Z axis of the camera Basis, matching Godot camera conventions.
      # - **Q: Can I draw multiple telemetry graphs at the same time?**<br/>
      #   *A:* Yes, each graph is keyed by its unique title and renders into its specified screen Rect2 bounding box.
      module PRIMITIVES
        # **3D Primitives**: Line, Arrow, Box, Sphere, Cylinder, Capsule, Vision Cone, Plane, Grid, Gizmo, Position 3D, Frustum, Points, Path, Spring, Ruler, Reticle, Surface Disk, Ray Hit, Trajectory Arc, Text 3D, and Motion Trails.
        def self.topic_01_3d_primitives : Nil; end

        # **2D Primitives**: Line 2D, Arrow 2D, Rect 2D, Circle 2D, Points 2D, Path 2D, Text 2D, and Real-time Telemetry Graphs.
        def self.topic_02_2d_primitives : Nil; end

        # **Example: Drawing 3D Primitives**
        #
        # ```crystal
        # DebugDraw.line_3d(v0, v1, Godot::Color.new(1, 0, 0))
        # DebugDraw.arrow_3d(from, to, Godot::Color.new(0, 1, 0), head_size: 0.3_f32)
        # DebugDraw.sphere_3d(center, radius: 1.5_f32, rings: 16)
        # DebugDraw.camera_frustum_3d(pos, basis, fov: 60.0_f32, near: 0.1_f32, far: 50.0_f32, aspect: 1.777_f32)
        # DebugDraw.trajectory_arc_3d(origin, velocity, gravity, max_time: 2.0_f32, steps: 25)
        # DebugDraw.ruler_3d(ptA, ptB, tick_size: 0.2_f32)
        # ```
        def self.example_01_drawing_3d_primitives : Nil; end

        # **Example: Drawing 2D Primitives and Telemetry**
        #
        # ```crystal
        # DebugDraw.line_2d(Godot::Vector2.new(0, 0), Godot::Vector2.new(100, 100))
        # DebugDraw.circle_2d(Godot::Vector2.new(200, 200), radius: 30.0_f32)
        # DebugDraw.rect_2d(Godot::Rect2.new(10, 10, 100, 50))
        # DebugDraw.stat_graph_2d("Player Speed", player.velocity.length)
        # ```
        def self.example_02_drawing_2d_primitives_and_telemetry : Nil; end
      end
    end
  end
end
{% end %}
