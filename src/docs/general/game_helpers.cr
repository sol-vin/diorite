# ==============================================================================
# Auto-generated from docs_src by Lapis::Docs::Generator
# ==============================================================================

{% unless flag?(:release) %}
module Lapis
  module Docs
    module GENERAL
      # # Game Spatial Helpers and UX Controls
      #
      # Comprehensive guide to swept shape casts, splines, actor cards, channels, transform stacks, and freeze mode.
      #
      # ## Overview
      #
      # Diorite includes rich gameplay debugging utilities and developer UX features.
      # Debug collision queries with swept shape casts, inspect pathfinding curves with cubic Bézier and Catmull-Rom splines,
      # display overhead entity stat cards, isolate system debug output with channels, and freeze frame decay for freecam inspection.
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
      #       <td><a href="#topic_01_swept_shape_casts%3ANil-class-method"><strong>Swept Shape Casts</strong></a></td>
      #       <td>Visualize continuous physics sweep queries showing start position, destination shape, edge connector rays, and impact indicators.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_02_splines%3ANil-class-method"><strong>Splines (Cubic Bézier &amp; Catmull-Rom)</strong></a></td>
      #       <td>Render smooth 3D trajectories, patrol routes, and motion camera curves with optional control polygon hulls.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_03_actor_cards%3ANil-class-method"><strong>Actor Cards &amp; 3D Spatial Helpers</strong></a></td>
      #       <td>Floating billboard cards with ground anchor poles displaying entity names and dynamic key-value stat blocks.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_04_channel_filtering%3ANil-class-method"><strong>Category / Channel Filtering</strong></a></td>
      #       <td>Assign draw calls to channels (e.g. 'ai', 'combat', 'physics') and toggle them at runtime via script or hotkey.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_05_transform_stacks%3ANil-class-method"><strong>Local-Space Transform Stacks</strong></a></td>
      #       <td>Render primitives relative to parent transforms with DebugDraw.with_transform(xform) do ... end.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_06_frame_freeze%3ANil-class-method"><strong>Frame Freeze Mode</strong></a></td>
      #       <td>Pause lifetime decay with DebugDraw.freeze! to freely maneuver the scene camera around momentary collision or visual glitches.</td>
      #     </tr>
      #   </tbody>
      # </table>
      #
      # ## Code Examples
      #
      # ### Swept Shape Casts
      #
      # ```crystal
      # # Visualize a sphere cast with hit notification
      # DebugDraw.sphere_cast_3d(cast_start, cast_end, radius: 0.5_f32, hit: is_colliding)
      #
      # # Visualize player character capsule sweep
      # DebugDraw.capsule_cast_3d(from_pos, to_pos, radius: 0.4_f32, height: 1.8_f32)
      #
      # # Visualize moving platform box sweep
      # DebugDraw.box_cast_3d(box_start, box_end, size: Godot::Vector3.new(2, 0.5, 2))
      # ```
      #
      # ### Spline Path Visualization
      #
      # ```crystal
      # # 3D Cubic Bézier with control hull
      # DebugDraw.bezier_cubic_3d(p0, p1, p2, p3, segments: 32, show_hull: true)
      #
      # # Multi-waypoint Catmull-Rom patrol curve
      # DebugDraw.catmull_rom_3d(patrol_points, segments_per_curve: 16, loop: true)
      # ```
      #
      # ### Channels and Transform Stacks
      #
      # ```crystal
      # # Scoped drawing with local transform
      # DebugDraw.with_transform(vehicle.global_transform) do
      #   DebugDraw.box_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 1, 4))
      #   DebugDraw.arrow_3d(Godot::Vector3.new(0, 1, 0), Godot::Vector3.new(0, 1, 3))
      # end
      #
      # # Filtered channel drawing
      # DebugDraw.channel("ai") do |d|
      #   d.vision_cone_3d(enemy.position, enemy.forward, angle_deg: 45.0_f32, range: 10.0_f32)
      #   d.actor_card_3d(enemy.position, "Guard AI", {"State" => "Patrol", "HP" => "100%"})
      # end
      # ```
      #
      # ## Pitfalls & Best Practices
      #
      # - Transform stacks automatically pop when exiting `with_transform` blocks, ensuring consistent global coordinate states.
      # - When the queue is frozen via `freeze!`, commands persist without decaying their remaining duration.
      #
      # ## Frequently Asked Questions
      #
      # - **Q: How do I toggle channels during gameplay?**<br/>
      #   *A:* Call `DebugDraw.enable_channel("ai")` or `DebugDraw.disable_channel("ai")` from an input action or debug console command.
      # - **Q: How do I freeze debug draws with a hotkey?**<br/>
      #   *A:* Call `DebugDraw.toggle_freeze!` in your input event handler when the desired pause/inspect key is pressed.
      module GAME_HELPERS
        # **Swept Shape Casts**: Visualize continuous physics sweep queries showing start position, destination shape, edge connector rays, and impact indicators.
        def self.topic_01_swept_shape_casts : Nil; end

        # **Splines (Cubic Bézier & Catmull-Rom)**: Render smooth 3D trajectories, patrol routes, and motion camera curves with optional control polygon hulls.
        def self.topic_02_splines : Nil; end

        # **Actor Cards & 3D Spatial Helpers**: Floating billboard cards with ground anchor poles displaying entity names and dynamic key-value stat blocks.
        def self.topic_03_actor_cards : Nil; end

        # **Category / Channel Filtering**: Assign draw calls to channels (e.g. 'ai', 'combat', 'physics') and toggle them at runtime via script or hotkey.
        def self.topic_04_channel_filtering : Nil; end

        # **Local-Space Transform Stacks**: Render primitives relative to parent transforms with DebugDraw.with_transform(xform) do ... end.
        def self.topic_05_transform_stacks : Nil; end

        # **Frame Freeze Mode**: Pause lifetime decay with DebugDraw.freeze! to freely maneuver the scene camera around momentary collision or visual glitches.
        def self.topic_06_frame_freeze : Nil; end

        # **Example: Swept Shape Casts**
        #
        # ```crystal
        # DebugDraw.sphere_cast_3d(cast_start, cast_end, radius: 0.5_f32, hit: is_colliding)
        # DebugDraw.capsule_cast_3d(from_pos, to_pos, radius: 0.4_f32, height: 1.8_f32)
        # DebugDraw.box_cast_3d(box_start, box_end, size: Godot::Vector3.new(2, 0.5, 2))
        # ```
        def self.example_01_swept_shape_casts : Nil; end

        # **Example: Spline Path Visualization**
        #
        # ```crystal
        # DebugDraw.bezier_cubic_3d(p0, p1, p2, p3, segments: 32, show_hull: true)
        # DebugDraw.catmull_rom_3d(patrol_points, segments_per_curve: 16, loop: true)
        # ```
        def self.example_02_spline_paths : Nil; end

        # **Example: Channels and Transform Stacks**
        #
        # ```crystal
        # DebugDraw.with_transform(vehicle.global_transform) do
        #   DebugDraw.box_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 1, 4))
        #   DebugDraw.arrow_3d(Godot::Vector3.new(0, 1, 0), Godot::Vector3.new(0, 1, 3))
        # end
        #
        # DebugDraw.channel("ai") do |d|
        #   d.vision_cone_3d(enemy.position, enemy.forward, angle_deg: 45.0_f32, range: 10.0_f32)
        #   d.actor_card_3d(enemy.position, "Guard AI", {"State" => "Patrol", "HP" => "100%"})
        # end
        # ```
        def self.example_03_channels_and_transforms : Nil; end
      end
    end
  end
end
{% end %}
