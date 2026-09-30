require "./debug_command"

module Diorite
  class FrameContext
    # Context passed into DebugDraw.frame { |d| ... }
    def line_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.line_3d(from, to, color, duration, on_top)
    end

    def arrow_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), head_size : Float32 = 0.25_f32, duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.arrow_3d(from, to, color, head_size, duration, on_top)
    end

    def box_3d(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), wireframe : Bool = true, duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.box_3d(center, size, color, wireframe, duration, on_top)
    end

    def sphere_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), rings : Int32 = 16, duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.sphere_3d(center, radius, color, rings, duration, on_top)
    end

    def line_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0)
      DebugDraw.line_2d(from, to, color, duration)
    end

    def circle_2d(center : Godot::Vector2, radius : Float32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), segments : Int32 = 24, duration : Float64 = 0.0)
      DebugDraw.circle_2d(center, radius, color, segments, duration)
    end
  end

  module DebugDraw
    @@queue = DebugCommandQueue.new
    @@frame_context = FrameContext.new

    def self.queue : DebugCommandQueue
      @@queue
    end

    # --- STANDARD 3D ITEMS ---

    def self.line_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Line, color, duration, on_top)
      cmd.v0 = from
      cmd.v1 = to
      @@queue.push_3d(cmd)
    end

    def self.line_arrow_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      head_size : Float32 = 0.25_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      arrow_3d(from, to, color, head_size, duration, on_top)
    end

    def self.line_path_3d(
      points : Array(Godot::Vector3),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::LinePath, color, duration, on_top)
      cmd.path = points.dup
      @@queue.push_3d(cmd)
    end

    def self.arrow_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      head_size : Float32 = 0.25_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Arrow, color, duration, on_top)
      cmd.v0 = from
      cmd.v1 = to
      cmd.f0 = head_size
      @@queue.push_3d(cmd)
    end

    def self.box_3d(
      center : Godot::Vector3,
      size : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      wireframe : Bool = true,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Box, color, duration, on_top)
      cmd.v0 = center
      cmd.v1 = size
      cmd.wireframe = wireframe
      @@queue.push_3d(cmd)
    end

    def self.sphere_3d(
      center : Godot::Vector3,
      radius : Float32 = 1.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      rings : Int32 = 16,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Sphere, color, duration, on_top)
      cmd.v0 = center
      cmd.f0 = radius
      cmd.i0 = rings
      @@queue.push_3d(cmd)
    end

    def self.cylinder_3d(
      center : Godot::Vector3,
      radius : Float32 = 1.0_f32,
      height : Float32 = 2.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 16,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Cylinder, color, duration, on_top)
      cmd.v0 = center
      cmd.f0 = radius
      cmd.f1 = height
      cmd.i0 = segments
      @@queue.push_3d(cmd)
    end

    def self.capsule_3d(
      center : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      height : Float32 = 2.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 16,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Capsule, color, duration, on_top)
      cmd.v0 = center
      cmd.f0 = radius
      cmd.f1 = height
      cmd.i0 = segments
      @@queue.push_3d(cmd)
    end

    def self.plane_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
      size : Godot::Vector2 = Godot::Vector2.new(5.0_f32, 5.0_f32),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Plane, color, duration, on_top)
      cmd.v0 = center
      cmd.v1 = normal
      cmd.f0 = size.x
      cmd.f1 = size.y
      @@queue.push_3d(cmd)
    end

    def self.points_3d(
      points : Array(Godot::Vector3),
      size : Float32 = 0.1_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Points, color, duration, on_top)
      cmd.path = points.dup
      cmd.f0 = size
      @@queue.push_3d(cmd)
    end

    def self.position_3d(
      origin : Godot::Vector3,
      size : Float32 = 1.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Position3D, color, duration, on_top)
      cmd.v0 = origin
      cmd.f0 = size
      @@queue.push_3d(cmd)
    end

    def self.gizmo_3d(
      origin : Godot::Vector3,
      basis : Godot::Basis = Godot::Basis.new,
      size : Float32 = 1.0_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Gizmo, Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration, on_top)
      cmd.v0 = origin
      cmd.basis = basis
      cmd.f0 = size
      @@queue.push_3d(cmd)
    end

    def self.grid_3d(
      center : Godot::Vector3 = Godot::Vector3.new,
      size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32),
      subdivisions : Int32 = 10,
      color : Godot::Color = Godot::Color.new(0.5_f32, 0.5_f32, 0.5_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Grid, color, duration, on_top)
      cmd.v0 = center
      cmd.f0 = size.x
      cmd.f1 = size.y
      cmd.i0 = subdivisions
      @@queue.push_3d(cmd)
    end

    def self.camera_frustum_3d(
      origin : Godot::Vector3,
      basis : Godot::Basis,
      fov_deg : Float32 = 75.0_f32,
      near : Float32 = 0.1_f32,
      far : Float32 = 10.0_f32,
      aspect : Float32 = 1.777_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::CameraFrustum, color, duration, on_top)
      cmd.v0 = origin
      cmd.basis = basis
      cmd.f0 = fov_deg
      cmd.f1 = near
      cmd.f2 = far
      cmd.f3 = aspect
      @@queue.push_3d(cmd)
    end

    def self.billboard_square_3d(
      position : Godot::Vector3,
      size : Float32 = 0.5_f32,
      camera_pos : Godot::Vector3 = Godot::Vector3.new(0, 0, 5),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::BillboardSquare, color, duration, on_top)
      cmd.v0 = position
      cmd.v1 = camera_pos
      cmd.f0 = size
      @@queue.push_3d(cmd)
    end

    def self.text_3d(
      position : Godot::Vector3,
      text : String,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = TextCommand3D.new(position, text, color, duration, on_top)
      @@queue.push_text_3d(cmd)
    end

    # --- INNOVATIVE 3D ITEMS ---

    def self.ray_hit_3d(
      origin : Godot::Vector3,
      hit_point : Godot::Vector3,
      normal : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.8_f32, 0.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::RayHit, color, duration, on_top)
      cmd.v0 = origin
      cmd.v1 = hit_point
      cmd.v2 = normal
      @@queue.push_3d(cmd)
    end

    def self.trajectory_arc_3d(
      origin : Godot::Vector3,
      velocity : Godot::Vector3,
      gravity : Godot::Vector3 = Godot::Vector3.new(0.0_f32, -9.8_f32, 0.0_f32),
      max_time : Float32 = 3.0_f32,
      steps : Int32 = 40,
      color : Godot::Color = Godot::Color.new(0.2_f32, 1.0_f32, 0.3_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::TrajectoryArc, color, duration, on_top)
      cmd.v0 = origin
      cmd.v1 = velocity
      cmd.v2 = gravity
      cmd.f0 = max_time
      cmd.i0 = steps
      @@queue.push_3d(cmd)
    end

    def self.vision_cone_3d(
      origin : Godot::Vector3,
      direction : Godot::Vector3,
      angle_deg : Float32 = 45.0_f32,
      range : Float32 = 10.0_f32,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32),
      segments : Int32 = 24,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::VisionCone, color, duration, on_top)
      cmd.v0 = origin
      cmd.v1 = direction
      cmd.f0 = angle_deg
      cmd.f1 = range
      cmd.i0 = segments
      @@queue.push_3d(cmd)
    end

    def self.obb_3d(
      center : Godot::Vector3,
      size : Godot::Vector3,
      basis : Godot::Basis,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      wireframe : Bool = true,
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::OBB, color, duration, on_top)
      cmd.v0 = center
      cmd.v1 = size
      cmd.basis = basis
      cmd.wireframe = wireframe
      @@queue.push_3d(cmd)
    end

    def self.spring_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32 = 0.2_f32,
      coils : Int32 = 8,
      segments : Int32 = 16,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.9_f32, 0.1_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Spring, color, duration, on_top)
      cmd.v0 = from
      cmd.v1 = to
      cmd.f0 = radius
      cmd.i0 = coils
      cmd.i1 = segments
      @@queue.push_3d(cmd)
    end

    def self.surface_disk_3d(
      position : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      segments : Int32 = 24,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.8_f32, 0.9_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::SurfaceDisk, color, duration, on_top)
      cmd.v0 = position
      cmd.v1 = normal
      cmd.f0 = radius
      cmd.i0 = segments
      @@queue.push_3d(cmd)
    end

    def self.ruler_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      tick_size : Float32 = 0.2_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Ruler, color, duration, on_top)
      cmd.v0 = from
      cmd.v1 = to
      cmd.f0 = tick_size
      @@queue.push_3d(cmd)

      # Dynamic 3D midpoint distance text
      dist = (to - from).length
      mid = (from + to) * 0.5_f32 + Godot::Vector3.new(0, 0.15_f32, 0)
      text_3d(mid, "#{dist.round(2)}m", color, duration, on_top)
    end

    def self.reticle_3d(
      position : Godot::Vector3,
      normal : Godot::Vector3 = Godot::Vector3.new(0, 0, 1),
      size : Float32 = 0.5_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Reticle, color, duration, on_top)
      cmd.v0 = position
      cmd.v1 = normal
      cmd.f0 = size
      @@queue.push_3d(cmd)
    end

    def self.trail_3d(
      id : String,
      current_position : Godot::Vector3,
      max_points : Int32 = 60,
      color : Godot::Color = Godot::Color.new(0.9_f32, 0.2_f32, 0.9_f32, 1.0_f32),
      on_top : Bool = true
    ) : Void
      pts = @@queue.update_trail(id, current_position, max_points)
      if pts.size >= 2
        line_path_3d(pts, color, 0.0, on_top)
      end
    end

    # --- 2D ITEMS ---

    def self.line_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Line, color, duration)
      cmd.p0 = from
      cmd.p1 = to
      @@queue.push_2d(cmd)
    end

    def self.arrow_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      head_size : Float32 = 10.0_f32,
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Arrow, color, duration)
      cmd.p0 = from
      cmd.p1 = to
      cmd.f0 = head_size
      @@queue.push_2d(cmd)
    end

    def self.rect_2d(
      rect : Godot::Rect2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Rect, color, duration)
      cmd.rect = rect
      @@queue.push_2d(cmd)
    end

    def self.circle_2d(
      center : Godot::Vector2,
      radius : Float32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 24,
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Circle, color, duration)
      cmd.p0 = center
      cmd.f0 = radius
      cmd.i0 = segments
      @@queue.push_2d(cmd)
    end

    def self.text_2d(
      position : Godot::Vector2,
      text : String,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = TextCommand2D.new(position, text, color, duration)
      @@queue.push_text_2d(cmd)
    end

    def self.stat_graph_2d(
      title : String,
      value : Number,
      rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32),
      min_val : Number = 0.0,
      max_val : Number = 100.0,
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32)
    ) : Void
      graph = @@queue.update_graph(title, value.to_f32, rect, min_val.to_f32, max_val.to_f32, color)
      # Print latest value string above graph
      text_2d(Godot::Vector2.new(rect.position.x, rect.position.y - 16.0_f32), "#{title}: #{value.to_f32.round(1)}", color, 0.0)
    end

    # Scoped frame block syntax
    def self.frame(&block : FrameContext ->) : Void
      yield @@frame_context
    end
  end
end
