require "./debug_command"

module Diorite
  # Context object passed into scoped frame drawing blocks (`DebugDraw.frame { |d| ... }`).
  #
  # Provides convenient access to immediate-mode 2D and 3D drawing operations.
  #
  # ```crystal
  # DebugDraw.frame do |d|
  #   d.line_3d(start_pos, end_pos, Color.new(0, 1, 0))
  #   d.sphere_3d(center: player.position, radius: 1.5)
  #   d.circle_2d(Godot::Vector2.new(100, 100), 25.0)
  # end
  # ```
  class FrameContext
    # Draws a 3D line segment between two world positions.
    def line_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.line_3d(from, to, color, duration, on_top)
    end

    # Draws a 3D directional arrow with a conical arrowhead.
    def arrow_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), head_size : Float32 = 0.25_f32, duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.arrow_3d(from, to, color, head_size, duration, on_top)
    end

    # Draws an axis-aligned 3D bounding box wireframe.
    def box_3d(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), wireframe : Bool = true, duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.box_3d(center, size, color, wireframe, duration, on_top)
    end

    # Draws a 3D orthogonal ring wireframe sphere.
    def sphere_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), rings : Int32 = 16, duration : Float64 = 0.0, on_top : Bool = true)
      DebugDraw.sphere_3d(center, radius, color, rings, duration, on_top)
    end

    # Draws a 2D line segment between two canvas pixel coordinates.
    def line_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0)
      DebugDraw.line_2d(from, to, color, duration)
    end

    # Draws a 2D circle on the canvas overlay.
    def circle_2d(center : Godot::Vector2, radius : Float32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), segments : Int32 = 24, duration : Float64 = 0.0)
      DebugDraw.circle_2d(center, radius, color, segments, duration)
    end

    # Draws 2D points on the canvas overlay.
    def points_2d(points : Array(Godot::Vector2), size : Float32 = 4.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0)
      DebugDraw.points_2d(points, size, color, duration)
    end

    # Draws a continuous 2D polyline connecting an ordered list of points.
    def path_2d(points : Array(Godot::Vector2), color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0)
      DebugDraw.path_2d(points, color, duration)
    end

    # Draws a 2D text label on the canvas overlay.
    def text_2d(position : Godot::Vector2, text : String, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0)
      DebugDraw.text_2d(position, text, color, duration)
    end
  end

  # High-level immediate-mode debug drawing API for Godot Engine 4.8+.
  #
  # `DebugDraw` allows you to render primitives anywhere in game logic (e.g. `_process`,
  # `_physics_process`, collision signals, AI controllers) without manually managing scene nodes.
  #
  # Primitives are submitted to a centralized thread-safe queue and batch rendered by `DebugDrawManager`.
  #
  # ### Features:
  # - **High Render Priority**: 3D items render with `render_priority = 127` and depth test disabled.
  # - **2D Overlay**: 2D items render to an overlay `CanvasLayer` (layer 128, `z_index = 4096`).
  # - **Single-frame vs Timed**: Draw for a single frame (`duration: 0.0`) or persist for a timed duration (`duration: 2.5`).
  # - **Zero Garbage Generation**: Uses pre-allocated vertex ring buffers for high performance.
  #
  # ```crystal
  # # Draw an arrow for 3 seconds
  # DebugDraw.arrow_3d(player.position, player.position + player.velocity, Color.new(1, 0, 0), duration: 3.0)
  #
  # # Draw real-time sparkline telemetry in 2D
  # DebugDraw.telemetry_graph_2d("Velocity", player.speed, Rect2.new(20, 20, 160, 40))
  # ```
  module DebugDraw
    @@queue = DebugCommandQueue.new
    @@frame_context = FrameContext.new

    # Returns the global underlying command queue.
    def self.queue : DebugCommandQueue
      @@queue
    end

    # =========================================================================
    # STANDARD 3D PRIMITIVES
    # =========================================================================

    # Draws a 3D line segment between *from* and *to*.
    #
    # - *from*: Starting world coordinate.
    # - *to*: Ending world coordinate.
    # - *color*: Line color.
    # - *duration*: Lifetime in seconds (`0.0` for single-frame).
    # - *on_top*: When `true`, renders on top of geometry with depth test disabled.
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

    # Alias for `arrow_3d`. Draws a line with a terminal arrow head.
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

    # Draws a continuous 3D polyline connecting an ordered list of *points*.
    #
    # - *points*: Array of 3D vertices to connect in sequence.
    # - *color*: Path color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D directional arrow from *from* to *to* with a conical finned head.
    #
    # - *from*: Start position.
    # - *to*: End/tip position.
    # - *color*: Arrow color.
    # - *head_size*: Length of the arrow fin head in world units.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws an axis-aligned 3D bounding box (AABB) centered at *center*.
    #
    # - *center*: World center of the box.
    # - *size*: Full width, height, and depth dimensions.
    # - *color*: Wireframe color.
    # - *wireframe*: Whether to render wireframe edges.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D wireframe sphere composed of 3 orthogonal intersecting circular rings.
    #
    # - *center*: World center of the sphere.
    # - *radius*: Sphere radius in units.
    # - *color*: Ring wireframe color.
    # - *rings*: Number of angular segments per circle.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D wireframe cylinder with circular top/bottom caps and 4 vertical struts.
    #
    # - *center*: World center position.
    # - *radius*: Cylinder radius.
    # - *height*: Total height along local Y axis.
    # - *color*: Wireframe color.
    # - *segments*: Circle perimeter resolution.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D wireframe capsule with hemispherical top and bottom caps.
    #
    # - *center*: World center position.
    # - *radius*: Capsule cap radius.
    # - *height*: Total cylindrical height excluding hemisphere caps.
    # - *color*: Wireframe color.
    # - *segments*: Arc resolution.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws an oriented 3D plane quad with a center normal pointer.
    #
    # - *center*: Center position on the plane surface.
    # - *normal*: Surface normal vector (e.g. `Vector3.new(0, 1, 0)`).
    # - *size*: Width and depth extents.
    # - *color*: Boundary and normal indicator color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws small 3D crosshair markers for an array of world *points*.
    #
    # - *points*: Array of coordinates to mark.
    # - *size*: Crosshair half-extent.
    # - *color*: Marker color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3-axis crossing crosshair indicating position and scale.
    #
    # - *origin*: World origin of the crosshair.
    # - *size*: Half-length of the axis arms.
    # - *color*: Crosshair color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D coordinate transform gizmo with Red=X, Green=Y, Blue=Z axis vectors.
    #
    # - *origin*: World origin of the gizmo.
    # - *basis*: 3x3 rotational orientation matrix.
    # - *size*: Axis arm length.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D ground reference grid plane.
    #
    # - *center*: Grid center coordinate.
    # - *size*: Full X and Z grid dimensions.
    # - *subdivisions*: Number of grid line subdivisions per axis.
    # - *color*: Grid line color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D camera view frustum pyramid with near and far clipping rectangles.
    #
    # - *origin*: Camera eye position.
    # - *basis*: Camera orientation transform.
    # - *fov_deg*: Vertical field of view in degrees.
    # - *near*: Near clipping distance.
    # - *far*: Far clipping distance.
    # - *aspect*: Viewport aspect ratio (e.g. `16.0 / 9.0`).
    # - *color*: Frustum boundary wireframe color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a camera-facing billboard square marker in 3D world space.
    #
    # - *position*: Center position of the billboard.
    # - *size*: Side length of the square.
    # - *camera_pos*: Camera position used to compute billboard alignment.
    # - *color*: Marker color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a world-positioned 3D billboard text label with depth-test bypass.
    #
    # - *position*: World position for the text label.
    # - *text*: String content to display.
    # - *color*: Modulate text color.
    # - *duration*: Lifetime in seconds (`0.0` for single-frame).
    # - *on_top*: Render priority mode.
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

    # =========================================================================
    # INNOVATIVE 3D PRIMITIVES
    # =========================================================================

    # Draws a complete raycast hit visualization: incident ray, surface impact disc, and surface normal reflection vector.
    #
    # - *origin*: Raycasting start origin.
    # - *hit_point*: Surface collision point.
    # - *normal*: Surface normal vector at contact point.
    # - *color*: Visualizer color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Alias for `ray_hit_3d`.
    def self.raycast_hit_3d(
      origin : Godot::Vector3,
      hit_point : Godot::Vector3,
      normal : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.8_f32, 0.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      ray_hit_3d(origin, hit_point, normal, color, duration, on_top)
    end

    # Draws a ballistic parabolic trajectory arc computed under gravity.
    #
    # - *origin*: Projectile launch position.
    # - *velocity*: Initial muzzle/launch velocity vector.
    # - *gravity*: Acceleration due to gravity (default `-9.8` m/s² on Y).
    # - *max_time*: Total flight duration simulated.
    # - *steps*: Polyline resolution.
    # - *color*: Arc line color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a spherical sector vision/detection cone for AI sensory perception.
    #
    # - *origin*: Sensor/eye origin.
    # - *direction*: Forward look direction vector.
    # - *angle_deg*: Total field-of-view angle in degrees.
    # - *range*: Sight/detection radius.
    # - *color*: Cone boundary color.
    # - *segments*: Arc resolution.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws an arbitrarily oriented bounding box (OBB) defined by a 3x3 rotation `Basis`.
    #
    # - *center*: World center of the oriented box.
    # - *size*: Box extents along local basis vectors.
    # - *basis*: 3x3 rotation orientation matrix.
    # - *color*: Wireframe color.
    # - *wireframe*: Render wireframe edges.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a 3D helical wire spring between two world endpoints.
    #
    # - *from*: Start attachment point.
    # - *to*: End attachment point.
    # - *radius*: Coil radius.
    # - *coils*: Number of complete helical rotations.
    # - *segments*: Angular steps per coil.
    # - *color*: Wire color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws a normal-aligned circular surface disc indicating a collision or ground contact patch.
    #
    # - *position*: Center contact point.
    # - *normal*: Surface normal vector at contact point.
    # - *radius*: Disc radius.
    # - *segments*: Circle perimeter resolution.
    # - *color*: Disc outline color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Alias for `surface_disk_3d`.
    def self.surface_contact_3d(
      position : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      segments : Int32 = 24,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.8_f32, 0.9_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true
    ) : Void
      surface_disk_3d(position, normal, radius, segments, color, duration, on_top)
    end

    # Draws a calibrated distance ruler with tick marks and midpoint distance readout.
    #
    # - *from*: Start measurement position.
    # - *to*: End measurement position.
    # - *tick_size*: Length of ruler tick marks.
    # - *color*: Ruler and text color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Draws an aim reticle with a center circle and 4 corner target brackets.
    #
    # - *position*: Target center in world space.
    # - *normal*: Reticle plane normal (facing direction).
    # - *size*: Reticle bracket radius.
    # - *color*: Reticle color.
    # - *duration*: Lifetime in seconds.
    # - *on_top*: Render priority mode.
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

    # Appends a moving entity's *current_position* to an ongoing motion trail identified by *id*.
    #
    # - *id*: Unique identifier for the tracked entity.
    # - *current_position*: Current world coordinate of the entity.
    # - *max_points*: Maximum historical points retained in the trail.
    # - *color*: Trail line color.
    # - *on_top*: Render priority mode.
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

    # =========================================================================
    # 2D CANVAS PRIMITIVES
    # =========================================================================

    # Draws a 2D line segment on the canvas overlay between pixel coordinates *from* and *to*.
    #
    # - *from*: Start pixel coordinate.
    # - *to*: End pixel coordinate.
    # - *color*: Line color.
    # - *duration*: Lifetime in seconds.
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

    # Draws a 2D directional arrow with a triangular head on the canvas overlay.
    #
    # - *from*: Start pixel coordinate.
    # - *to*: End/tip pixel coordinate.
    # - *color*: Arrow color.
    # - *head_size*: Length of arrowhead in pixels.
    # - *duration*: Lifetime in seconds.
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

    # Draws a 2D wireframe rectangle on the canvas overlay.
    #
    # - *rect*: 2D bounding rectangle in pixels.
    # - *color*: Outline color.
    # - *duration*: Lifetime in seconds.
    def self.rect_2d(
      rect : Godot::Rect2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Rect, color, duration)
      cmd.rect = rect
      @@queue.push_2d(cmd)
    end

    # Draws a 2D wireframe circle on the canvas overlay.
    #
    # - *center*: Pixel coordinate of the circle center.
    # - *radius*: Circle radius in pixels.
    # - *color*: Outline color.
    # - *segments*: Number of perimeter segments.
    # - *duration*: Lifetime in seconds.
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

    # Draws discrete 2D point markers on the canvas overlay.
    #
    # - *points*: Array of 2D canvas pixel coordinates.
    # - *size*: Marker crosshair half-size in pixels.
    # - *color*: Marker color.
    # - *duration*: Lifetime in seconds.
    def self.points_2d(
      points : Array(Godot::Vector2),
      size : Float32 = 4.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Points, color, duration)
      cmd.points = points
      cmd.f0 = size
      @@queue.push_2d(cmd)
    end

    # Draws a continuous 2D polyline connecting an ordered list of *points*.
    #
    # - *points*: Array of 2D canvas pixel coordinates to connect.
    # - *color*: Path color.
    # - *duration*: Lifetime in seconds.
    def self.path_2d(
      points : Array(Godot::Vector2),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Path, color, duration)
      cmd.points = points
      @@queue.push_2d(cmd)
    end

    # Alias for `path_2d`.
    def self.line_path_2d(
      points : Array(Godot::Vector2),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      path_2d(points, color, duration)
    end

    # Draws a 2D text label on the canvas overlay at pixel position *position*.
    #
    # - *position*: Canvas coordinate for label.
    # - *text*: String content to render.
    # - *color*: Text color modulate.
    # - *duration*: Lifetime in seconds.
    def self.text_2d(
      position : Godot::Vector2,
      text : String,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0
    ) : Void
      cmd = TextCommand2D.new(position, text, color, duration)
      @@queue.push_text_2d(cmd)
    end

    # Updates and renders a real-time scrolling telemetry sparkline graph on the 2D canvas overlay.
    #
    # - *title*: Unique graph series label (e.g. `"FPS"` or `"Velocity"`).
    # - *value*: Current numerical data sample.
    # - *rect*: Bounding rectangle on the canvas for the graph box.
    # - *min_val*: Expected lower value clamp bound.
    # - *max_val*: Expected upper value clamp bound.
    # - *color*: Graph line and border color.
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

    # Alias for `stat_graph_2d`.
    def self.telemetry_graph_2d(
      title : String,
      value : Number,
      rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32),
      min_val : Number = 0.0,
      max_val : Number = 100.0,
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32)
    ) : Void
      stat_graph_2d(title, value, rect, min_val, max_val, color)
    end

    # Yields a scoped `FrameContext` block for batching debug draws within a single frame.
    #
    # ```crystal
    # DebugDraw.frame do |d|
    #   d.line_3d(from, to)
    #   d.sphere_3d(center, 1.0)
    # end
    # ```
    def self.frame(&block : FrameContext ->) : Void
      yield @@frame_context
    end

    # Clears all active 2D and 3D commands from the global queue immediately.
    def self.clear : Void
      @@queue.clear
    end
  end
end
