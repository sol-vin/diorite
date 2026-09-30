require "benchmark"
require "../src/diorite/diorite"

puts "========================================================================"
puts "  DIORITE DEBUG DRAW - COMPREHENSIVE PERFORMANCE BENCHMARK SUITE        "
puts "========================================================================"
puts "Crystal Version: #{Crystal::VERSION}"
puts "Target Platform: #{Crystal::DESCRIPTION}"
puts "Timestamp:       #{Time.utc.to_s}"
puts "========================================================================"
puts ""

# Pre-allocated scratch vertex and color arrays for zero-allocation geometry tests
verts_3d = Array(Godot::Vector3).new(8192)
cols_3d = Array(Godot::Color).new(8192)
verts_2d = Array(Godot::Vector2).new(8192)
cols_2d = Array(Godot::Color).new(8192)

c_red = Godot::Color.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32)
c_green = Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32)
c_blue = Godot::Color.new(0.0_f32, 0.5_f32, 1.0_f32, 1.0_f32)

v_zero = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
v_target = Godot::Vector3.new(10.0_f32, 15.0_f32, 20.0_f32)
v_up = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32)
v_fwd = Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32)
v_size = Godot::Vector3.new(2.0_f32, 4.0_f32, 2.0_f32)
basis_ident = Godot::Basis.new

v2_zero = Godot::Vector2.new(0.0_f32, 0.0_f32)
v2_target = Godot::Vector2.new(300.0_f32, 200.0_f32)
rect_demo = Godot::Rect2.new(10.0_f32, 10.0_f32, 200.0_f32, 100.0_f32)

path_pts_3d = (0..20).map { |i| Godot::Vector3.new(i.to_f32, Math.sin(i.to_f32).to_f32 * 5.0_f32, 0.0_f32) }
path_pts_2d = (0..20).map { |i| Godot::Vector2.new(i.to_f32 * 10.0_f32, Math.sin(i.to_f32).to_f32 * 20.0_f32 + 50.0_f32) }

# -----------------------------------------------------------------------------
# 1. MathHelpers Throughput
# -----------------------------------------------------------------------------
puts ">>> 1. MATH HELPERS BENCHMARKS (Vector transforms & basis generation)"
Benchmark.ips do |x|
  x.report("MathHelpers.find_perpendicular") do
    Diorite::MathHelpers.find_perpendicular(v_target)
  end

  x.report("MathHelpers.orthonormal_plane") do
    Diorite::MathHelpers.orthonormal_plane(v_up)
  end

  x.report("MathHelpers.rotate_around_axis") do
    Diorite::MathHelpers.rotate_around_axis(v_fwd, v_up, 0.785_f32)
  end
end
puts ""

# -----------------------------------------------------------------------------
# 2. GeometryBuilder: 3D Primitives Generation
# -----------------------------------------------------------------------------
puts ">>> 2. GEOMETRY BUILDER 3D PRIMITIVES BENCHMARK"
Benchmark.ips do |x|
  x.report("3D Line") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_line(v_zero, v_target, c_red, verts_3d, cols_3d)
  end

  x.report("3D Arrow") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_arrow(v_zero, v_target, c_red, 0.3_f32, verts_3d, cols_3d)
  end

  x.report("3D Box (12 edges)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_box(v_zero, v_size, c_green, verts_3d, cols_3d)
  end

  x.report("3D Sphere (16 rings)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_sphere(v_zero, 2.0_f32, 16, c_blue, verts_3d, cols_3d)
  end

  x.report("3D Cylinder (24 segs)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_cylinder(v_zero, 1.5_f32, 4.0_f32, 24, c_green, verts_3d, cols_3d)
  end

  x.report("3D Capsule (24 segs)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_capsule(v_zero, 1.0_f32, 3.0_f32, 24, c_red, verts_3d, cols_3d)
  end

  x.report("3D Vision Cone (24 segs)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_vision_cone(v_zero, v_fwd, 60.0_f32, 15.0_f32, 24, c_blue, verts_3d, cols_3d)
  end

  x.report("3D Grid (10x10 subs)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_grid(v_zero, Godot::Vector2.new(20, 20), 10, c_green, verts_3d, cols_3d)
  end

  x.report("3D Gizmo") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_gizmo(v_zero, basis_ident, 2.0_f32, verts_3d, cols_3d)
  end

  x.report("3D Camera Frustum") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_camera_frustum(v_zero, basis_ident, 60.0_f32, 0.1_f32, 50.0_f32, 1.777_f32, c_red, verts_3d, cols_3d)
  end

  x.report("3D Spring (8 coils)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_spring(v_zero, v_target, 0.6_f32, 8, 24, c_blue, verts_3d, cols_3d)
  end

  x.report("3D Ruler (20 ticks)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_ruler(v_zero, v_target, 0.25_f32, c_green, verts_3d, cols_3d)
  end

  x.report("3D Ray Hit & Reflection") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_ray_hit(v_zero, Godot::Vector3.new(0, 5, 0), v_up, c_red, verts_3d, cols_3d)
  end

  x.report("3D Trajectory Arc (20 steps)") do
    verts_3d.clear; cols_3d.clear
    Diorite::GeometryBuilder.build_trajectory_arc(v_zero, Godot::Vector3.new(10, 10, 0), Godot::Vector3.new(0, -9.8, 0), 2.0_f32, 20, c_green, verts_3d, cols_3d)
  end
end
puts ""

# -----------------------------------------------------------------------------
# 3. GeometryBuilder: 2D Primitives Generation
# -----------------------------------------------------------------------------
puts ">>> 3. GEOMETRY BUILDER 2D PRIMITIVES BENCHMARK"
Benchmark.ips do |x|
  x.report("2D Line") do
    verts_2d.clear; cols_2d.clear
    Diorite::GeometryBuilder.build_line_2d(v2_zero, v2_target, c_red, verts_2d, cols_2d)
  end

  x.report("2D Arrow") do
    verts_2d.clear; cols_2d.clear
    Diorite::GeometryBuilder.build_arrow_2d(v2_zero, v2_target, 12.0_f32, c_green, verts_2d, cols_2d)
  end

  x.report("2D Rect") do
    verts_2d.clear; cols_2d.clear
    Diorite::GeometryBuilder.build_rect_2d(rect_demo, c_blue, verts_2d, cols_2d)
  end

  x.report("2D Circle (24 segs)") do
    verts_2d.clear; cols_2d.clear
    Diorite::GeometryBuilder.build_circle_2d(v2_target, 50.0_f32, 24, c_red, verts_2d, cols_2d)
  end

  x.report("2D Points (20 pts)") do
    verts_2d.clear; cols_2d.clear
    Diorite::GeometryBuilder.build_points_2d(path_pts_2d, 4.0_f32, c_green, verts_2d, cols_2d)
  end

  x.report("2D Path (20 segments)") do
    verts_2d.clear; cols_2d.clear
    Diorite::GeometryBuilder.build_path_2d(path_pts_2d, c_blue, verts_2d, cols_2d)
  end
end
puts ""

# -----------------------------------------------------------------------------
# 4. DebugCommandQueue: Enqueue, Step, Decay & Flush
# -----------------------------------------------------------------------------
puts ">>> 4. COMMAND QUEUE THROUGHPUT (10,000 items batch processing)"
Benchmark.bm do |x|
  x.report("Push 10,000 3D Commands") do
    Diorite::DebugDraw.clear
    10_000.times do
      cmd = Diorite::Command3D.new(Diorite::ShapeKind3D::Line, c_red, 2.5)
      cmd.v0 = v_zero
      cmd.v1 = v_target
      Diorite::DebugDraw.queue.push_3d(cmd)
    end
  end

  x.report("Step & Decay 10,000 Commands") do
    Diorite::DebugDraw.queue.step_and_clean(0.016)
  end

  x.report("Clear 10,000 Commands") do
    Diorite::DebugDraw.queue.clear_all
  end
end
puts ""

# -----------------------------------------------------------------------------
# 5. TelemetryGraph Ring Buffer Performance
# -----------------------------------------------------------------------------
puts ">>> 5. TELEMETRY GRAPH BENCHMARK (Ring buffer ingestion & geometry)"
graph = Diorite::TelemetryGraph.new("Velocity", rect_demo, 0.0_f32, 100.0_f32, c_green, max_samples: 120)

Benchmark.ips do |x|
  x.report("TelemetryGraph#add_sample") do
    graph.add_sample(42.5_f32)
  end

  x.report("TelemetryGraph#build_geometry") do
    verts_2d.clear; cols_2d.clear
    graph.build_geometry(verts_2d, cols_2d)
  end
end
puts ""

# -----------------------------------------------------------------------------
# 6. Full-Frame Simulation (Mixed Heavy Frame)
# -----------------------------------------------------------------------------
puts ">>> 6. FULL-FRAME HEAVY WORKLOAD SIMULATION"
puts "Simulating a frame drawing 500 mixed 3D shapes + 200 2D shapes + text labels..."

Benchmark.ips do |x|
  x.report("Heavy Frame (700 primitives)") do
    Diorite::DebugDraw.clear
    500.times do |i|
      Diorite::DebugDraw.line_3d(v_zero, v_target, c_red)
    end
    200.times do |i|
      Diorite::DebugDraw.circle_2d(v2_target, 20.0_f32, c_blue)
    end
    Diorite::DebugDraw.text_3d(v_target, "Unit Benchmark", c_green)
    Diorite::DebugDraw.text_2d(v2_zero, "Frame Time: 16ms", c_red)
  end
end

puts ""
puts "========================================================================"
puts "  ALL BENCHMARKS COMPLETED SUCCESSFULLY!                                "
puts "========================================================================"
