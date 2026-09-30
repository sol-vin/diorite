# ==============================================================================
# Auto-generated from docs_src by Lapis::Docs::Generator
# ==============================================================================

{% unless flag?(:release) %}
module Lapis
  module Docs
    module GENERAL
      # # Data Visualization and Charting
      #
      # Complete guide to 2D and 3D Pie charts, Bar charts, Radial gauges, and multi-series telemetry graphs.
      #
      # ## Overview
      #
      # Diorite features a built-in algorithmic charting engine for data visualization.
      # Render pie charts, donut charts, bar charts, radial gauges, and multi-series performance telemetry
      # graphs directly in Godot game scenes or canvas overlays without external dependencies.
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
      #       <td><a href="#topic_01_pie_and_donut_charts%3ANil-class-method"><strong>Pie &amp; Donut Charts (2D &amp; 3D)</strong></a></td>
      #       <td>Visualize categorical distributions, resource breakdown, or AI behavior weightings with outer rims, inner donut cutouts, and slice spokes.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_02_bar_charts_and_histograms%3ANil-class-method"><strong>Bar Charts &amp; Histograms (2D)</strong></a></td>
      #       <td>Render vertical columns or horizontal bar charts complete with coordinate axis frames, auto-scaling value heights, and labels.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_03_radial_gauges%3ANil-class-method"><strong>Radial Gauges (2D &amp; 3D)</strong></a></td>
      #       <td>Display dials for speed, temperature, health, or weapon charge featuring calibrated tick marks, needle pointers, and central hubs.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_04_multi_series_telemetry_graphs%3ANil-class-method"><strong>Multi-Series Telemetry Graphs</strong></a></td>
      #       <td>Overlay multiple metric curves onto a single graph box with custom line colors and horizontal threshold limit indicators.</td>
      #     </tr>
      #   </tbody>
      # </table>
      #
      # ## Code Examples
      #
      # ### Drawing 2D & 3D Pie Charts
      #
      # ```crystal
      # slices = [
      #   Diorite::PieSlice.new("Physics", 45.0_f32, Godot::Color.new(1.0, 0.2, 0.2)),
      #   Diorite::PieSlice.new("Render", 35.0_f32, Godot::Color.new(0.2, 0.8, 0.2)),
      #   Diorite::PieSlice.new("Scripts", 20.0_f32, Godot::Color.new(0.2, 0.5, 1.0)),
      # ]
      #
      # # 2D Donut Chart on Canvas
      # DebugDraw.pie_chart_2d(Godot::Vector2.new(120, 120), radius: 50.0_f32, slices: slices, inner_radius: 25.0_f32)
      #
      # # 3D Pie Chart oriented on ground plane
      # DebugDraw.pie_chart_3d(entity.position, normal: Godot::Vector3.new(0, 1, 0), radius: 2.0_f32, slices: slices)
      # ```
      #
      # ### Drawing Bar Charts & Gauges
      #
      # ```crystal
      # bars = [
      #   Diorite::BarData.new("Enemies", 12.0_f32, Godot::Color.new(1.0, 0.3, 0.3)),
      #   Diorite::BarData.new("Allies", 4.0_f32, Godot::Color.new(0.3, 0.9, 0.3)),
      #   Diorite::BarData.new("Items", 28.0_f32, Godot::Color.new(1.0, 0.8, 0.2)),
      # ]
      # DebugDraw.bar_chart_2d(Godot::Rect2.new(20, 200, 180, 80), bars: bars, title: "Entity Breakdown")
      #
      # # Radial speedometer gauge
      # DebugDraw.gauge_2d(Godot::Vector2.new(300, 120), radius: 40.0_f32, value: player.speed, min_val: 0.0, max_val: 120.0, title: "Speed")
      # ```
      #
      # ### Multi-Series Telemetry with Thresholds
      #
      # ```crystal
      # # Log multiple series to the same telemetry graph
      # DebugDraw.telemetry_series_2d("Engine", "Frame", frame_ms, color: Godot::Color.new(0.2, 0.9, 0.3))
      # DebugDraw.telemetry_series_2d("Engine", "Physics", physics_ms, color: Godot::Color.new(0.2, 0.5, 1.0))
      #
      # # Draw a 16.6ms (60 FPS) threshold guideline
      # DebugDraw.telemetry_threshold_2d("Engine", 16.66_f32, Godot::Color.new(1.0, 0.2, 0.2, 0.8), "60 FPS")
      # ```
      #
      # ## Pitfalls & Best Practices
      #
      # - ChartBuilder routines are pure algorithmic geometry synthesizers designed for zero-allocation rendering.
      # - When specifying PieSlice values, Diorite automatically calculates proportional percentage sweeps across 360 degrees.
      #
      # ## Frequently Asked Questions
      #
      # - **Q: Can I place 3D pie charts or gauges relative to moving entities?**<br/>
      #   *A:* Yes, use `DebugDraw.with_transform(entity.global_transform)` to render them in the entity's local coordinate space.
      # - **Q: How do I customize gauge sweep angles?**<br/>
      #   *A:* Call `ChartBuilder.build_gauge_2d` or `build_gauge_3d` directly with custom `start_angle` and `end_angle` parameters in radians.
      module CHARTING
        # **Pie & Donut Charts (2D & 3D)**: Visualize categorical distributions, resource breakdown, or AI behavior weightings with outer rims, inner donut cutouts, and slice spokes.
        def self.topic_01_pie_and_donut_charts : Nil; end

        # **Bar Charts & Histograms (2D)**: Render vertical columns or horizontal bar charts complete with coordinate axis frames, auto-scaling value heights, and labels.
        def self.topic_02_bar_charts_and_histograms : Nil; end

        # **Radial Gauges (2D & 3D)**: Display dials for speed, temperature, health, or weapon charge featuring calibrated tick marks, needle pointers, and central hubs.
        def self.topic_03_radial_gauges : Nil; end

        # **Multi-Series Telemetry Graphs**: Overlay multiple metric curves onto a single graph box with custom line colors and horizontal threshold limit indicators.
        def self.topic_04_multi_series_telemetry_graphs : Nil; end

        # **Example: Drawing 2D & 3D Pie Charts**
        #
        # ```crystal
        # slices = [
        #   Diorite::PieSlice.new("Physics", 45.0_f32, Godot::Color.new(1.0, 0.2, 0.2)),
        #   Diorite::PieSlice.new("Render", 35.0_f32, Godot::Color.new(0.2, 0.8, 0.2)),
        #   Diorite::PieSlice.new("Scripts", 20.0_f32, Godot::Color.new(0.2, 0.5, 1.0)),
        # ]
        # DebugDraw.pie_chart_2d(Godot::Vector2.new(120, 120), radius: 50.0_f32, slices: slices, inner_radius: 25.0_f32)
        # DebugDraw.pie_chart_3d(entity.position, normal: Godot::Vector3.new(0, 1, 0), radius: 2.0_f32, slices: slices)
        # ```
        def self.example_01_pie_charts : Nil; end

        # **Example: Drawing Bar Charts & Gauges**
        #
        # ```crystal
        # bars = [
        #   Diorite::BarData.new("Enemies", 12.0_f32, Godot::Color.new(1.0, 0.3, 0.3)),
        #   Diorite::BarData.new("Allies", 4.0_f32, Godot::Color.new(0.3, 0.9, 0.3)),
        #   Diorite::BarData.new("Items", 28.0_f32, Godot::Color.new(1.0, 0.8, 0.2)),
        # ]
        # DebugDraw.bar_chart_2d(Godot::Rect2.new(20, 200, 180, 80), bars: bars, title: "Entity Breakdown")
        # DebugDraw.gauge_2d(Godot::Vector2.new(300, 120), radius: 40.0_f32, value: player.speed, min_val: 0.0, max_val: 120.0, title: "Speed")
        # ```
        def self.example_02_bar_charts_and_gauges : Nil; end

        # **Example: Multi-Series Telemetry with Thresholds**
        #
        # ```crystal
        # DebugDraw.telemetry_series_2d("Engine", "Frame", frame_ms, color: Godot::Color.new(0.2, 0.9, 0.3))
        # DebugDraw.telemetry_series_2d("Engine", "Physics", physics_ms, color: Godot::Color.new(0.2, 0.5, 1.0))
        # DebugDraw.telemetry_threshold_2d("Engine", 16.66_f32, Godot::Color.new(1.0, 0.2, 0.2, 0.8), "60 FPS")
        # ```
        def self.example_03_telemetry_thresholds : Nil; end
      end
    end
  end
end
{% end %}
