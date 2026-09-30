require "./math_helpers"

module Diorite
  module GeometryBuilder
    include MathHelpers

    # --- 1. Line ---
    def self.build_line(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      verts << from
      verts << to
      cols << color
      cols << color
    end

    # --- 2. Arrow & Line with Arrow ---
    def self.build_arrow(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color,
      head_size : Float32,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      # Shaft
      build_line(from, to, color, verts, cols)

      # Direction
      dir = (to - from)
      len = dir.length
      return if len < 0.0001_f32

      norm_dir = dir / len
      u, v = MathHelpers.orthonormal_plane(norm_dir)

      actual_head = head_size.clamp(0.01_f32, len * 0.5_f32)
      base_pt = to - norm_dir * actual_head

      # 4 arrowhead fin lines connecting back from tip to base
      fins = [
        base_pt + u * (actual_head * 0.5_f32),
        base_pt - u * (actual_head * 0.5_f32),
        base_pt + v * (actual_head * 0.5_f32),
        base_pt - v * (actual_head * 0.5_f32),
      ]

      fins.each do |f|
        build_line(to, f, color, verts, cols)
        build_line(base_pt, f, color, verts, cols)
      end
    end

    # --- 3. Line Path ---
    def self.build_line_path(
      points : Array(Godot::Vector3),
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      return if points.size < 2
      (0...points.size - 1).each do |i|
        build_line(points[i], points[i + 1], color, verts, cols)
      end
    end

    # --- 4. Box (AABB) ---
    def self.build_box(
      center : Godot::Vector3,
      size : Godot::Vector3,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      hx = size.x * 0.5_f32
      hy = size.y * 0.5_f32
      hz = size.z * 0.5_f32

      c0 = center + Godot::Vector3.new(-hx, -hy, -hz)
      c1 = center + Godot::Vector3.new(hx, -hy, -hz)
      c2 = center + Godot::Vector3.new(hx, -hy, hz)
      c3 = center + Godot::Vector3.new(-hx, -hy, hz)
      c4 = center + Godot::Vector3.new(-hx, hy, -hz)
      c5 = center + Godot::Vector3.new(hx, hy, -hz)
      c6 = center + Godot::Vector3.new(hx, hy, hz)
      c7 = center + Godot::Vector3.new(-hx, hy, hz)

      # Bottom face
      build_line(c0, c1, color, verts, cols)
      build_line(c1, c2, color, verts, cols)
      build_line(c2, c3, color, verts, cols)
      build_line(c3, c0, color, verts, cols)

      # Top face
      build_line(c4, c5, color, verts, cols)
      build_line(c5, c6, color, verts, cols)
      build_line(c6, c7, color, verts, cols)
      build_line(c7, c4, color, verts, cols)

      # Pillars
      build_line(c0, c4, color, verts, cols)
      build_line(c1, c5, color, verts, cols)
      build_line(c2, c6, color, verts, cols)
      build_line(c3, c7, color, verts, cols)
    end

    # --- 5. Sphere (3 orthogonal major circles + latitude/longitude rings) ---
    def self.build_sphere(
      center : Godot::Vector3,
      radius : Float32,
      rings : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      segs = rings.clamp(8, 64)
      step = MathHelpers::TAU / segs.to_f32

      # XY, XZ, YZ primary circles
      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step

        c0 = Math.cos(a0).to_f32 * radius
        s0 = Math.sin(a0).to_f32 * radius
        c1 = Math.cos(a1).to_f32 * radius
        s1 = Math.sin(a1).to_f32 * radius

        # XY
        build_line(center + Godot::Vector3.new(c0, s0, 0), center + Godot::Vector3.new(c1, s1, 0), color, verts, cols)
        # XZ
        build_line(center + Godot::Vector3.new(c0, 0, s0), center + Godot::Vector3.new(c1, 0, s1), color, verts, cols)
        # YZ
        build_line(center + Godot::Vector3.new(0, c0, s0), center + Godot::Vector3.new(0, c1, s1), color, verts, cols)
      end
    end

    # --- 6. Cylinder ---
    def self.build_cylinder(
      center : Godot::Vector3,
      radius : Float32,
      height : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      segs = segments.clamp(8, 48)
      step = MathHelpers::TAU / segs.to_f32
      hh = height * 0.5_f32

      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step

        c0 = Math.cos(a0).to_f32 * radius
        s0 = Math.sin(a0).to_f32 * radius
        c1 = Math.cos(a1).to_f32 * radius
        s1 = Math.sin(a1).to_f32 * radius

        # Bottom circle
        p_bot0 = center + Godot::Vector3.new(c0, -hh, s0)
        p_bot1 = center + Godot::Vector3.new(c1, -hh, s1)
        build_line(p_bot0, p_bot1, color, verts, cols)

        # Top circle
        p_top0 = center + Godot::Vector3.new(c0, hh, s0)
        p_top1 = center + Godot::Vector3.new(c1, hh, s1)
        build_line(p_top0, p_top1, color, verts, cols)

        # Connecting vertical ribs (every 90 degrees or every 4 segments)
        if i % (segs // 4) == 0
          build_line(p_bot0, p_top0, color, verts, cols)
        end
      end
    end

    # --- 7. Capsule ---
    def self.build_capsule(
      center : Godot::Vector3,
      radius : Float32,
      height : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      segs = segments.clamp(8, 36)
      step = MathHelpers::TAU / segs.to_f32
      cylinder_h = Math.max(0.0_f32, height - radius * 2.0_f32)
      hh = cylinder_h * 0.5_f32

      top_center = center + Godot::Vector3.new(0, hh, 0)
      bot_center = center + Godot::Vector3.new(0, -hh, 0)

      # Middle rings
      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step
        c0 = Math.cos(a0).to_f32 * radius
        s0 = Math.sin(a0).to_f32 * radius
        c1 = Math.cos(a1).to_f32 * radius
        s1 = Math.sin(a1).to_f32 * radius

        build_line(top_center + Godot::Vector3.new(c0, 0, s0), top_center + Godot::Vector3.new(c1, 0, s1), color, verts, cols)
        build_line(bot_center + Godot::Vector3.new(c0, 0, s0), bot_center + Godot::Vector3.new(c1, 0, s1), color, verts, cols)
      end

      # Side vertical ribs
      [Godot::Vector3.new(radius, 0, 0), Godot::Vector3.new(-radius, 0, 0),
       Godot::Vector3.new(0, 0, radius), Godot::Vector3.new(0, 0, -radius)].each do |offset|
        build_line(bot_center + offset, top_center + offset, color, verts, cols)
      end

      # Hemispherical dome arcs
      half_segs = segs // 2
      half_step = MathHelpers::PI / half_segs.to_f32
      (0...half_segs).each do |i|
        a0 = i * half_step
        a1 = (i + 1) * half_step
        c0 = Math.cos(a0).to_f32 * radius
        s0 = Math.sin(a0).to_f32 * radius
        c1 = Math.cos(a1).to_f32 * radius
        s1 = Math.sin(a1).to_f32 * radius

        # Top dome in XY and ZY
        build_line(top_center + Godot::Vector3.new(c0, s0, 0), top_center + Godot::Vector3.new(c1, s1, 0), color, verts, cols)
        build_line(top_center + Godot::Vector3.new(0, s0, c0), top_center + Godot::Vector3.new(0, s1, c1), color, verts, cols)

        # Bottom dome in XY and ZY
        build_line(bot_center + Godot::Vector3.new(c0, -s0, 0), bot_center + Godot::Vector3.new(c1, -s1, 0), color, verts, cols)
        build_line(bot_center + Godot::Vector3.new(0, -s0, c0), bot_center + Godot::Vector3.new(0, -s1, c1), color, verts, cols)
      end
    end

    # --- 8. Plane ---
    def self.build_plane(
      center : Godot::Vector3,
      normal : Godot::Vector3,
      size : Godot::Vector2,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      n = normal.normalized
      u, v = MathHelpers.orthonormal_plane(n)

      hx = size.x * 0.5_f32
      hy = size.y * 0.5_f32

      p0 = center - u * hx - v * hy
      p1 = center + u * hx - v * hy
      p2 = center + u * hx + v * hy
      p3 = center - u * hx + v * hy

      build_line(p0, p1, color, verts, cols)
      build_line(p1, p2, color, verts, cols)
      build_line(p2, p3, color, verts, cols)
      build_line(p3, p0, color, verts, cols)

      # Diagonal cross
      build_line(p0, p2, color, verts, cols)
      build_line(p1, p3, color, verts, cols)

      # Normal indicator
      build_arrow(center, center + n * (Math.min(size.x, size.y) * 0.4_f32), color, 0.15_f32, verts, cols)
    end

    # --- 9. Points (3D crosshairs) ---
    def self.build_points(
      points : Array(Godot::Vector3),
      size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      hs = size * 0.5_f32
      points.each do |p|
        build_line(p - Godot::Vector3.new(hs, 0, 0), p + Godot::Vector3.new(hs, 0, 0), color, verts, cols)
        build_line(p - Godot::Vector3.new(0, hs, 0), p + Godot::Vector3.new(0, hs, 0), color, verts, cols)
        build_line(p - Godot::Vector3.new(0, 0, hs), p + Godot::Vector3.new(0, 0, hs), color, verts, cols)
      end
    end

    # --- 10. Position 3D (3 crossing axes) ---
    def self.build_position_3d(
      origin : Godot::Vector3,
      size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      hs = size * 0.5_f32
      build_line(origin - Godot::Vector3.new(hs, 0, 0), origin + Godot::Vector3.new(hs, 0, 0), color, verts, cols)
      build_line(origin - Godot::Vector3.new(0, hs, 0), origin + Godot::Vector3.new(0, hs, 0), color, verts, cols)
      build_line(origin - Godot::Vector3.new(0, 0, hs), origin + Godot::Vector3.new(0, 0, hs), color, verts, cols)
    end

    # --- 11. Coordinate Gizmo (RGB colored X, Y, Z axes) ---
    def self.build_gizmo(
      origin : Godot::Vector3,
      basis : Godot::Basis,
      size : Float32,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      # X axis = Red
      red = Godot::Color.new(1.0_f32, 0.1_f32, 0.1_f32, 1.0_f32)
      x_end = origin + basis.x.normalized * size
      build_arrow(origin, x_end, red, size * 0.2_f32, verts, cols)

      # Y axis = Green
      green = Godot::Color.new(0.1_f32, 1.0_f32, 0.1_f32, 1.0_f32)
      y_end = origin + basis.y.normalized * size
      build_arrow(origin, y_end, green, size * 0.2_f32, verts, cols)

      # Z axis = Blue
      blue = Godot::Color.new(0.2_f32, 0.4_f32, 1.0_f32, 1.0_f32)
      z_end = origin + basis.z.normalized * size
      build_arrow(origin, z_end, blue, size * 0.2_f32, verts, cols)
    end

    # --- 12. Grid ---
    def self.build_grid(
      center : Godot::Vector3,
      size : Godot::Vector2,
      subdivisions : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      subs = subdivisions.clamp(1, 100)
      hx = size.x * 0.5_f32
      hz = size.y * 0.5_f32

      step_x = size.x / subs.to_f32
      step_z = size.y / subs.to_f32

      (0..subs).each do |i|
        z = -hz + i * step_z
        build_line(center + Godot::Vector3.new(-hx, 0, z), center + Godot::Vector3.new(hx, 0, z), color, verts, cols)
      end

      (0..subs).each do |i|
        x = -hx + i * step_x
        build_line(center + Godot::Vector3.new(x, 0, -hz), center + Godot::Vector3.new(x, 0, hz), color, verts, cols)
      end
    end

    # --- 13. Camera Frustum ---
    def self.build_camera_frustum(
      origin : Godot::Vector3,
      basis : Godot::Basis,
      fov_deg : Float32,
      near : Float32,
      far : Float32,
      aspect : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      rad = MathHelpers.deg_to_rad(fov_deg * 0.5_f32)
      tan_f = Math.tan(rad).to_f32

      near_h = near * tan_f
      near_w = near_h * aspect

      far_h = far * tan_f
      far_w = far_h * aspect

      forward = -basis.z.normalized
      up = basis.y.normalized
      right = basis.x.normalized

      nc = origin + forward * near
      fc = origin + forward * far

      # Near quad corners
      n_tl = nc + up * near_h - right * near_w
      n_tr = nc + up * near_h + right * near_w
      n_br = nc - up * near_h + right * near_w
      n_bl = nc - up * near_h - right * near_w

      # Far quad corners
      f_tl = fc + up * far_h - right * far_w
      f_tr = fc + up * far_h + right * far_w
      f_br = fc - up * far_h + right * far_w
      f_bl = fc - up * far_h - right * far_w

      # Near rectangle
      build_line(n_tl, n_tr, color, verts, cols)
      build_line(n_tr, n_br, color, verts, cols)
      build_line(n_br, n_bl, color, verts, cols)
      build_line(n_bl, n_tl, color, verts, cols)

      # Far rectangle
      build_line(f_tl, f_tr, color, verts, cols)
      build_line(f_tr, f_br, color, verts, cols)
      build_line(f_br, f_bl, color, verts, cols)
      build_line(f_bl, f_tl, color, verts, cols)

      # Frustum pyramids edges
      build_line(origin, f_tl, color, verts, cols)
      build_line(origin, f_tr, color, verts, cols)
      build_line(origin, f_br, color, verts, cols)
      build_line(origin, f_bl, color, verts, cols)
    end

    # --- 14. Billboard Opaque Square ---
    def self.build_billboard_square(
      position : Godot::Vector3,
      size : Float32,
      camera_pos : Godot::Vector3,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      to_cam = (camera_pos - position)
      norm = to_cam.length > 0.001_f32 ? to_cam.normalized : Godot::Vector3.new(0, 0, 1)
      u, v = MathHelpers.orthonormal_plane(norm)

      hs = size * 0.5_f32
      p0 = position - u * hs - v * hs
      p1 = position + u * hs - v * hs
      p2 = position + u * hs + v * hs
      p3 = position - u * hs + v * hs

      # Wireframe square
      build_line(p0, p1, color, verts, cols)
      build_line(p1, p2, color, verts, cols)
      build_line(p2, p3, color, verts, cols)
      build_line(p3, p0, color, verts, cols)
      build_line(p0, p2, color, verts, cols)
    end

    # --- INNOVATIVE ITEM 1: Raycast Hit Visualizer ---
    def self.build_ray_hit(
      origin : Godot::Vector3,
      hit_point : Godot::Vector3,
      normal : Godot::Vector3,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      # 1. Incident ray
      build_line(origin, hit_point, color, verts, cols)

      # 2. Surface normal arrow pointing outward from hit point
      norm = normal.normalized
      arrow_col = Godot::Color.new(0.2_f32, 1.0_f32, 0.4_f32, 1.0_f32)
      build_arrow(hit_point, hit_point + norm * 0.8_f32, arrow_col, 0.2_f32, verts, cols)

      # 3. Surface impact ring
      disk_col = Godot::Color.new(1.0_f32, 0.3_f32, 0.3_f32, 1.0_f32)
      u, v = MathHelpers.orthonormal_plane(norm)
      radius = 0.3_f32
      segs = 16
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step
        p0 = hit_point + u * (Math.cos(a0).to_f32 * radius) + v * (Math.sin(a0).to_f32 * radius)
        p1 = hit_point + u * (Math.cos(a1).to_f32 * radius) + v * (Math.sin(a1).to_f32 * radius)
        build_line(p0, p1, disk_col, verts, cols)
      end
    end

    # --- INNOVATIVE ITEM 2: Parabolic Trajectory Arc Predictor ---
    def self.build_trajectory_arc(
      origin : Godot::Vector3,
      velocity : Godot::Vector3,
      gravity : Godot::Vector3,
      max_time : Float32,
      steps : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      st = steps.clamp(4, 100)
      dt = max_time / st.to_f32

      prev = origin
      (1..st).each do |i|
        t = i * dt
        # p(t) = p0 + v0*t + 0.5*g*t^2
        curr = origin + velocity * t + gravity * (0.5_f32 * t * t)
        build_line(prev, curr, color, verts, cols)
        prev = curr
      end

      # Impact ring at terminal position
      term_col = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32)
      radius = 0.4_f32
      segs = 16
      step = MathHelpers::TAU / segs.to_f32
      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step
        p0 = prev + Godot::Vector3.new(Math.cos(a0).to_f32 * radius, 0, Math.sin(a0).to_f32 * radius)
        p1 = prev + Godot::Vector3.new(Math.cos(a1).to_f32 * radius, 0, Math.sin(a1).to_f32 * radius)
        build_line(p0, p1, term_col, verts, cols)
      end
    end

    # --- INNOVATIVE ITEM 3: Vision / Sensor Cone ---
    def self.build_vision_cone(
      origin : Godot::Vector3,
      direction : Godot::Vector3,
      angle_deg : Float32,
      range : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      dir = direction.normalized
      half_rad = MathHelpers.deg_to_rad(angle_deg * 0.5_f32)
      base_dist = Math.cos(half_rad).to_f32 * range
      base_radius = Math.sin(half_rad).to_f32 * range

      u, v = MathHelpers.orthonormal_plane(dir)
      base_center = origin + dir * base_dist

      segs = segments.clamp(8, 36)
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step

        c0 = Math.cos(a0).to_f32 * base_radius
        s0 = Math.sin(a0).to_f32 * base_radius
        c1 = Math.cos(a1).to_f32 * base_radius
        s1 = Math.sin(a1).to_f32 * base_radius

        p0 = base_center + u * c0 + v * s0
        p1 = base_center + u * c1 + v * s1

        # Base circle arc
        build_line(p0, p1, color, verts, cols)

        # Ray from apex to base perimeter (every quarter or 4 segments)
        if i % (segs // 4) == 0
          build_line(origin, p0, color, verts, cols)
        end
      end

      # Center bore ray
      build_line(origin, origin + dir * range, color, verts, cols)
    end

    # --- INNOVATIVE ITEM 4: Oriented Bounding Box (OBB) ---
    def self.build_obb(
      center : Godot::Vector3,
      size : Godot::Vector3,
      basis : Godot::Basis,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      hx = size.x * 0.5_f32
      hy = size.y * 0.5_f32
      hz = size.z * 0.5_f32

      bx = basis.x.normalized * hx
      by = basis.y.normalized * hy
      bz = basis.z.normalized * hz

      c0 = center - bx - by - bz
      c1 = center + bx - by - bz
      c2 = center + bx - by + bz
      c3 = center - bx - by + bz
      c4 = center - bx + by - bz
      c5 = center + bx + by - bz
      c6 = center + bx + by + bz
      c7 = center - bx + by + bz

      # Bottom
      build_line(c0, c1, color, verts, cols)
      build_line(c1, c2, color, verts, cols)
      build_line(c2, c3, color, verts, cols)
      build_line(c3, c0, color, verts, cols)

      # Top
      build_line(c4, c5, color, verts, cols)
      build_line(c5, c6, color, verts, cols)
      build_line(c6, c7, color, verts, cols)
      build_line(c7, c4, color, verts, cols)

      # Vertical edges
      build_line(c0, c4, color, verts, cols)
      build_line(c1, c5, color, verts, cols)
      build_line(c2, c6, color, verts, cols)
      build_line(c3, c7, color, verts, cols)
    end

    # --- INNOVATIVE ITEM 5: Helical Spring / Joint ---
    def self.build_spring(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32,
      coils : Int32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      axis = (to - from)
      length = axis.length
      return if length < 0.0001_f32

      dir = axis / length
      u, v = MathHelpers.orthonormal_plane(dir)

      total_coils = coils.clamp(1, 30)
      total_segs = (total_coils * segments).clamp(16, 200)

      prev = from
      (1..total_segs).each do |i|
        t = i.to_f32 / total_segs.to_f32
        angle = t * total_coils * MathHelpers::TAU

        pt_on_axis = from + dir * (t * length)
        offset = u * (Math.cos(angle).to_f32 * radius) + v * (Math.sin(angle).to_f32 * radius)
        curr = pt_on_axis + offset

        build_line(prev, curr, color, verts, cols)
        prev = curr
      end
      build_line(prev, to, color, verts, cols)
    end

    # --- INNOVATIVE ITEM 6: Surface Contact Disk ---
    def self.build_surface_disk(
      position : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      norm = normal.normalized
      u, v = MathHelpers.orthonormal_plane(norm)

      segs = segments.clamp(8, 36)
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step
        p0 = position + u * (Math.cos(a0).to_f32 * radius) + v * (Math.sin(a0).to_f32 * radius)
        p1 = position + u * (Math.cos(a1).to_f32 * radius) + v * (Math.sin(a1).to_f32 * radius)
        build_line(p0, p1, color, verts, cols)
      end

      # Orthogonal normal arrow
      build_arrow(position, position + norm * (radius * 1.5_f32), color, radius * 0.3_f32, verts, cols)
    end

    # --- INNOVATIVE ITEM 7: Distance Measurement Ruler ---
    def self.build_ruler(
      from : Godot::Vector3,
      to : Godot::Vector3,
      tick_size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      dir = (to - from)
      len = dir.length
      return if len < 0.0001_f32

      # Main span line
      build_line(from, to, color, verts, cols)

      # End caps
      norm = dir / len
      u, _ = MathHelpers.orthonormal_plane(norm)
      ht = tick_size * 0.5_f32

      build_line(from - u * ht, from + u * ht, color, verts, cols)
      build_line(to - u * ht, to + u * ht, color, verts, cols)

      # Intermediate centimeter / meter tick marks
      ticks = (len / 1.0_f32).to_i
      if ticks > 1 && ticks < 20
        (1...ticks).each do |t_idx|
          pt = from + norm * t_idx.to_f32
          build_line(pt - u * (ht * 0.5_f32), pt + u * (ht * 0.5_f32), color, verts, cols)
        end
      end
    end

    # --- INNOVATIVE ITEM 8: Reticle 3D ---
    def self.build_reticle(
      position : Godot::Vector3,
      normal : Godot::Vector3,
      size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      norm = normal.normalized
      u, v = MathHelpers.orthonormal_plane(norm)

      inner = size * 0.25_f32
      outer = size * 0.5_f32

      # 4 crosshair tick marks
      build_line(position + u * inner, position + u * outer, color, verts, cols)
      build_line(position - u * inner, position - u * outer, color, verts, cols)
      build_line(position + v * inner, position + v * outer, color, verts, cols)
      build_line(position - v * inner, position - v * outer, color, verts, cols)

      # Outer circle ring
      segs = 16
      step = MathHelpers::TAU / segs.to_f32
      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step
        p0 = position + u * (Math.cos(a0).to_f32 * outer) + v * (Math.sin(a0).to_f32 * outer)
        p1 = position + u * (Math.cos(a1).to_f32 * outer) + v * (Math.sin(a1).to_f32 * outer)
        build_line(p0, p1, color, verts, cols)
      end
    end

    # --- 2D Items ---
    def self.build_line_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      verts << from
      verts << to
      cols << color
      cols << color
    end

    def self.build_arrow_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      head_size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      build_line_2d(from, to, color, verts, cols)

      dir = to - from
      len = dir.length
      return if len < 0.001_f32

      norm = dir / len
      perp = norm.perpendicular

      hs = head_size.clamp(2.0_f32, len * 0.5_f32)
      base_pt = to - norm * hs

      f0 = base_pt + perp * (hs * 0.5_f32)
      f1 = base_pt - perp * (hs * 0.5_f32)

      build_line_2d(to, f0, color, verts, cols)
      build_line_2d(to, f1, color, verts, cols)
    end

    def self.build_rect_2d(
      rect : Godot::Rect2,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      x0 = rect.position.x
      y0 = rect.position.y
      x1 = x0 + rect.size.x
      y1 = y0 + rect.size.y

      p0 = Godot::Vector2.new(x0, y0)
      p1 = Godot::Vector2.new(x1, y0)
      p2 = Godot::Vector2.new(x1, y1)
      p3 = Godot::Vector2.new(x0, y1)

      build_line_2d(p0, p1, color, verts, cols)
      build_line_2d(p1, p2, color, verts, cols)
      build_line_2d(p2, p3, color, verts, cols)
      build_line_2d(p3, p0, color, verts, cols)
    end

    def self.build_circle_2d(
      center : Godot::Vector2,
      radius : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      segs = segments.clamp(8, 64)
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step
        p0 = center + Godot::Vector2.new(Math.cos(a0).to_f32 * radius, Math.sin(a0).to_f32 * radius)
        p1 = center + Godot::Vector2.new(Math.cos(a1).to_f32 * radius, Math.sin(a1).to_f32 * radius)
        build_line_2d(p0, p1, color, verts, cols)
      end
    end
  end
end
