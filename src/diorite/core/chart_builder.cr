require "./math_helpers"
require "./debug_command"

module Diorite
  # Algorithmic geometry synthesizer for data visualization (Pie/Donut charts, Bar charts, Gauges).
  #
  # Emits line-list vertices and colors directly to immediate-mesh vertex arrays with zero GC pressure.
  module ChartBuilder
    include MathHelpers

    # Builds a 2D Pie or Donut chart on the canvas overlay.
    def self.build_pie_chart_2d(
      center : Godot::Vector2,
      radius : Float32,
      inner_radius : Float32,
      slices : Array(PieSlice),
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color),
      segments_per_full_turn : Int32 = 64
    ) : Void
      total = slices.sum(&.value)
      return if total <= 0.0_f32 || radius <= 0.0_f32

      current_angle = 0.0_f32
      slices.each do |slice|
        fraction = (slice.value / total).clamp(0.0_f32, 1.0_f32)
        next if fraction <= 0.0_f32

        sweep = fraction * MathHelpers::TAU
        slice_end = current_angle + sweep
        color = slice.color

        seg_count = (segments_per_full_turn.to_f32 * fraction).ceil.to_i32.clamp(3, 64)
        angle_step = sweep / seg_count.to_f32

        # Outer arc
        (0...seg_count).each do |i|
          a0 = current_angle + i.to_f32 * angle_step
          a1 = current_angle + (i + 1).to_f32 * angle_step
          p0 = center + Godot::Vector2.new(Math.cos(a0).to_f32 * radius, Math.sin(a0).to_f32 * radius)
          p1 = center + Godot::Vector2.new(Math.cos(a1).to_f32 * radius, Math.sin(a1).to_f32 * radius)
          verts << p0; verts << p1
          cols << color; cols << color
        end

        # Inner arc (if donut)
        if inner_radius > 0.0_f32
          (0...seg_count).each do |i|
            a0 = current_angle + i.to_f32 * angle_step
            a1 = current_angle + (i + 1).to_f32 * angle_step
            p0 = center + Godot::Vector2.new(Math.cos(a0).to_f32 * inner_radius, Math.sin(a0).to_f32 * inner_radius)
            p1 = center + Godot::Vector2.new(Math.cos(a1).to_f32 * inner_radius, Math.sin(a1).to_f32 * inner_radius)
            verts << p0; verts << p1
            cols << color; cols << color
          end
        end

        # Radial dividing spokes at slice start and slice end
        p_start_inner = center + (inner_radius > 0.0_f32 ? Godot::Vector2.new(Math.cos(current_angle).to_f32 * inner_radius, Math.sin(current_angle).to_f32 * inner_radius) : Godot::Vector2.new(0.0_f32, 0.0_f32))
        p_start_outer = center + Godot::Vector2.new(Math.cos(current_angle).to_f32 * radius, Math.sin(current_angle).to_f32 * radius)
        verts << p_start_inner; verts << p_start_outer
        cols << color; cols << color

        p_end_inner = center + (inner_radius > 0.0_f32 ? Godot::Vector2.new(Math.cos(slice_end).to_f32 * inner_radius, Math.sin(slice_end).to_f32 * inner_radius) : Godot::Vector2.new(0.0_f32, 0.0_f32))
        p_end_outer = center + Godot::Vector2.new(Math.cos(slice_end).to_f32 * radius, Math.sin(slice_end).to_f32 * radius)
        verts << p_end_inner; verts << p_end_outer
        cols << color; cols << color

        current_angle = slice_end
      end
    end

    # Builds a 3D Pie or Donut chart oriented by normal.
    def self.build_pie_chart_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32,
      inner_radius : Float32,
      slices : Array(PieSlice),
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color),
      segments_per_full_turn : Int32 = 64
    ) : Void
      total = slices.sum(&.value)
      return if total <= 0.0_f32 || radius <= 0.0_f32

      u, v = MathHelpers.orthonormal_plane(normal)

      current_angle = 0.0_f32
      slices.each do |slice|
        fraction = (slice.value / total).clamp(0.0_f32, 1.0_f32)
        next if fraction <= 0.0_f32

        sweep = fraction * MathHelpers::TAU
        slice_end = current_angle + sweep
        color = slice.color

        seg_count = (segments_per_full_turn.to_f32 * fraction).ceil.to_i32.clamp(3, 64)
        angle_step = sweep / seg_count.to_f32

        (0...seg_count).each do |i|
          a0 = current_angle + i.to_f32 * angle_step
          a1 = current_angle + (i + 1).to_f32 * angle_step
          p0 = center + (u * Math.cos(a0).to_f32 + v * Math.sin(a0).to_f32) * radius
          p1 = center + (u * Math.cos(a1).to_f32 + v * Math.sin(a1).to_f32) * radius
          verts << p0; verts << p1
          cols << color; cols << color
        end

        if inner_radius > 0.0_f32
          (0...seg_count).each do |i|
            a0 = current_angle + i.to_f32 * angle_step
            a1 = current_angle + (i + 1).to_f32 * angle_step
            p0 = center + (u * Math.cos(a0).to_f32 + v * Math.sin(a0).to_f32) * inner_radius
            p1 = center + (u * Math.cos(a1).to_f32 + v * Math.sin(a1).to_f32) * inner_radius
            verts << p0; verts << p1
            cols << color; cols << color
          end
        end

        p_start_inner = center + (inner_radius > 0.0_f32 ? (u * Math.cos(current_angle).to_f32 + v * Math.sin(current_angle).to_f32) * inner_radius : Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32))
        p_start_outer = center + (u * Math.cos(current_angle).to_f32 + v * Math.sin(current_angle).to_f32) * radius
        verts << p_start_inner; verts << p_start_outer
        cols << color; cols << color

        p_end_inner = center + (inner_radius > 0.0_f32 ? (u * Math.cos(slice_end).to_f32 + v * Math.sin(slice_end).to_f32) * inner_radius : Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32))
        p_end_outer = center + (u * Math.cos(slice_end).to_f32 + v * Math.sin(slice_end).to_f32) * radius
        verts << p_end_inner; verts << p_end_outer
        cols << color; cols << color

        current_angle = slice_end
      end
    end

    # Builds a 2D Bar chart with axis frame and bar outlines.
    def self.build_bar_chart_2d(
      rect : Godot::Rect2,
      bars : Array(BarData),
      horizontal : Bool,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      return if bars.empty?

      x0 = rect.position.x
      y0 = rect.position.y
      w = rect.size.x
      h = rect.size.y
      x1 = x0 + w
      y1 = y0 + h

      axis_color = Godot::Color.new(0.5_f32, 0.5_f32, 0.5_f32, 0.8_f32)

      # Axis lines (Left vertical and Bottom horizontal)
      verts << Godot::Vector2.new(x0, y0); verts << Godot::Vector2.new(x0, y1)
      cols << axis_color; cols << axis_color
      verts << Godot::Vector2.new(x0, y1); verts << Godot::Vector2.new(x1, y1)
      cols << axis_color; cols << axis_color

      max_val = bars.max_of(&.value)
      max_val = 1.0_f32 if max_val <= 0.0_f32

      n = bars.size

      if !horizontal
        # Vertical bars
        slot_w = w / n.to_f32
        bar_w = slot_w * 0.7_f32
        margin = slot_w * 0.15_f32

        bars.each_with_index do |bar, idx|
          bar_h = (bar.value / max_val).clamp(0.0_f32, 1.0_f32) * (h - 10.0_f32)
          bx0 = x0 + idx.to_f32 * slot_w + margin
          bx1 = bx0 + bar_w
          by1 = y1
          by0 = y1 - bar_h

          # Bar rect (4 sides)
          verts << Godot::Vector2.new(bx0, by0); verts << Godot::Vector2.new(bx1, by0)
          cols << bar.color; cols << bar.color
          verts << Godot::Vector2.new(bx1, by0); verts << Godot::Vector2.new(bx1, by1)
          cols << bar.color; cols << bar.color
          verts << Godot::Vector2.new(bx1, by1); verts << Godot::Vector2.new(bx0, by1)
          cols << bar.color; cols << bar.color
          verts << Godot::Vector2.new(bx0, by1); verts << Godot::Vector2.new(bx0, by0)
          cols << bar.color; cols << bar.color
        end
      else
        # Horizontal bars
        slot_h = h / n.to_f32
        bar_h = slot_h * 0.7_f32
        margin = slot_h * 0.15_f32

        bars.each_with_index do |bar, idx|
          bar_w = (bar.value / max_val).clamp(0.0_f32, 1.0_f32) * (w - 10.0_f32)
          by0 = y0 + idx.to_f32 * slot_h + margin
          by1 = by0 + bar_h
          bx0 = x0
          bx1 = x0 + bar_w

          # Bar rect (4 sides)
          verts << Godot::Vector2.new(bx0, by0); verts << Godot::Vector2.new(bx1, by0)
          cols << bar.color; cols << bar.color
          verts << Godot::Vector2.new(bx1, by0); verts << Godot::Vector2.new(bx1, by1)
          cols << bar.color; cols << bar.color
          verts << Godot::Vector2.new(bx1, by1); verts << Godot::Vector2.new(bx0, by1)
          cols << bar.color; cols << bar.color
          verts << Godot::Vector2.new(bx0, by1); verts << Godot::Vector2.new(bx0, by0)
          cols << bar.color; cols << bar.color
        end
      end
    end

    # Builds a 2D radial gauge with scale ticks and needle indicator.
    def self.build_gauge_2d(
      center : Godot::Vector2,
      radius : Float32,
      value : Float32,
      min_val : Float32,
      max_val : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color),
      start_angle : Float32 = 2.3561945_f32,
      end_angle : Float32 = 7.0685834_f32,
      ticks : Int32 = 6
    ) : Void
      return if radius <= 0.0_f32

      span = end_angle - start_angle
      segs = 32
      step = span / segs.to_f32

      # Scale arc
      (0...segs).each do |i|
        a0 = start_angle + i.to_f32 * step
        a1 = start_angle + (i + 1).to_f32 * step
        p0 = center + Godot::Vector2.new(Math.cos(a0).to_f32 * radius, Math.sin(a0).to_f32 * radius)
        p1 = center + Godot::Vector2.new(Math.cos(a1).to_f32 * radius, Math.sin(a1).to_f32 * radius)
        verts << p0; verts << p1
        cols << color; cols << color
      end

      # Tick marks
      tick_step = span / (ticks - 1).to_f32
      tick_len = radius * 0.15_f32
      (0...ticks).each do |t|
        ang = start_angle + t.to_f32 * tick_step
        dir = Godot::Vector2.new(Math.cos(ang).to_f32, Math.sin(ang).to_f32)
        p_outer = center + dir * radius
        p_inner = center + dir * (radius - tick_len)
        verts << p_inner; verts << p_outer
        cols << color; cols << color
      end

      # Needle pointer
      range = (max_val - min_val).abs
      range = 0.0001_f32 if range < 0.0001_f32
      fraction = ((value - min_val) / range).clamp(0.0_f32, 1.0_f32)
      needle_angle = start_angle + fraction * span
      needle_dir = Godot::Vector2.new(Math.cos(needle_angle).to_f32, Math.sin(needle_angle).to_f32)
      needle_tip = center + needle_dir * (radius * 0.85_f32)

      needle_color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32)
      verts << center; verts << needle_tip
      cols << needle_color; cols << needle_color

      # Central hub
      hub_r = radius * 0.08_f32
      verts << (center - Godot::Vector2.new(hub_r, 0.0_f32)); verts << (center + Godot::Vector2.new(hub_r, 0.0_f32))
      cols << color; cols << color
      verts << (center - Godot::Vector2.new(0.0_f32, hub_r)); verts << (center + Godot::Vector2.new(0.0_f32, hub_r))
      cols << color; cols << color
    end

    # Builds a 3D radial gauge oriented on a plane by normal.
    def self.build_gauge_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32,
      value : Float32,
      min_val : Float32,
      max_val : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color),
      start_angle : Float32 = 2.3561945_f32,
      end_angle : Float32 = 7.0685834_f32,
      ticks : Int32 = 6
    ) : Void
      return if radius <= 0.0_f32

      u, v = MathHelpers.orthonormal_plane(normal)

      span = end_angle - start_angle
      segs = 32
      step = span / segs.to_f32

      # Scale arc
      (0...segs).each do |i|
        a0 = start_angle + i.to_f32 * step
        a1 = start_angle + (i + 1).to_f32 * step
        p0 = center + (u * Math.cos(a0).to_f32 + v * Math.sin(a0).to_f32) * radius
        p1 = center + (u * Math.cos(a1).to_f32 + v * Math.sin(a1).to_f32) * radius
        verts << p0; verts << p1
        cols << color; cols << color
      end

      # Tick marks
      tick_step = span / (ticks - 1).to_f32
      tick_len = radius * 0.15_f32
      (0...ticks).each do |t|
        ang = start_angle + t.to_f32 * tick_step
        dir = (u * Math.cos(ang).to_f32 + v * Math.sin(ang).to_f32)
        p_outer = center + dir * radius
        p_inner = center + dir * (radius - tick_len)
        verts << p_inner; verts << p_outer
        cols << color; cols << color
      end

      # Needle pointer
      range = (max_val - min_val).abs
      range = 0.0001_f32 if range < 0.0001_f32
      fraction = ((value - min_val) / range).clamp(0.0_f32, 1.0_f32)
      needle_angle = start_angle + fraction * span
      needle_dir = (u * Math.cos(needle_angle).to_f32 + v * Math.sin(needle_angle).to_f32)
      needle_tip = center + needle_dir * (radius * 0.85_f32)

      needle_color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32)
      verts << center; verts << needle_tip
      cols << needle_color; cols << needle_color

      # Central hub
      hub_r = radius * 0.08_f32
      verts << (center - u * hub_r); verts << (center + u * hub_r)
      cols << color; cols << color
      verts << (center - v * hub_r); verts << (center + v * hub_r)
      cols << color; cols << color
    end
  end
end
