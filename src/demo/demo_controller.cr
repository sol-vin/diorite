require "lapis"
require "../diorite/diorite"

@[Tool]
node DemoController < Node3D do
  @time : Float64 = 0.0

  def _ready : Void
    Godot.print("[DemoController] Initialized. Demonstrating 26 Diorite Debug Draw items!")
  end

  def _process(delta : Float64) : Void
    @time += delta
    t = @time.to_f32

    # --- 1. Standard 3D Items ---
    # Ground grid
    DebugDraw.grid_3d(
      center: Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
      size: Godot::Vector2.new(16.0_f32, 16.0_f32),
      subdivisions: 16,
      color: Godot::Color.new(0.3_f32, 0.3_f32, 0.35_f32, 1.0_f32)
    )

    # Origin pivot
    DebugDraw.position_3d(Godot::Vector3.new(0, 0, 0), size: 1.0_f32)

    # Static line & line with arrow
    DebugDraw.line_3d(Godot::Vector3.new(-5, 0, -5), Godot::Vector3.new(-5, 3, -5), Godot::Color.new(0.2, 0.8, 1.0))
    DebugDraw.arrow_3d(Godot::Vector3.new(-4, 0, -5), Godot::Vector3.new(-4, 3, -5), Godot::Color.new(1.0, 0.8, 0.2))

    # Box, Sphere, Cylinder, Capsule
    DebugDraw.box_3d(center: Godot::Vector3.new(-3, 1, 0), size: Godot::Vector3.new(1.5, 1.5, 1.5), color: Godot::Color.new(1.0, 0.3, 0.3))
    DebugDraw.sphere_3d(center: Godot::Vector3.new(0, 1, 0), radius: 0.8_f32, color: Godot::Color.new(0.3, 1.0, 0.3))
    DebugDraw.cylinder_3d(center: Godot::Vector3.new(3, 1, 0), radius: 0.6_f32, height: 1.8_f32, color: Godot::Color.new(0.3, 0.5, 1.0))
    DebugDraw.capsule_3d(center: Godot::Vector3.new(5, 1, 0), radius: 0.5_f32, height: 2.0_f32, color: Godot::Color.new(1.0, 0.4, 0.8))

    # Plane & Points
    DebugDraw.plane_3d(center: Godot::Vector3.new(-5, 0.1, 3), normal: Godot::Vector3.new(0, 1, 0), size: Godot::Vector2.new(2, 2), color: Godot::Color.new(0.8, 0.8, 0.2))
    pts = [Godot::Vector3.new(-5, 1, 4), Godot::Vector3.new(-4.5, 1.2, 4), Godot::Vector3.new(-4, 0.9, 4)]
    DebugDraw.points_3d(pts, size: 0.2_f32, color: Godot::Color.new(1.0, 1.0, 0.5))

    # Line Path
    path_nodes = [
      Godot::Vector3.new(2, 0.2, 3),
      Godot::Vector3.new(3, 0.8, 4),
      Godot::Vector3.new(4, 0.4, 3.5),
      Godot::Vector3.new(5, 1.0, 4.5)
    ]
    DebugDraw.line_path_3d(path_nodes, color: Godot::Color.new(0.9, 0.5, 0.1))

    # Camera Frustum & Billboard Square
    frustum_basis = Godot::Basis.new
    DebugDraw.camera_frustum_3d(origin: Godot::Vector3.new(0, 3, 6), basis: frustum_basis, fov_deg: 60.0_f32, near: 0.5_f32, far: 3.0_f32, aspect: 1.5_f32, color: Godot::Color.new(0.7, 0.7, 1.0))
    DebugDraw.billboard_square_3d(position: Godot::Vector3.new(0, 4, 0), size: 0.8_f32, color: Godot::Color.new(1.0, 0.6, 0.0))

    # 3D Text
    DebugDraw.text_3d(Godot::Vector3.new(0, 2.2, 0), "Diorite Debug Draw", Godot::Color.new(1, 1, 1))

    # --- 2. Innovative 3D Items ---
    # 1. Raycast Hit Visualizer
    hit_pos = Godot::Vector3.new(-2.0_f32 + Math.sin(t).to_f32 * 0.5_f32, 0.0_f32, -2.0_f32)
    DebugDraw.ray_hit_3d(
      origin: Godot::Vector3.new(-2, 3, -2),
      hit_point: hit_pos,
      normal: Godot::Vector3.new(0, 1, 0)
    )

    # 2. Trajectory Arc Predictor
    launch_vel = Godot::Vector3.new(Math.cos(t).to_f32 * 4.0_f32, 6.0_f32, Math.sin(t).to_f32 * 4.0_f32)
    DebugDraw.trajectory_arc_3d(
      origin: Godot::Vector3.new(0, 0.5, -4),
      velocity: launch_vel,
      gravity: Godot::Vector3.new(0, -9.8, 0),
      max_time: 1.5_f32
    )

    # 3. Vision / Sensor Cone (sweeping AI radar)
    cone_dir = Godot::Vector3.new(Math.sin(t * 1.5).to_f32, 0, Math.cos(t * 1.5).to_f32).normalized
    DebugDraw.vision_cone_3d(
      origin: Godot::Vector3.new(3, 0.5, -3),
      direction: cone_dir,
      angle_deg: 40.0_f32,
      range: 3.5_f32
    )

    # 4. Oriented Bounding Box (OBB - rotated box)
    rot_angle = t * 0.8_f32
    obb_basis = Godot::Basis.new(
      Godot::Vector3.new(Math.cos(rot_angle).to_f32, 0, -Math.sin(rot_angle).to_f32),
      Godot::Vector3.new(0, 1, 0),
      Godot::Vector3.new(Math.sin(rot_angle).to_f32, 0, Math.cos(rot_angle).to_f32)
    )
    DebugDraw.obb_3d(
      center: Godot::Vector3.new(-4, 1.5, -1),
      size: Godot::Vector3.new(1.2, 0.8, 2.0),
      basis: obb_basis,
      color: Godot::Color.new(0.9, 0.3, 0.9)
    )

    # 5. Helical Spring
    spring_end = Godot::Vector3.new(5, 2.5_f32 + Math.sin(t * 3.0).to_f32 * 0.8_f32, -3)
    DebugDraw.spring_3d(
      from: Godot::Vector3.new(5, 0.2, -3),
      to: spring_end,
      radius: 0.25_f32,
      coils: 7,
      color: Godot::Color.new(1.0, 0.8, 0.1)
    )

    # 6. Surface Contact Disk
    DebugDraw.surface_disk_3d(
      position: Godot::Vector3.new(1, 0.05, 3),
      normal: Godot::Vector3.new(0, 1, 0),
      radius: 0.6_f32
    )

    # 7. Distance Measurement Ruler
    ruler_target = Godot::Vector3.new(3.0_f32 + Math.sin(t).to_f32 * 1.5_f32, 1.5, 2.0)
    DebugDraw.ruler_3d(
      from: Godot::Vector3.new(1.0, 1.5, 2.0),
      to: ruler_target,
      color: Godot::Color.new(1.0, 1.0, 1.0)
    )

    # 8. Reticle 3D
    DebugDraw.reticle_3d(
      position: Godot::Vector3.new(0, 1.5, 4),
      normal: Godot::Vector3.new(0, 0, 1),
      size: 0.6_f32
    )

    # 9. Motion Trail
    moving_pt = Godot::Vector3.new(Math.cos(t * 2.0).to_f32 * 2.0_f32, 2.0_f32 + Math.sin(t * 4.0).to_f32 * 0.5_f32, Math.sin(t * 2.0).to_f32 * 2.0_f32)
    DebugDraw.trail_3d("orbiter", moving_pt, max_points: 50, color: Godot::Color.new(0.2, 1.0, 0.8))
    DebugDraw.sphere_3d(moving_pt, radius: 0.15_f32, color: Godot::Color.new(0.2, 1.0, 0.8), rings: 8)

    # --- 3. 2D Overlay Items & Telemetry Graph ---
    DebugDraw.line_2d(Godot::Vector2.new(20, 120), Godot::Vector2.new(160, 120), Godot::Color.new(1, 0.5, 0.2))
    DebugDraw.arrow_2d(Godot::Vector2.new(20, 150), Godot::Vector2.new(160, 150), Godot::Color.new(0.2, 0.8, 1))
    DebugDraw.rect_2d(Godot::Rect2.new(20, 180, 80, 50), Godot::Color.new(1, 0.2, 0.6))
    DebugDraw.circle_2d(Godot::Vector2.new(150, 205), radius: 25.0_f32, color: Godot::Color.new(0.8, 1, 0.2))
    DebugDraw.text_2d(Godot::Vector2.new(20, 245), "Diorite 2D Overlay active", Godot::Color.new(1, 1, 1))

    # Real-Time Telemetry Graph
    simulated_fps = 60.0_f32 + Math.sin(t * 5.0).to_f32 * 15.0_f32
    DebugDraw.stat_graph_2d(
      title: "Engine FPS",
      value: simulated_fps,
      rect: Godot::Rect2.new(20.0_f32, 20.0_f32, 180.0_f32, 50.0_f32),
      min_val: 30.0_f32,
      max_val: 90.0_f32,
      color: Godot::Color.new(0.2_f32, 1.0_f32, 0.4_f32, 1.0_f32)
    )
  end
end
