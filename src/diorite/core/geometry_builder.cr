require "./math_helpers"

module Diorite
  # High-performance algorithmic generator for 2D and 3D debug geometry.
  #
  # Emits line-list vertices (`Vector3` or `Vector2`) and vertex color arrays suitable for direct
  # ingestion by Godot's `ImmediateMesh` surface buffers (`surface_add_vertex` and `surface_set_color`).
  #
  # Designed for zero heap reallocation during frame loops when passed pre-sized arrays.
  module GeometryBuilder
    include MathHelpers

    # Generates a single 3D line segment between *from* and *to*.
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

    # Generates a 3D directional arrow with a 4-fin conical arrowhead.
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

    # Generates a continuous 3D polyline connecting an ordered list of *points*.
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

    # Generates an axis-aligned 3D bounding box (AABB) wireframe with 12 edges.
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

    # Generates a 3D wireframe sphere composed of 3 orthogonal intersecting rings.
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

    # Generates a 3D wireframe cylinder with circular caps and longitudinal ribs.
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

    # Generates a 3D wireframe capsule with hemispherical domes and side struts.
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

    # Generates an oriented 3D plane quad with a center normal pointer.
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

      hu = size.x * 0.5_f32
      hv = size.y * 0.5_f32

      p0 = center - u * hu - v * hv
      p1 = center + u * hu - v * hv
      p2 = center + u * hu + v * hv
      p3 = center - u * hu + v * hv

      # Perimeter
      build_line(p0, p1, color, verts, cols)
      build_line(p1, p2, color, verts, cols)
      build_line(p2, p3, color, verts, cols)
      build_line(p3, p0, color, verts, cols)

      # Diagonal cross
      build_line(p0, p2, color, verts, cols)
      build_line(p1, p3, color, verts, cols)

      # Surface normal arrow
      build_arrow(center, center + n * (Math.min(hu, hv) * 0.8_f32), color, 0.2_f32, verts, cols)
    end

    # Generates small 3D crosshair markers for an array of world *points*.
    def self.build_points(
      points : Array(Godot::Vector3),
      size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      hs = size * 0.5_f32
      points.each do |pt|
        build_line(pt - Godot::Vector3.new(hs, 0, 0), pt + Godot::Vector3.new(hs, 0, 0), color, verts, cols)
        build_line(pt - Godot::Vector3.new(0, hs, 0), pt + Godot::Vector3.new(0, hs, 0), color, verts, cols)
        build_line(pt - Godot::Vector3.new(0, 0, hs), pt + Godot::Vector3.new(0, 0, hs), color, verts, cols)
      end
    end

    # Generates a 3-axis crossing crosshair indicating position and scale.
    def self.build_position_3d(
      origin : Godot::Vector3,
      size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      build_line(origin - Godot::Vector3.new(size, 0, 0), origin + Godot::Vector3.new(size, 0, 0), color, verts, cols)
      build_line(origin - Godot::Vector3.new(0, size, 0), origin + Godot::Vector3.new(0, size, 0), color, verts, cols)
      build_line(origin - Godot::Vector3.new(0, 0, size), origin + Godot::Vector3.new(0, 0, size), color, verts, cols)
    end

    # Generates a 3D coordinate transform gizmo with Red=X, Green=Y, Blue=Z axis vectors.
    def self.build_gizmo(
      origin : Godot::Vector3,
      basis : Godot::Basis,
      size : Float32,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      red = Godot::Color.new(1.0_f32, 0.1_f32, 0.1_f32, 1.0_f32)
      green = Godot::Color.new(0.1_f32, 0.9_f32, 0.1_f32, 1.0_f32)
      blue = Godot::Color.new(0.2_f32, 0.4_f32, 1.0_f32, 1.0_f32)

      # Extract columns/axes from Basis as local coordinate axes
      axis_x = basis.x.normalized * size
      axis_y = basis.y.normalized * size
      axis_z = basis.z.normalized * size

      build_arrow(origin, origin + axis_x, red, size * 0.2_f32, verts, cols)
      build_arrow(origin, origin + axis_y, green, size * 0.2_f32, verts, cols)
      build_arrow(origin, origin + axis_z, blue, size * 0.2_f32, verts, cols)
    end

    # Generates a 3D ground reference grid plane.
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

      dx = size.x / subs.to_f32
      dz = size.y / subs.to_f32

      (0..subs).each do |i|
        # Lines parallel to Z axis
        x = -hx + i.to_f32 * dx
        build_line(center + Godot::Vector3.new(x, 0, -hz), center + Godot::Vector3.new(x, 0, hz), color, verts, cols)

        # Lines parallel to X axis
        z = -hz + i.to_f32 * dz
        build_line(center + Godot::Vector3.new(-hx, 0, z), center + Godot::Vector3.new(hx, 0, z), color, verts, cols)
      end
    end

    # Generates a 3D camera view frustum pyramid with near and far clipping rectangles.
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
      fwd = -basis.z.normalized
      up = basis.y.normalized
      right = basis.x.normalized

      half_fov_rad = MathHelpers.deg_to_rad(fov_deg * 0.5_f32)
      tan_fov = Math.tan(half_fov_rad).to_f32

      near_h = near * tan_fov
      near_w = near_h * aspect
      far_h = far * tan_fov
      far_w = far_h * aspect

      near_center = origin + fwd * near
      far_center = origin + fwd * far

      # Near rectangle corners
      n_tl = near_center + up * near_h - right * near_w
      n_tr = near_center + up * near_h + right * near_w
      n_br = near_center - up * near_h + right * near_w
      n_bl = near_center - up * near_h - right * near_w

      # Far rectangle corners
      f_tl = far_center + up * far_h - right * far_w
      f_tr = far_center + up * far_h + right * far_w
      f_br = far_center - up * far_h + right * far_w
      f_bl = far_center - up * far_h - right * far_w

      # Near plane rectangle
      build_line(n_tl, n_tr, color, verts, cols)
      build_line(n_tr, n_br, color, verts, cols)
      build_line(n_br, n_bl, color, verts, cols)
      build_line(n_bl, n_tl, color, verts, cols)

      # Far plane rectangle
      build_line(f_tl, f_tr, color, verts, cols)
      build_line(f_tr, f_br, color, verts, cols)
      build_line(f_br, f_bl, color, verts, cols)
      build_line(f_bl, f_tl, color, verts, cols)

      # Connecting pyramid rays
      build_line(origin, f_tl, color, verts, cols)
      build_line(origin, f_tr, color, verts, cols)
      build_line(origin, f_br, color, verts, cols)
      build_line(origin, f_bl, color, verts, cols)
    end

    # Generates a camera-facing billboard square marker in 3D world space.
    def self.build_billboard_square(
      position : Godot::Vector3,
      size : Float32,
      camera_pos : Godot::Vector3,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      dir_to_cam = (camera_pos - position)
      norm = dir_to_cam.length > 0.001_f32 ? dir_to_cam.normalized : Godot::Vector3.new(0, 0, 1)

      u, v = MathHelpers.orthonormal_plane(norm)
      hs = size * 0.5_f32

      p0 = position - u * hs - v * hs
      p1 = position + u * hs - v * hs
      p2 = position + u * hs + v * hs
      p3 = position - u * hs + v * hs

      build_line(p0, p1, color, verts, cols)
      build_line(p1, p2, color, verts, cols)
      build_line(p2, p3, color, verts, cols)
      build_line(p3, p0, color, verts, cols)
    end

    # Generates a raycast hit visualization: incident ray, surface impact disc, and surface normal reflection vector.
    def self.build_ray_hit(
      origin : Godot::Vector3,
      hit_point : Godot::Vector3,
      normal : Godot::Vector3,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      # 1. Incoming ray line
      build_line(origin, hit_point, color, verts, cols)

      # 2. Surface impact disk
      build_surface_disk(hit_point, normal, 0.35_f32, 16, color, verts, cols)

      # 3. Reflected / Normal indicator
      norm = normal.normalized
      norm_color = Godot::Color.new(0.2_f32, 1.0_f32, 0.4_f32, 1.0_f32)
      build_arrow(hit_point, hit_point + norm * 1.0_f32, norm_color, 0.2_f32, verts, cols)

      # 4. Computed reflection ray
      incoming_dir = (hit_point - origin).normalized
      refl_dir = incoming_dir - norm * (2.0_f32 * incoming_dir.dot(norm))
      refl_color = Godot::Color.new(1.0_f32, 0.3_f32, 0.3_f32, 0.8_f32)
      build_line(hit_point, hit_point + refl_dir * 1.5_f32, refl_color, verts, cols)
    end

    # Generates a ballistic parabolic trajectory arc computed under gravity.
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
      step_count = steps.clamp(4, 100)
      dt = max_time / step_count.to_f32

      prev_pt = origin
      (1..step_count).each do |i|
        t = i.to_f32 * dt
        curr_pt = origin + velocity * t + gravity * (0.5_f32 * t * t)
        build_line(prev_pt, curr_pt, color, verts, cols)
        prev_pt = curr_pt
      end

      # Ground impact footprint circle at terminal point
      build_surface_disk(prev_pt, Godot::Vector3.new(0, 1, 0), 0.4_f32, 16, color, verts, cols)
    end

    # Generates a spherical sector vision/detection cone for AI sensory perception.
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
      u, v = MathHelpers.orthonormal_plane(dir)

      half_angle_rad = MathHelpers.deg_to_rad(angle_deg * 0.5_f32)
      cos_half = Math.cos(half_angle_rad).to_f32
      sin_half = Math.sin(half_angle_rad).to_f32

      segs = segments.clamp(8, 48)
      step = MathHelpers::TAU / segs.to_f32

      base_radius = range * sin_half
      base_dist = range * cos_half
      base_center = origin + dir * base_dist

      # Base circle perimeter and 4 radial rays
      prev_pt : Godot::Vector3? = nil
      first_pt : Godot::Vector3? = nil

      (0...segs).each do |i|
        theta = i * step
        cu = Math.cos(theta).to_f32 * base_radius
        cv = Math.sin(theta).to_f32 * base_radius
        pt = base_center + u * cu + v * cv

        first_pt = pt if i == 0
        if p = prev_pt
          build_line(p, pt, color, verts, cols)
        end
        prev_pt = pt

        # 4 rays from eye origin to cone perimeter
        if i % (segs // 4) == 0
          build_line(origin, pt, color, verts, cols)
        end
      end

      # Close circle
      if f = first_pt
        if p = prev_pt
          build_line(p, f, color, verts, cols)
        end
      end

      # Forward centerline
      center_col = Godot::Color.new(color.r, color.g, color.b, 0.4_f32)
      build_line(origin, origin + dir * range, center_col, verts, cols)
    end

    # Generates an arbitrarily oriented bounding box (OBB) defined by a 3x3 rotation `Basis`.
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

      # Basis columns
      bx = basis.x.normalized
      by = basis.y.normalized
      bz = basis.z.normalized

      # 8 transformed corners
      c0 = center - bx * hx - by * hy - bz * hz
      c1 = center + bx * hx - by * hy - bz * hz
      c2 = center + bx * hx - by * hy + bz * hz
      c3 = center - bx * hx - by * hy + bz * hz
      c4 = center - bx * hx + by * hy - bz * hz
      c5 = center + bx * hx + by * hy - bz * hz
      c6 = center + bx * hx + by * hy + bz * hz
      c7 = center - bx * hx + by * hy + bz * hz

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

      # Connecting pillars
      build_line(c0, c4, color, verts, cols)
      build_line(c1, c5, color, verts, cols)
      build_line(c2, c6, color, verts, cols)
      build_line(c3, c7, color, verts, cols)
    end

    # Generates a 3D helical wire spring between two world endpoints.
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
      axis = to - from
      len = axis.length
      return if len < 0.0001_f32

      norm_axis = axis / len
      u, v = MathHelpers.orthonormal_plane(norm_axis)

      total_coils = coils.clamp(2, 60)
      segs_per_coil = segments.clamp(6, 32)
      total_steps = total_coils * segs_per_coil

      prev_pt = from
      (1..total_steps).each do |i|
        fraction = i.to_f32 / total_steps.to_f32
        curr_dist = fraction * len
        theta = fraction * total_coils.to_f32 * MathHelpers::TAU

        curr_pt = from + norm_axis * curr_dist +
                  u * (Math.cos(theta).to_f32 * radius) +
                  v * (Math.sin(theta).to_f32 * radius)

        build_line(prev_pt, curr_pt, color, verts, cols)
        prev_pt = curr_pt
      end
    end

    # Generates a normal-aligned circular surface disc indicating a collision or ground contact patch.
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

      segs = segments.clamp(8, 48)
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i * step
        a1 = (i + 1) * step

        p0 = position + u * (Math.cos(a0).to_f32 * radius) + v * (Math.sin(a0).to_f32 * radius)
        p1 = position + u * (Math.cos(a1).to_f32 * radius) + v * (Math.sin(a1).to_f32 * radius)
        build_line(p0, p1, color, verts, cols)
      end

      # Crosshairs through center
      build_line(position - u * radius, position + u * radius, color, verts, cols)
      build_line(position - v * radius, position + v * radius, color, verts, cols)
    end

    # Generates a calibrated distance measurement ruler bar with tick marks between two points.
    def self.build_ruler(
      from : Godot::Vector3,
      to : Godot::Vector3,
      tick_size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      # Main line
      build_line(from, to, color, verts, cols)

      diff = to - from
      dist = diff.length
      return if dist < 0.01_f32

      norm_dir = diff / dist
      u, v = MathHelpers.orthonormal_plane(norm_dir)
      ht = tick_size * 0.5_f32

      # Terminal end caps
      build_line(from - u * ht, from + u * ht, color, verts, cols)
      build_line(to - u * ht, to + u * ht, color, verts, cols)

      # Metric subdivision ticks every 1 unit
      ticks = dist.floor.to_i32
      if ticks > 1
        (1...ticks).each do |step|
          pt = from + norm_dir * step.to_f32
          # Sub-ticks are half-height
          build_line(pt - u * (ht * 0.5_f32), pt + u * (ht * 0.5_f32), color, verts, cols)
        end
      end
    end

    # Generates an aim reticle with a center circle and 4 corner target brackets.
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

    # Generates a 3D swept sphere cast visualizing collision trajectory between *from* and *to*.
    def self.build_sphere_cast(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32,
      hit : Bool,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      build_sphere(from, radius, 12, color, verts, cols)
      build_sphere(to, radius, 12, color, verts, cols)

      dir = to - from
      len = dir.length
      return if len < 0.0001_f32

      norm = dir / len
      u, v = MathHelpers.orthonormal_plane(norm)

      build_line(from + u * radius, to + u * radius, color, verts, cols)
      build_line(from - u * radius, to - u * radius, color, verts, cols)
      build_line(from + v * radius, to + v * radius, color, verts, cols)
      build_line(from - v * radius, to - v * radius, color, verts, cols)

      if hit
        hit_col = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32)
        build_line(to - u * (radius * 1.3_f32), to + u * (radius * 1.3_f32), hit_col, verts, cols)
        build_line(to - v * (radius * 1.3_f32), to + v * (radius * 1.3_f32), hit_col, verts, cols)
      end
    end

    # Generates a 3D swept capsule cast between *from* and *to*.
    def self.build_capsule_cast(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32,
      height : Float32,
      hit : Bool,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      build_capsule(from, radius, height, 12, color, verts, cols)
      build_capsule(to, radius, height, 12, color, verts, cols)

      hh = (height * 0.5_f32) - radius
      hh = 0.0_f32 if hh < 0.0_f32

      top_offset = Godot::Vector3.new(0.0_f32, hh, 0.0_f32)
      bot_offset = Godot::Vector3.new(0.0_f32, -hh, 0.0_f32)

      build_line(from + top_offset, to + top_offset, color, verts, cols)
      build_line(from + bot_offset, to + bot_offset, color, verts, cols)
      build_line(from + Godot::Vector3.new(radius, 0.0_f32, 0.0_f32), to + Godot::Vector3.new(radius, 0.0_f32, 0.0_f32), color, verts, cols)
      build_line(from - Godot::Vector3.new(radius, 0.0_f32, 0.0_f32), to - Godot::Vector3.new(radius, 0.0_f32, 0.0_f32), color, verts, cols)
    end

    # Generates a 3D swept oriented or axis-aligned box cast between *from* and *to*.
    def self.build_box_cast(
      from : Godot::Vector3,
      to : Godot::Vector3,
      size : Godot::Vector3,
      hit : Bool,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      build_box(from, size, color, verts, cols)
      build_box(to, size, color, verts, cols)

      hx = size.x * 0.5_f32
      hy = size.y * 0.5_f32
      hz = size.z * 0.5_f32

      [-1.0_f32, 1.0_f32].each do |sx|
        [-1.0_f32, 1.0_f32].each do |sy|
          [-1.0_f32, 1.0_f32].each do |sz|
            offset = Godot::Vector3.new(hx * sx, hy * sy, hz * sz)
            build_line(from + offset, to + offset, color, verts, cols)
          end
        end
      end
    end

    # Generates a 3D cubic Bézier spline curve.
    def self.build_bezier_cubic(
      p0 : Godot::Vector3,
      p1 : Godot::Vector3,
      p2 : Godot::Vector3,
      p3 : Godot::Vector3,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color),
      show_hull : Bool = true
    ) : Void
      if show_hull
        hull_col = Godot::Color.new(color.r, color.g, color.b, color.a * 0.35_f32)
        build_line(p0, p1, hull_col, verts, cols)
        build_line(p1, p2, hull_col, verts, cols)
        build_line(p2, p3, hull_col, verts, cols)
      end

      segs = segments.clamp(4, 128)
      step = 1.0_f32 / segs.to_f32

      (0...segs).each do |i|
        t0 = i.to_f32 * step
        t1 = (i + 1).to_f32 * step

        u0 = 1.0_f32 - t0
        pt0 = p0 * (u0 * u0 * u0) + p1 * (3.0_f32 * u0 * u0 * t0) + p2 * (3.0_f32 * u0 * t0 * t0) + p3 * (t0 * t0 * t0)

        u1 = 1.0_f32 - t1
        pt1 = p0 * (u1 * u1 * u1) + p1 * (3.0_f32 * u1 * u1 * t1) + p2 * (3.0_f32 * u1 * t1 * t1) + p3 * (t1 * t1 * t1)

        build_line(pt0, pt1, color, verts, cols)
      end
    end

    # Generates a 3D Catmull-Rom spline through a sequence of waypoints.
    def self.build_catmull_rom(
      points : Array(Godot::Vector3),
      segments_per_curve : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color),
      loop : Bool = false
    ) : Void
      return if points.size < 2

      if points.size == 2
        build_line(points[0], points[1], color, verts, cols)
        return
      end

      segs = segments_per_curve.clamp(4, 32)
      step = 1.0_f32 / segs.to_f32
      n = points.size

      count = loop ? n : n - 1
      (0...count).each do |i|
        p0 = loop ? points[(i - 1 + n) % n] : (i > 0 ? points[i - 1] : points[0] - (points[1] - points[0]))
        p1 = points[i % n]
        p2 = points[(i + 1) % n]
        p3 = loop ? points[(i + 2) % n] : (i + 2 < n ? points[i + 2] : p2 + (p2 - p1))

        (0...segs).each do |s|
          t0 = s.to_f32 * step
          t1 = (s + 1).to_f32 * step

          pt0 = catmull_rom_eval(p0, p1, p2, p3, t0)
          pt1 = catmull_rom_eval(p0, p1, p2, p3, t1)

          build_line(pt0, pt1, color, verts, cols)
        end
      end
    end

    private def self.catmull_rom_eval(
      p0 : Godot::Vector3,
      p1 : Godot::Vector3,
      p2 : Godot::Vector3,
      p3 : Godot::Vector3,
      t : Float32
    ) : Godot::Vector3
      t2 = t * t
      t3 = t2 * t
      (
        (p1 * 2.0_f32) +
        (-p0 + p2) * t +
        (p0 * 2.0_f32 - p1 * 5.0_f32 + p2 * 4.0_f32 - p3) * t2 +
        (-p0 + p1 * 3.0_f32 - p2 * 3.0_f32 + p3) * t3
      ) * 0.5_f32
    end

    # Generates a 3D vision cone or spotlight frustum.
    def self.build_cone_3d(
      tip : Godot::Vector3,
      dir : Godot::Vector3,
      length : Float32,
      angle_rad : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      return if length <= 0.0_f32

      norm = dir.length > 0.0001_f32 ? dir.normalized : Godot::Vector3.new(0.0_f32, 0.0_f32, -1.0_f32)
      u, v = MathHelpers.orthonormal_plane(norm)

      base_center = tip + norm * length
      base_radius = length * Math.tan(angle_rad.clamp(0.01_f32, 1.55_f32)).to_f32

      segs = segments.clamp(8, 64)
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i.to_f32 * step
        a1 = (i + 1).to_f32 * step

        p0 = base_center + (u * Math.cos(a0).to_f32 + v * Math.sin(a0).to_f32) * base_radius
        p1 = base_center + (u * Math.cos(a1).to_f32 + v * Math.sin(a1).to_f32) * base_radius

        build_line(p0, p1, color, verts, cols)

        if i % (segs // 4).clamp(1, 16) == 0
          build_line(tip, p0, color, verts, cols)
        end
      end
    end

    # Generates an arbitrary 3D planar circle ring.
    def self.build_circle_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      return if radius <= 0.0_f32

      u, v = MathHelpers.orthonormal_plane(normal)
      segs = segments.clamp(8, 64)
      step = MathHelpers::TAU / segs.to_f32

      (0...segs).each do |i|
        a0 = i.to_f32 * step
        a1 = (i + 1).to_f32 * step
        p0 = center + (u * Math.cos(a0).to_f32 + v * Math.sin(a0).to_f32) * radius
        p1 = center + (u * Math.cos(a1).to_f32 + v * Math.sin(a1).to_f32) * radius
        build_line(p0, p1, color, verts, cols)
      end
    end

    # Generates a 3D actor card frame with ground anchor line.
    def self.build_actor_card_3d(
      position : Godot::Vector3,
      size : Godot::Vector2,
      color : Godot::Color,
      verts : Array(Godot::Vector3),
      cols : Array(Godot::Color)
    ) : Void
      card_h = size.y
      card_w = size.x
      half_w = card_w * 0.5_f32

      pole_bottom = position
      pole_top = position + Godot::Vector3.new(0.0_f32, card_h * 0.3_f32, 0.0_f32)
      build_line(pole_bottom, pole_top, color, verts, cols)

      # Card wireframe rect floating above anchor
      y_bot = pole_top.y
      y_top = y_bot + card_h

      c0 = Godot::Vector3.new(position.x - half_w, y_bot, position.z)
      c1 = Godot::Vector3.new(position.x + half_w, y_bot, position.z)
      c2 = Godot::Vector3.new(position.x + half_w, y_top, position.z)
      c3 = Godot::Vector3.new(position.x - half_w, y_top, position.z)

      build_line(c0, c1, color, verts, cols)
      build_line(c1, c2, color, verts, cols)
      build_line(c2, c3, color, verts, cols)
      build_line(c3, c0, color, verts, cols)
    end

    # Generates a 2D line segment between two canvas pixel coordinates.
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

    # Generates a 2D directional arrow with a triangular head on the canvas overlay.
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

    # Generates a 2D wireframe rectangle on the canvas overlay.
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

    # Generates a 2D wireframe circle on the canvas overlay.
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

    # Generates crosshair markers for a collection of 2D points on the canvas.
    def self.build_points_2d(
      points : Array(Godot::Vector2),
      size : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      hs = size * 0.5_f32
      points.each do |pt|
        build_line_2d(pt - Godot::Vector2.new(hs, 0.0_f32), pt + Godot::Vector2.new(hs, 0.0_f32), color, verts, cols)
        build_line_2d(pt - Godot::Vector2.new(0.0_f32, hs), pt + Godot::Vector2.new(0.0_f32, hs), color, verts, cols)
      end
    end

    # Generates a continuous 2D polyline connecting an ordered list of canvas points.
    def self.build_path_2d(
      points : Array(Godot::Vector2),
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      return if points.size < 2
      (0...points.size - 1).each do |i|
        build_line_2d(points[i], points[i + 1], color, verts, cols)
      end
    end

    # Generates a 2D wireframe stadium capsule connecting two center points with semicircular caps.
    def self.build_capsule_2d(
      p0 : Godot::Vector2,
      p1 : Godot::Vector2,
      radius : Float32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color),
      segments : Int32 = 12
    ) : Void
      dir = p1 - p0
      len = dir.length
      if len < 0.001_f32
        build_circle_2d(p0, radius, segments * 2, color, verts, cols)
        return
      end

      norm = dir / len
      perp = norm.perpendicular * radius

      # Side parallel connecting lines
      build_line_2d(p0 + perp, p1 + perp, color, verts, cols)
      build_line_2d(p0 - perp, p1 - perp, color, verts, cols)

      # Semicircle at p1 facing outward
      base_ang = Math.atan2(norm.y, norm.x).to_f32
      step = MathHelpers::PI / segments.to_f32

      (0...segments).each do |i|
        a0 = base_ang - (MathHelpers::PI * 0.5_f32) + i.to_f32 * step
        a1 = base_ang - (MathHelpers::PI * 0.5_f32) + (i + 1).to_f32 * step
        pt0 = p1 + Godot::Vector2.new(Math.cos(a0).to_f32 * radius, Math.sin(a0).to_f32 * radius)
        pt1 = p1 + Godot::Vector2.new(Math.cos(a1).to_f32 * radius, Math.sin(a1).to_f32 * radius)
        build_line_2d(pt0, pt1, color, verts, cols)
      end

      # Semicircle at p0 facing backward
      (0...segments).each do |i|
        a0 = base_ang + (MathHelpers::PI * 0.5_f32) + i.to_f32 * step
        a1 = base_ang + (MathHelpers::PI * 0.5_f32) + (i + 1).to_f32 * step
        pt0 = p0 + Godot::Vector2.new(Math.cos(a0).to_f32 * radius, Math.sin(a0).to_f32 * radius)
        pt1 = p0 + Godot::Vector2.new(Math.cos(a1).to_f32 * radius, Math.sin(a1).to_f32 * radius)
        build_line_2d(pt0, pt1, color, verts, cols)
      end
    end

    # Generates a 2D vision cone or field-of-view wedge.
    def self.build_vision_cone_2d(
      origin : Godot::Vector2,
      dir : Godot::Vector2,
      distance : Float32,
      angle_rad : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      return if distance <= 0.0_f32

      base_ang = dir.length > 0.001_f32 ? Math.atan2(dir.y, dir.x).to_f32 : 0.0_f32
      half_ang = angle_rad * 0.5_f32
      start_ang = base_ang - half_ang
      end_ang = base_ang + half_ang

      build_sector_2d(origin, distance, start_ang, end_ang, segments, color, verts, cols)
    end

    # Generates a 2D circular arc segment.
    def self.build_arc_2d(
      center : Godot::Vector2,
      radius : Float32,
      start_angle : Float32,
      end_angle : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      segs = segments.clamp(4, 64)
      step = (end_angle - start_angle) / segs.to_f32

      (0...segs).each do |i|
        a0 = start_angle + i.to_f32 * step
        a1 = start_angle + (i + 1).to_f32 * step
        p0 = center + Godot::Vector2.new(Math.cos(a0).to_f32 * radius, Math.sin(a0).to_f32 * radius)
        p1 = center + Godot::Vector2.new(Math.cos(a1).to_f32 * radius, Math.sin(a1).to_f32 * radius)
        build_line_2d(p0, p1, color, verts, cols)
      end
    end

    # Generates a 2D pie-slice sector with bounding radial rays.
    def self.build_sector_2d(
      center : Godot::Vector2,
      radius : Float32,
      start_angle : Float32,
      end_angle : Float32,
      segments : Int32,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color)
    ) : Void
      build_arc_2d(center, radius, start_angle, end_angle, segments, color, verts, cols)

      p_start = center + Godot::Vector2.new(Math.cos(start_angle).to_f32 * radius, Math.sin(start_angle).to_f32 * radius)
      p_end = center + Godot::Vector2.new(Math.cos(end_angle).to_f32 * radius, Math.sin(end_angle).to_f32 * radius)

      build_line_2d(center, p_start, color, verts, cols)
      build_line_2d(center, p_end, color, verts, cols)
    end

    # Generates a 2D calibrated measuring ruler with distance tick marks.
    def self.build_ruler_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color,
      verts : Array(Godot::Vector2),
      cols : Array(Godot::Color),
      tick_step : Float32 = 20.0_f32,
      tick_size : Float32 = 8.0_f32
    ) : Void
      build_line_2d(from, to, color, verts, cols)

      dir = to - from
      len = dir.length
      return if len < 0.001_f32

      norm = dir / len
      perp = norm.perpendicular * (tick_size * 0.5_f32)

      # Start and end caps
      build_line_2d(from - perp, from + perp, color, verts, cols)
      build_line_2d(to - perp, to + perp, color, verts, cols)

      step_size = tick_step.clamp(2.0_f32, len)
      num_ticks = (len / step_size).to_i32

      (1...num_ticks).each do |i|
        pos = from + norm * (i.to_f32 * step_size)
        build_line_2d(pos - perp, pos + perp, color, verts, cols)
      end
    end
  end
end
