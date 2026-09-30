require "./debug_command"
require "./chart_builder"

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
    # Executes a block with a local 3D transform applied to all nested 3D drawing calls.
    def with_transform(xform : Godot::Transform3D, &block) : Void
      DebugDraw.with_transform(xform, &block)
    end

    # Pushes a 3D coordinate transform onto the local transform stack.
    def push_transform(xform : Godot::Transform3D) : Void
      DebugDraw.push_transform(xform)
    end

    # Pops the top 3D coordinate transform from the local transform stack.
    def pop_transform : Void
      DebugDraw.pop_transform
    end

    # Executes a block with all nested drawing commands assigned to *channel_name*.
    def channel(channel_name : String, &block : FrameContext ->) : Void
      DebugDraw.channel(channel_name, &block)
    end

    # Draws a 3D line segment between two world positions.
    def line_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.line_3d(from, to, color, duration, on_top, channel)
    end

    # Draws a line with a terminal arrow head.
    def line_arrow_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), head_size : Float32 = 0.25_f32, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.line_arrow_3d(from, to, color, head_size, duration, on_top, channel)
    end

    # Draws a continuous 3D polyline connecting an ordered list of points.
    def line_path_3d(points : Array(Godot::Vector3), color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.line_path_3d(points, color, duration, on_top, channel)
    end

    # Draws a 3D directional arrow with a conical arrowhead.
    def arrow_3d(from : Godot::Vector3, to : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), head_size : Float32 = 0.25_f32, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.arrow_3d(from, to, color, head_size, duration, on_top, channel)
    end

    # Draws an axis-aligned 3D bounding box wireframe.
    def box_3d(center : Godot::Vector3, size : Godot::Vector3, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), wireframe : Bool = true, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.box_3d(center, size, color, wireframe, duration, on_top, channel)
    end

    # Draws a 3D orthogonal ring wireframe sphere.
    def sphere_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), rings : Int32 = 16, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.sphere_3d(center, radius, color, rings, duration, on_top, channel)
    end

    # Draws a 3D cylinder wireframe.
    def cylinder_3d(center : Godot::Vector3, radius : Float32 = 1.0_f32, height : Float32 = 2.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), segments : Int32 = 16, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.cylinder_3d(center, radius, height, color, segments, duration, on_top, channel)
    end

    # Draws a 3D capsule wireframe.
    def capsule_3d(center : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 2.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), segments : Int32 = 16, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.capsule_3d(center, radius, height, color, segments, duration, on_top, channel)
    end

    # Draws a 3D plane quad.
    def plane_3d(center : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32), size : Godot::Vector2 = Godot::Vector2.new(5.0_f32, 5.0_f32), color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.plane_3d(center, normal, size, color, duration, on_top, channel)
    end

    # Draws 3D point markers.
    def points_3d(points : Array(Godot::Vector3), size : Float32 = 0.1_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.points_3d(points, size, color, duration, on_top, channel)
    end

    # Draws a 3-axis crossing position marker.
    def position_3d(origin : Godot::Vector3, size : Float32 = 1.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.position_3d(origin, size, color, duration, on_top, channel)
    end

    # Draws an RGB coordinate transform gizmo.
    def gizmo_3d(origin : Godot::Vector3, basis : Godot::Basis = Godot::Basis.new, size : Float32 = 1.0_f32, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.gizmo_3d(origin, basis, size, duration, on_top, channel)
    end

    # Draws a 3D ground reference grid.
    def grid_3d(origin : Godot::Vector3 = Godot::Vector3.new, size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32), subdivisions : Int32 = 10, color : Godot::Color = Godot::Color.new(0.6_f32, 0.6_f32, 0.6_f32, 0.5_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil, center : Godot::Vector3? = nil)
      DebugDraw.grid_3d(origin, size, subdivisions, color, duration, on_top, channel, center)
    end

    # Draws a 3D camera frustum wireframe.
    def camera_frustum_3d(origin : Godot::Vector3, basis : Godot::Basis, fov_deg : Float32 = 75.0_f32, near : Float32 = 0.05_f32, far : Float32 = 10.0_f32, aspect : Float32 = 1.777_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 0.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.camera_frustum_3d(origin, basis, fov_deg, near, far, aspect, color, duration, on_top, channel)
    end

    # Draws a camera-facing billboard square.
    def billboard_square_3d(center : Godot::Vector3 = Godot::Vector3.new, size : Float32 = 1.0_f32, camera_pos : Godot::Vector3 = Godot::Vector3.new, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil, position : Godot::Vector3? = nil)
      DebugDraw.billboard_square_3d(center, size, camera_pos, color, duration, on_top, channel, position)
    end

    # Draws a raycast collision result.
    def ray_hit_3d(from : Godot::Vector3 = Godot::Vector3.new, hit_point : Godot::Vector3 = Godot::Vector3.new, normal : Godot::Vector3 = Godot::Vector3.new, color : Godot::Color = Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil, origin : Godot::Vector3? = nil)
      DebugDraw.ray_hit_3d(from, hit_point, normal, color, duration, on_top, channel, origin)
    end

    # Draws a ballistic projectile trajectory arc.
    def trajectory_arc_3d(origin : Godot::Vector3, velocity : Godot::Vector3, gravity : Godot::Vector3 = Godot::Vector3.new(0.0_f32, -9.8_f32, 0.0_f32), max_time : Float32 = 3.0_f32, steps : Int32 = 40, color : Godot::Color = Godot::Color.new(0.2_f32, 1.0_f32, 0.3_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.trajectory_arc_3d(origin, velocity, gravity, max_time, steps, color, duration, on_top, channel)
    end

    # Draws a 3D vision / sensory cone.
    def vision_cone_3d(origin : Godot::Vector3, direction : Godot::Vector3, angle_deg : Float32 = 45.0_f32, range : Float32 = 10.0_f32, color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32), segments : Int32 = 24, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.vision_cone_3d(origin, direction, angle_deg, range, color, segments, duration, on_top, channel)
    end

    # Draws an oriented bounding box (OBB).
    def obb_3d(center : Godot::Vector3, size : Godot::Vector3, basis : Godot::Basis, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), wireframe : Bool = true, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.obb_3d(center, size, basis, color, wireframe, duration, on_top, channel)
    end

    # Draws a 3D helical wire spring.
    def spring_3d(from : Godot::Vector3, to : Godot::Vector3, radius : Float32 = 0.2_f32, coils : Int32 = 8, segments : Int32 = 16, color : Godot::Color = Godot::Color.new(1.0_f32, 0.9_f32, 0.1_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.spring_3d(from, to, radius, coils, segments, color, duration, on_top, channel)
    end

    # Draws a circular surface contact disc.
    def surface_disk_3d(position : Godot::Vector3, normal : Godot::Vector3, radius : Float32 = 0.5_f32, segments : Int32 = 24, color : Godot::Color = Godot::Color.new(0.0_f32, 0.8_f32, 0.9_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.surface_disk_3d(position, normal, radius, segments, color, duration, on_top, channel)
    end

    # Draws a 3D distance measuring ruler.
    def ruler_3d(from : Godot::Vector3, to : Godot::Vector3, tick_size : Float32 = 0.2_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.ruler_3d(from, to, tick_size, color, duration, on_top, channel)
    end

    # Draws a 3D aiming reticle.
    def reticle_3d(position : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0, 0, 1), size : Float32 = 0.5_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.reticle_3d(position, normal, size, color, duration, on_top, channel)
    end

    # Updates a 3D motion trail.
    def trail_3d(id : String, current_position : Godot::Vector3, max_points : Int32 = 60, color : Godot::Color = Godot::Color.new(0.9_f32, 0.2_f32, 0.9_f32, 1.0_f32), on_top : Bool = true)
      DebugDraw.trail_3d(id, current_position, max_points, color, on_top)
    end

    # Draws a swept sphere cast.
    def sphere_cast_3d(from : Godot::Vector3, to : Godot::Vector3, radius : Float32 = 0.5_f32, hit : Bool = false, color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.sphere_cast_3d(from, to, radius, hit, color, duration, on_top, channel)
    end

    # Draws a swept capsule cast.
    def capsule_cast_3d(from : Godot::Vector3, to : Godot::Vector3, radius : Float32 = 0.5_f32, height : Float32 = 1.8_f32, hit : Bool = false, color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.capsule_cast_3d(from, to, radius, height, hit, color, duration, on_top, channel)
    end

    # Draws a swept box cast.
    def box_cast_3d(from : Godot::Vector3, to : Godot::Vector3, size : Godot::Vector3 = Godot::Vector3.new(1.0_f32, 1.0_f32, 1.0_f32), hit : Bool = false, color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.box_cast_3d(from, to, size, hit, color, duration, on_top, channel)
    end

    # Draws a 3D cubic Bézier curve.
    def bezier_cubic_3d(p0 : Godot::Vector3, p1 : Godot::Vector3, p2 : Godot::Vector3, p3 : Godot::Vector3, segments : Int32 = 32, color : Godot::Color = Godot::Color.new(1.0_f32, 0.8_f32, 0.0_f32, 1.0_f32), show_hull : Bool = true, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.bezier_cubic_3d(p0, p1, p2, p3, segments, color, show_hull, duration, on_top, channel)
    end

    # Draws a 3D Catmull-Rom spline curve.
    def catmull_rom_3d(points : Array(Godot::Vector3), segments_per_curve : Int32 = 16, color : Godot::Color = Godot::Color.new(0.4_f32, 0.8_f32, 1.0_f32, 1.0_f32), loop : Bool = false, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.catmull_rom_3d(points, segments_per_curve, color, loop, duration, on_top, channel)
    end

    # Draws a 3D vision cone or spotlight frustum.
    def cone_3d(tip : Godot::Vector3, dir : Godot::Vector3, length : Float32 = 5.0_f32, angle_rad : Float32 = 0.52359877_f32, segments : Int32 = 16, color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 0.8_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.cone_3d(tip, dir, length, angle_rad, segments, color, duration, on_top, channel)
    end

    # Draws a 3D planar circle ring.
    def circle_3d(center : Godot::Vector3, normal : Godot::Vector3 = Godot::Vector3.new(0, 1, 0), radius : Float32 = 1.0_f32, segments : Int32 = 24, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.circle_3d(center, normal, radius, segments, color, duration, on_top, channel)
    end

    # Draws a 3D actor card billboard with anchor line and optional stats.
    def actor_card_3d(position : Godot::Vector3, title : String, stats : Hash(String, String)? = nil, size : Godot::Vector2 = Godot::Vector2.new(1.2_f32, 0.8_f32), color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.actor_card_3d(position, title, stats, size, color, duration, on_top, channel)
    end

    # Draws a 3D pie or donut chart.
    def pie_chart_3d(center : Godot::Vector3, normal : Godot::Vector3, radius : Float32, slices : Array(PieSlice), inner_radius : Float32 = 0.0_f32, duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.pie_chart_3d(center, normal, radius, slices, inner_radius, duration, on_top, channel)
    end

    # Draws a 3D radial gauge.
    def gauge_3d(center : Godot::Vector3, normal : Godot::Vector3, radius : Float32, value : Float32, min_val : Float32 = 0.0_f32, max_val : Float32 = 100.0_f32, title : String = "", color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.gauge_3d(center, normal, radius, value, min_val, max_val, title, color, duration, on_top, channel)
    end

    # Draws a 3D billboard text label.
    def text_3d(position : Godot::Vector3, text : String, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, on_top : Bool = true, channel : String? = nil)
      DebugDraw.text_3d(position, text, color, duration, on_top, channel)
    end

    # Draws a 2D line segment.
    def line_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.line_2d(from, to, color, duration, channel)
    end

    # Draws a 2D directional arrow.
    def arrow_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), head_size : Float32 = 10.0_f32, duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.arrow_2d(from, to, color, head_size, duration, channel)
    end

    # Draws a 2D wireframe rectangle.
    def rect_2d(rect : Godot::Rect2, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.rect_2d(rect, color, duration, channel)
    end

    # Draws a 2D circle on the canvas overlay.
    def circle_2d(center : Godot::Vector2, radius : Float32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), segments : Int32 = 24, duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.circle_2d(center, radius, color, segments, duration, channel)
    end

    # Draws 2D points on the canvas overlay.
    def points_2d(points : Array(Godot::Vector2), size : Float32 = 4.0_f32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.points_2d(points, size, color, duration, channel)
    end

    # Draws a continuous 2D polyline connecting an ordered list of points.
    def path_2d(points : Array(Godot::Vector2), color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.path_2d(points, color, duration, channel)
    end

    # Draws a 2D stadium capsule.
    def capsule_2d(p0 : Godot::Vector2, p1 : Godot::Vector2, radius : Float32, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), segments : Int32 = 12, duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.capsule_2d(p0, p1, radius, color, segments, duration, channel)
    end

    # Draws a 2D vision cone or detection wedge.
    def vision_cone_2d(origin : Godot::Vector2, dir : Godot::Vector2, distance : Float32, angle_rad : Float32, segments : Int32 = 16, color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.vision_cone_2d(origin, dir, distance, angle_rad, segments, color, duration, channel)
    end

    # Draws a 2D circular arc.
    def arc_2d(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.arc_2d(center, radius, start_angle, end_angle, segments, color, duration, channel)
    end

    # Draws a 2D pie-slice sector.
    def sector_2d(center : Godot::Vector2, radius : Float32, start_angle : Float32, end_angle : Float32, segments : Int32 = 24, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.sector_2d(center, radius, start_angle, end_angle, segments, color, duration, channel)
    end

    # Draws a 2D calibrated measuring ruler.
    def ruler_2d(from : Godot::Vector2, to : Godot::Vector2, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), tick_step : Float32 = 20.0_f32, tick_size : Float32 = 8.0_f32, duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.ruler_2d(from, to, color, tick_step, tick_size, duration, channel)
    end

    # Draws a 2D pie or donut chart.
    def pie_chart_2d(center : Godot::Vector2, radius : Float32, slices : Array(PieSlice), inner_radius : Float32 = 0.0_f32, duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.pie_chart_2d(center, radius, slices, inner_radius, duration, channel)
    end

    # Draws a 2D bar chart or histogram.
    def bar_chart_2d(rect : Godot::Rect2, bars : Array(BarData), horizontal : Bool = false, title : String = "", duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.bar_chart_2d(rect, bars, horizontal, title, duration, channel)
    end

    # Draws a 2D radial gauge.
    def gauge_2d(center : Godot::Vector2, radius : Float32, value : Float32, min_val : Float32 = 0.0_f32, max_val : Float32 = 100.0_f32, title : String = "", color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.gauge_2d(center, radius, value, min_val, max_val, title, color, duration, channel)
    end

    # Draws a 2D text label on the canvas overlay.
    def text_2d(position : Godot::Vector2, text : String, color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration : Float64 = 0.0, channel : String? = nil)
      DebugDraw.text_2d(position, text, color, duration, channel)
    end

    # Renders a real-time sparkline telemetry graph.
    def stat_graph_2d(title : String, value : Number, rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32), min_val : Number = 0.0, max_val : Number = 100.0, color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32))
      DebugDraw.stat_graph_2d(title, value, rect, min_val, max_val, color)
    end

    # Alias for `stat_graph_2d`.
    def telemetry_graph_2d(title : String, value : Number, rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32), min_val : Number = 0.0, max_val : Number = 100.0, color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32))
      DebugDraw.telemetry_graph_2d(title, value, rect, min_val, max_val, color)
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
  # - **Category / Channel Filtering**: Organize draws into channels (`channel: "ai"`) and toggle them on the fly.
  # - **Local-space Transform Stacks**: Draw relative to any node with `DebugDraw.with_transform(node.global_transform)`.
  # - **Frame Freeze Mode**: Pause frame decay with `DebugDraw.freeze!` to orbit the camera freely and inspect transient bugs.
  # - **Full Charting Suite**: 2D/3D Pie and Donut charts, 2D Bar charts, and 2D/3D Radial gauges.
  # - **Game Dev Helpers**: Swept shape casts (SphereCast, CapsuleCast, BoxCast), cubic Bézier & Catmull-Rom splines, actor cards, 2D vision cones, and rulers.
  # - **Multi-series Telemetry**: Real-time scrolling performance graphs with threshold guidelines.
  module DebugDraw
    @@queue = DebugCommandQueue.new
    @@frame_context = FrameContext.new
    @@transform_stack = Array(Godot::Transform3D).new
    @@current_channel : String = "default"

    # Returns the global underlying command queue.
    def self.queue : DebugCommandQueue
      @@queue
    end

    # Master switch toggling all debug drawing on/off.
    def self.enabled : Bool
      @@queue.enabled
    end

    # Sets master drawing switch.
    def self.enabled=(val : Bool)
      @@queue.enabled = val
    end

    # Pauses frame decay allowing static freecam inspection of active debug shapes.
    def self.freeze! : Void
      @@queue.freeze!
    end

    # Unfreezes frame decay resuming normal lifetime decay.
    def self.unfreeze! : Void
      @@queue.unfreeze!
    end

    # Toggles freeze state.
    def self.toggle_freeze! : Void
      @@queue.toggle_freeze!
    end

    # Returns whether the debug queue is frozen.
    def self.frozen? : Bool
      @@queue.frozen?
    end

    # Enables a filtered channel.
    def self.enable_channel(name : String) : Void
      @@queue.enable_channel(name)
    end

    # Disables a filtered channel, suppressing all associated commands.
    def self.disable_channel(name : String) : Void
      @@queue.disable_channel(name)
    end

    # Returns true if the channel is currently enabled.
    def self.channel_enabled?(name : String) : Bool
      @@queue.channel_enabled?(name)
    end

    # Current active drawing channel name.
    def self.current_channel : String
      @@current_channel
    end

    # Sets the active channel for the duration of the given block.
    def self.with_channel(channel_name : String, &block) : Void
      prev = @@current_channel
      @@current_channel = channel_name
      begin
        yield
      ensure
        @@current_channel = prev
      end
    end

    # Yields `FrameContext` scoped to a specific channel.
    def self.channel(channel_name : String, &block : FrameContext ->) : Void
      with_channel(channel_name) do
        yield @@frame_context
      end
    end

    # Pushes a 3D coordinate transform onto the stack.
    def self.push_transform(xform : Godot::Transform3D) : Void
      curr = @@transform_stack.last?
      @@transform_stack << (curr ? curr * xform : xform)
    end

    # Pops the current 3D coordinate transform from the stack.
    def self.pop_transform : Void
      @@transform_stack.pop?
    end

    # Returns the active top transform on the stack, if any.
    def self.current_transform : Godot::Transform3D?
      @@transform_stack.last?
    end

    # Executes a block with a local transform pushed to the stack.
    def self.with_transform(xform : Godot::Transform3D, &block) : Void
      push_transform(xform)
      begin
        yield
      ensure
        pop_transform
      end
    end

    # Transforms a 3D position vector by the active transform stack if present.
    def self.apply_pos(pos : Godot::Vector3) : Godot::Vector3
      if t = @@transform_stack.last?
        t * pos
      else
        pos
      end
    end

    # Transforms a 3D direction vector by the active transform stack basis if present.
    def self.apply_dir(dir : Godot::Vector3) : Godot::Vector3
      if t = @@transform_stack.last?
        t.basis * dir
      else
        dir
      end
    end

    # Transforms a 3D basis orientation by the active transform stack basis if present.
    def self.apply_basis(basis : Godot::Basis) : Godot::Basis
      if t = @@transform_stack.last?
        t.basis * basis
      else
        basis
      end
    end

    # =========================================================================
    # STANDARD 3D PRIMITIVES
    # =========================================================================

    # Draws a 3D line segment between *from* and *to*.
    def self.line_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Line, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Alias for `arrow_3d`. Draws a line with a terminal arrow head.
    def self.line_arrow_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      head_size : Float32 = 0.25_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      arrow_3d(from, to, color, head_size, duration, on_top, channel)
    end

    # Draws a continuous 3D polyline connecting an ordered list of *points*.
    def self.line_path_3d(
      points : Array(Godot::Vector3),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::LinePath, color, duration, on_top)
      cmd.path = points.map { |pt| apply_pos(pt) }
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D directional arrow from *from* to *to* with a conical finned head.
    def self.arrow_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      head_size : Float32 = 0.25_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Arrow, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.f0 = head_size
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws an axis-aligned 3D bounding box (AABB) centered at *center*.
    def self.box_3d(
      center : Godot::Vector3,
      size : Godot::Vector3,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      wireframe : Bool = true,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Box, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.v1 = size
      cmd.wireframe = wireframe
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D orthogonal ring wireframe sphere centered at *center*.
    def self.sphere_3d(
      center : Godot::Vector3,
      radius : Float32 = 1.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      rings : Int32 = 16,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Sphere, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.f0 = radius
      cmd.i0 = rings
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D wireframe cylinder with circular top/bottom caps.
    def self.cylinder_3d(
      center : Godot::Vector3,
      radius : Float32 = 1.0_f32,
      height : Float32 = 2.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 16,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Cylinder, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.f0 = radius
      cmd.f1 = height
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D wireframe capsule with hemispherical top and bottom caps.
    def self.capsule_3d(
      center : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      height : Float32 = 2.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 16,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Capsule, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.f0 = radius
      cmd.f1 = height
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws an oriented 3D plane quad with a center normal pointer.
    def self.plane_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
      size : Godot::Vector2 = Godot::Vector2.new(5.0_f32, 5.0_f32),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Plane, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.v1 = apply_dir(normal)
      cmd.f0 = size.x
      cmd.f1 = size.y
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws small 3D crosshair markers for an array of world *points*.
    def self.points_3d(
      points : Array(Godot::Vector3),
      size : Float32 = 0.1_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Points, color, duration, on_top)
      cmd.path = points.map { |pt| apply_pos(pt) }
      cmd.f0 = size
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3-axis crossing crosshair indicating position and scale.
    def self.position_3d(
      origin : Godot::Vector3,
      size : Float32 = 1.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Position3D, color, duration, on_top)
      cmd.v0 = apply_pos(origin)
      cmd.f0 = size
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D coordinate transform gizmo with Red=X, Green=Y, Blue=Z axis vectors.
    def self.gizmo_3d(
      origin : Godot::Vector3,
      basis : Godot::Basis = Godot::Basis.new,
      size : Float32 = 1.0_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Gizmo, Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration, on_top)
      cmd.v0 = apply_pos(origin)
      cmd.basis = apply_basis(basis)
      cmd.f0 = size
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D ground reference grid plane.
    def self.grid_3d(
      origin : Godot::Vector3 = Godot::Vector3.new,
      size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32),
      subdivisions : Int32 = 10,
      color : Godot::Color = Godot::Color.new(0.6_f32, 0.6_f32, 0.6_f32, 0.5_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil,
      center : Godot::Vector3? = nil
    ) : Void
      orig = center || origin
      cmd = Command3D.new(ShapeKind3D::Grid, color, duration, on_top)
      cmd.v0 = apply_pos(orig)
      cmd.f0 = size.x
      cmd.f1 = size.y
      cmd.i0 = subdivisions
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D camera viewing frustum wireframe.
    def self.camera_frustum_3d(
      origin : Godot::Vector3,
      basis : Godot::Basis,
      fov_deg : Float32 = 75.0_f32,
      near : Float32 = 0.05_f32,
      far : Float32 = 10.0_f32,
      aspect : Float32 = 1.777_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 0.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::CameraFrustum, color, duration, on_top)
      cmd.v0 = apply_pos(origin)
      cmd.basis = apply_basis(basis)
      cmd.f0 = fov_deg
      cmd.f1 = near
      cmd.f2 = far
      cmd.f3 = aspect
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a billboard square wireframe centered at *center*.
    def self.billboard_square_3d(
      center : Godot::Vector3 = Godot::Vector3.new,
      size : Float32 = 1.0_f32,
      camera_pos : Godot::Vector3 = Godot::Vector3.new,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil,
      position : Godot::Vector3? = nil
    ) : Void
      c = position || center
      cmd = Command3D.new(ShapeKind3D::BillboardSquare, color, duration, on_top)
      cmd.v0 = apply_pos(c)
      cmd.f0 = size
      cmd.v1 = camera_pos
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a raycast collision result showing cast ray and surface normal at the hit point.
    def self.ray_hit_3d(
      from : Godot::Vector3 = Godot::Vector3.new,
      hit_point : Godot::Vector3 = Godot::Vector3.new,
      normal : Godot::Vector3 = Godot::Vector3.new,
      color : Godot::Color = Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil,
      origin : Godot::Vector3? = nil
    ) : Void
      start_pt = origin || from
      cmd = Command3D.new(ShapeKind3D::RayHit, color, duration, on_top)
      cmd.v0 = apply_pos(start_pt)
      cmd.v1 = apply_pos(hit_point)
      cmd.v2 = apply_dir(normal)
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a ballistic projectile trajectory arc.
    def self.trajectory_arc_3d(
      origin : Godot::Vector3,
      velocity : Godot::Vector3,
      gravity : Godot::Vector3 = Godot::Vector3.new(0.0_f32, -9.8_f32, 0.0_f32),
      max_time : Float32 = 3.0_f32,
      steps : Int32 = 40,
      color : Godot::Color = Godot::Color.new(0.2_f32, 1.0_f32, 0.3_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::TrajectoryArc, color, duration, on_top)
      cmd.v0 = apply_pos(origin)
      cmd.v1 = apply_dir(velocity)
      cmd.v2 = gravity
      cmd.f0 = max_time
      cmd.i0 = steps
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a spherical sector vision/detection cone for AI sensory perception.
    def self.vision_cone_3d(
      origin : Godot::Vector3,
      direction : Godot::Vector3,
      angle_deg : Float32 = 45.0_f32,
      range : Float32 = 10.0_f32,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32),
      segments : Int32 = 24,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::VisionCone, color, duration, on_top)
      cmd.v0 = apply_pos(origin)
      cmd.v1 = apply_dir(direction)
      cmd.f0 = angle_deg
      cmd.f1 = range
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws an arbitrarily oriented bounding box (OBB) defined by a 3x3 rotation `Basis`.
    def self.obb_3d(
      center : Godot::Vector3,
      size : Godot::Vector3,
      basis : Godot::Basis,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      wireframe : Bool = true,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::OBB, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.v1 = size
      cmd.basis = apply_basis(basis)
      cmd.wireframe = wireframe
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D helical wire spring between two world endpoints.
    def self.spring_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32 = 0.2_f32,
      coils : Int32 = 8,
      segments : Int32 = 16,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.9_f32, 0.1_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Spring, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.f0 = radius
      cmd.i0 = coils
      cmd.i1 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a normal-aligned circular surface disc indicating a collision or ground contact patch.
    def self.surface_disk_3d(
      position : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      segments : Int32 = 24,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.8_f32, 0.9_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::SurfaceDisk, color, duration, on_top)
      cmd.v0 = apply_pos(position)
      cmd.v1 = apply_dir(normal)
      cmd.f0 = radius
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
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
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      surface_disk_3d(position, normal, radius, segments, color, duration, on_top, channel)
    end

    # Draws a calibrated distance ruler with tick marks and midpoint distance readout.
    def self.ruler_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      tick_size : Float32 = 0.2_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Ruler, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.f0 = tick_size
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)

      dist = (to - from).length
      mid = (cmd.v0 + cmd.v1) * 0.5_f32 + Godot::Vector3.new(0.0_f32, 0.15_f32, 0.0_f32)
      text_3d(mid, "#{dist.round(2)}m", color, duration, on_top, channel)
    end

    # Draws an aim reticle with a center circle and 4 corner target brackets.
    def self.reticle_3d(
      position : Godot::Vector3,
      normal : Godot::Vector3 = Godot::Vector3.new(0, 0, 1),
      size : Float32 = 0.5_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Reticle, color, duration, on_top)
      cmd.v0 = apply_pos(position)
      cmd.v1 = apply_dir(normal)
      cmd.f0 = size
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Appends a moving entity's *current_position* to an ongoing motion trail identified by *id*.
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

    # Draws a swept sphere cast visualizing collision trajectory between *from* and *to*.
    def self.sphere_cast_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      hit : Bool = false,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::SphereCast, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.f0 = radius
      cmd.hit = hit
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a swept capsule cast between *from* and *to*.
    def self.capsule_cast_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      radius : Float32 = 0.5_f32,
      height : Float32 = 1.8_f32,
      hit : Bool = false,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::CapsuleCast, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.f0 = radius
      cmd.f1 = height
      cmd.hit = hit
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a swept box cast between *from* and *to*.
    def self.box_cast_3d(
      from : Godot::Vector3,
      to : Godot::Vector3,
      size : Godot::Vector3 = Godot::Vector3.new(1.0_f32, 1.0_f32, 1.0_f32),
      hit : Bool = false,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::BoxCast, color, duration, on_top)
      cmd.v0 = apply_pos(from)
      cmd.v1 = apply_pos(to)
      cmd.v2 = size
      cmd.hit = hit
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D cubic Bézier spline curve with optional control hull.
    def self.bezier_cubic_3d(
      p0 : Godot::Vector3,
      p1 : Godot::Vector3,
      p2 : Godot::Vector3,
      p3 : Godot::Vector3,
      segments : Int32 = 32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.8_f32, 0.0_f32, 1.0_f32),
      show_hull : Bool = true,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::BezierCubic, color, duration, on_top)
      cmd.v0 = apply_pos(p0)
      cmd.v1 = apply_pos(p1)
      cmd.v2 = apply_pos(p2)
      cmd.v3 = apply_pos(p3)
      cmd.i0 = segments
      cmd.wireframe = show_hull
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D Catmull-Rom spline curve passing smoothly through *points*.
    def self.catmull_rom_3d(
      points : Array(Godot::Vector3),
      segments_per_curve : Int32 = 16,
      color : Godot::Color = Godot::Color.new(0.4_f32, 0.8_f32, 1.0_f32, 1.0_f32),
      loop : Bool = false,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::CatmullRom, color, duration, on_top)
      cmd.path = points.map { |pt| apply_pos(pt) }
      cmd.i0 = segments_per_curve
      cmd.wireframe = loop
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D vision cone or spotlight frustum.
    def self.cone_3d(
      tip : Godot::Vector3,
      dir : Godot::Vector3,
      length : Float32 = 5.0_f32,
      angle_rad : Float32 = 0.52359877_f32,
      segments : Int32 = 16,
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 0.8_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Cone3D, color, duration, on_top)
      cmd.v0 = apply_pos(tip)
      cmd.v1 = apply_dir(dir)
      cmd.f0 = length
      cmd.f1 = angle_rad
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws an arbitrary 3D planar circle ring.
    def self.circle_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3 = Godot::Vector3.new(0, 1, 0),
      radius : Float32 = 1.0_f32,
      segments : Int32 = 24,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::Circle3D, color, duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.v1 = apply_dir(normal)
      cmd.f0 = radius
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D actor card billboard with ground anchor and stats readout.
    def self.actor_card_3d(
      position : Godot::Vector3,
      title : String,
      stats : Hash(String, String)? = nil,
      size : Godot::Vector2 = Godot::Vector2.new(1.2_f32, 0.8_f32),
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      actual_pos = apply_pos(position)
      cmd = Command3D.new(ShapeKind3D::ActorCard3D, color, duration, on_top)
      cmd.v0 = actual_pos
      cmd.f0 = size.x
      cmd.f1 = size.y
      cmd.title = title
      cmd.stats_hash = stats
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)

      # Title label
      text_3d(actual_pos + Godot::Vector3.new(0.0_f32, size.y * 1.35_f32, 0.0_f32), title, color, duration, on_top, channel)

      # Stats lines
      if st = stats
        y_offset = 1.15_f32
        st.each do |k, v|
          text_3d(actual_pos + Godot::Vector3.new(0.0_f32, size.y * y_offset, 0.0_f32), "#{k}: #{v}", color, duration, on_top, channel)
          y_offset -= 0.2_f32
        end
      end
    end

    # Draws a 3D pie or donut chart oriented along *normal*.
    def self.pie_chart_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32,
      slices : Array(PieSlice),
      inner_radius : Float32 = 0.0_f32,
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = Command3D.new(ShapeKind3D::PieChart3D, Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration, on_top)
      cmd.v0 = apply_pos(center)
      cmd.v1 = apply_dir(normal)
      cmd.f0 = radius
      cmd.f1 = inner_radius
      cmd.pie_slices = slices
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)
    end

    # Draws a 3D radial gauge oriented along *normal*.
    def self.gauge_3d(
      center : Godot::Vector3,
      normal : Godot::Vector3,
      radius : Float32,
      value : Float32,
      min_val : Float32 = 0.0_f32,
      max_val : Float32 = 100.0_f32,
      title : String = "",
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      actual_pos = apply_pos(center)
      cmd = Command3D.new(ShapeKind3D::Gauge3D, color, duration, on_top)
      cmd.v0 = actual_pos
      cmd.v1 = apply_dir(normal)
      cmd.f0 = radius
      cmd.f1 = value
      cmd.f2 = min_val
      cmd.f3 = max_val
      cmd.title = title
      cmd.channel = channel || @@current_channel
      @@queue.push_3d(cmd)

      if title.size > 0
        text_3d(actual_pos + Godot::Vector3.new(0.0_f32, radius * 1.2_f32, 0.0_f32), "#{title}: #{value.round(1)}", color, duration, on_top, channel)
      end
    end

    # Draws a 3D camera-facing billboard text label at world position *position*.
    def self.text_3d(
      position : Godot::Vector3,
      text : String,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      on_top : Bool = true,
      channel : String? = nil
    ) : Void
      cmd = TextCommand3D.new(apply_pos(position), text, color, duration, on_top, channel || @@current_channel)
      @@queue.push_text_3d(cmd)
    end

    # =========================================================================
    # 2D CANVAS PRIMITIVES
    # =========================================================================

    # Draws a 2D line segment on the canvas overlay.
    def self.line_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Line, color, duration)
      cmd.p0 = from
      cmd.p1 = to
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D directional arrow with a triangular head on the canvas overlay.
    def self.arrow_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      head_size : Float32 = 10.0_f32,
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Arrow, color, duration)
      cmd.p0 = from
      cmd.p1 = to
      cmd.f0 = head_size
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D wireframe rectangle on the canvas overlay.
    def self.rect_2d(
      rect : Godot::Rect2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Rect, color, duration)
      cmd.rect = rect
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D wireframe circle on the canvas overlay.
    def self.circle_2d(
      center : Godot::Vector2,
      radius : Float32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 24,
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Circle, color, duration)
      cmd.p0 = center
      cmd.f0 = radius
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws discrete 2D point markers on the canvas overlay.
    def self.points_2d(
      points : Array(Godot::Vector2),
      size : Float32 = 4.0_f32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Points, color, duration)
      cmd.points = points
      cmd.f0 = size
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a continuous 2D polyline connecting an ordered list of *points*.
    def self.path_2d(
      points : Array(Godot::Vector2),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Path, color, duration)
      cmd.points = points
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Alias for `path_2d`.
    def self.line_path_2d(
      points : Array(Godot::Vector2),
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      path_2d(points, color, duration, channel)
    end

    # Draws a 2D wireframe stadium capsule connecting two center points.
    def self.capsule_2d(
      p0 : Godot::Vector2,
      p1 : Godot::Vector2,
      radius : Float32,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      segments : Int32 = 12,
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Capsule, color, duration)
      cmd.p0 = p0
      cmd.p1 = p1
      cmd.f0 = radius
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D vision cone or field-of-view wedge.
    def self.vision_cone_2d(
      origin : Godot::Vector2,
      dir : Godot::Vector2,
      distance : Float32,
      angle_rad : Float32,
      segments : Int32 = 16,
      color : Godot::Color = Godot::Color.new(0.0_f32, 0.9_f32, 1.0_f32, 0.8_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::VisionCone, color, duration)
      cmd.p0 = origin
      cmd.p1 = dir
      cmd.f0 = distance
      cmd.f1 = angle_rad
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D circular arc segment.
    def self.arc_2d(
      center : Godot::Vector2,
      radius : Float32,
      start_angle : Float32,
      end_angle : Float32,
      segments : Int32 = 24,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Arc, color, duration)
      cmd.p0 = center
      cmd.f0 = radius
      cmd.f2 = start_angle
      cmd.f3 = end_angle
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D pie-slice sector.
    def self.sector_2d(
      center : Godot::Vector2,
      radius : Float32,
      start_angle : Float32,
      end_angle : Float32,
      segments : Int32 = 24,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Sector, color, duration)
      cmd.p0 = center
      cmd.f0 = radius
      cmd.f2 = start_angle
      cmd.f3 = end_angle
      cmd.i0 = segments
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D calibrated measuring ruler with distance tick marks.
    def self.ruler_2d(
      from : Godot::Vector2,
      to : Godot::Vector2,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      tick_step : Float32 = 20.0_f32,
      tick_size : Float32 = 8.0_f32,
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Ruler, color, duration)
      cmd.p0 = from
      cmd.p1 = to
      cmd.f0 = tick_step
      cmd.f1 = tick_size
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)

      dist = (to - from).length
      mid = (from + to) * 0.5_f32 + Godot::Vector2.new(0.0_f32, -12.0_f32)
      text_2d(mid, "#{dist.round(1)}px", color, duration, channel)
    end

    # Draws a 2D pie or donut chart on the canvas.
    def self.pie_chart_2d(
      center : Godot::Vector2,
      radius : Float32,
      slices : Array(PieSlice),
      inner_radius : Float32 = 0.0_f32,
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::PieChart, Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration)
      cmd.p0 = center
      cmd.f0 = radius
      cmd.f1 = inner_radius
      cmd.pie_slices = slices
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)
    end

    # Draws a 2D bar chart or histogram on the canvas.
    def self.bar_chart_2d(
      rect : Godot::Rect2,
      bars : Array(BarData),
      horizontal : Bool = false,
      title : String = "",
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::BarChart, Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration)
      cmd.rect = rect
      cmd.bar_data = bars
      cmd.b0 = horizontal
      cmd.title = title
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)

      if title.size > 0
        text_2d(Godot::Vector2.new(rect.position.x, rect.position.y - 18.0_f32), title, Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), duration, channel)
      end
    end

    # Draws a 2D radial gauge on the canvas.
    def self.gauge_2d(
      center : Godot::Vector2,
      radius : Float32,
      value : Float32,
      min_val : Float32 = 0.0_f32,
      max_val : Float32 = 100.0_f32,
      title : String = "",
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = Command2D.new(ShapeKind2D::Gauge, color, duration)
      cmd.p0 = center
      cmd.f0 = radius
      cmd.f1 = value
      cmd.f2 = min_val
      cmd.f3 = max_val
      cmd.title = title
      cmd.channel = channel || @@current_channel
      @@queue.push_2d(cmd)

      if title.size > 0
        text_2d(Godot::Vector2.new(center.x - radius, center.y + radius + 8.0_f32), "#{title}: #{value.round(1)}", color, duration, channel)
      end
    end

    # Draws a 2D text label on the canvas overlay.
    def self.text_2d(
      position : Godot::Vector2,
      text : String,
      color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      duration : Float64 = 0.0,
      channel : String? = nil
    ) : Void
      cmd = TextCommand2D.new(position, text, color, duration, channel || @@current_channel)
      @@queue.push_text_2d(cmd)
    end

    # Updates and renders a real-time scrolling telemetry sparkline graph on the 2D canvas overlay.
    def self.stat_graph_2d(
      title : String,
      value : Number,
      rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32),
      min_val : Number = 0.0,
      max_val : Number = 100.0,
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32)
    ) : Void
      graph = @@queue.update_graph(title, value.to_f32, rect, min_val.to_f32, max_val.to_f32, color)
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

    # Updates a named series within a multi-series telemetry graph.
    def self.telemetry_series_2d(
      title : String,
      series_name : String,
      value : Number,
      color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32),
      rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32),
      min_val : Number = 0.0,
      max_val : Number = 100.0
    ) : Void
      graph = (@@queue.telemetry_graphs[title]? || @@queue.update_graph(title, value.to_f32, rect, min_val.to_f32, max_val.to_f32, color))
      graph.add_series_sample(series_name, value.to_f32, color)
      text_2d(Godot::Vector2.new(rect.position.x, rect.position.y - 16.0_f32), "#{title}: #{series_name}=#{value.to_f32.round(1)}", color, 0.0)
    end

    # Adds a horizontal threshold line across a telemetry graph.
    def self.telemetry_threshold_2d(
      title : String,
      value : Number,
      color : Godot::Color = Godot::Color.new(1.0_f32, 0.3_f32, 0.3_f32, 0.8_f32),
      label : String = ""
    ) : Void
      if g = @@queue.telemetry_graphs[title]?
        g.add_threshold(value, color, label)
      end
    end

    # Yields a scoped `FrameContext` block for batching debug draws within a single frame.
    def self.frame(&block : FrameContext ->) : Void
      yield @@frame_context
    end

    # Clears all active 2D and 3D commands from the global queue immediately.
    def self.clear : Void
      @@queue.clear
    end
  end
end
