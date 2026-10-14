require "benchmark"
require "lapis"
require "../src/diorite/core/math_helpers"
require "../src/diorite/core/telemetry_graph"
require "../src/diorite/core/geometry_builder"
require "../src/diorite/core/chart_builder"
require "../src/diorite/core/debug_command"
require "../src/diorite/core/frame_arena_batch"
require "../src/diorite/core/dsl"

puts "========================================================================"
puts "  DIORITE x LAPIS::CORE::FRAMEARENA 2D/3D BATCH BENCHMARK.IPS SUITE     "
puts "========================================================================"
puts "Crystal Version: #{Crystal::VERSION}"
puts "Target Platform: #{Crystal::DESCRIPTION}"
puts "Arena Capacity:  4 MiB (Lapis::Core::FrameArena)"
puts "========================================================================"
puts ""

bench_arena = Lapis::Core::FrameArena.new(4 * 1024 * 1024)

v_zero   = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
v_target = Godot::Vector3.new(10.0_f32, 15.0_f32, 20.0_f32)
v_size   = Godot::Vector3.new(2.0_f32, 4.0_f32, 2.0_f32)

v2_zero   = Godot::Vector2.new(0.0_f32, 0.0_f32)
v2_target = Godot::Vector2.new(300.0_f32, 200.0_f32)
rect_demo = Godot::Rect2.new(10.0_f32, 10.0_f32, 200.0_f32, 100.0_f32)

c_red   = Godot::Color.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32)
c_green = Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32)
c_blue  = Godot::Color.new(0.0_f32, 0.5_f32, 1.0_f32, 1.0_f32)

# Pre-populate a representative frame command queue
Diorite::DebugDraw.clear
Diorite::DebugDraw.line_3d(v_zero, v_target, c_red)
Diorite::DebugDraw.box_3d(v_zero, v_size, c_green)
Diorite::DebugDraw.sphere_3d(v_target, 2.0_f32, c_blue, 12, 0.0, true)
Diorite::DebugDraw.cylinder_3d(v_zero, 1.0_f32, 3.0_f32, c_red, 12, 0.0, false)
Diorite::DebugDraw.line_2d(v2_zero, v2_target, c_green)
Diorite::DebugDraw.rect_2d(rect_demo, c_blue)
Diorite::DebugDraw.circle_2d(v2_target, 40.0_f32, c_red, 16)

Benchmark.ips(warmup: 300.milliseconds, calculation: 1.seconds) do |x|
  x.report("FrameArena 3D Batch (Box + Sphere + Arrow)") do
    bench_arena.tick!
    batch_3d = Diorite::FrameLineBatch3D.from_arena(bench_arena, 512)
    Diorite::GeometryBuilder.build_box(v_zero, v_size, c_red, batch_3d.verts, batch_3d.cols)
    Diorite::GeometryBuilder.build_sphere(v_target, 2.0_f32, 12, c_green, batch_3d.verts, batch_3d.cols)
    Diorite::GeometryBuilder.build_arrow(v_zero, v_target, c_blue, 0.5_f32, batch_3d.verts, batch_3d.cols)
  end

  x.report("FrameArena 2D Batch (Rect + Circle + Arrow)") do
    bench_arena.tick!
    batch_2d = Diorite::FrameLineBatch2D.from_arena(bench_arena, 512)
    Diorite::GeometryBuilder.build_rect_2d(rect_demo, c_red, batch_2d.verts, batch_2d.cols)
    Diorite::GeometryBuilder.build_circle_2d(v2_target, 50.0_f32, 16, c_green, batch_2d.verts, batch_2d.cols)
    Diorite::GeometryBuilder.build_arrow_2d(v2_zero, v2_target, 12.0_f32, c_blue, batch_2d.verts, batch_2d.cols)
  end

  x.report("Diorite.frame Declarative 2D/3D Batch") do
    bench_arena.frame do |arena|
      Diorite.frame(arena, cap_3d_on_top: 512, cap_3d_depth: 256, cap_2d: 512) do |ctx|
        ctx.box(v_zero, v_size, c_red)
        ctx.arrow(v_zero, v_target, c_green)
        ctx.rect_2d(rect_demo, c_blue)
        ctx.circle_2d(v2_target, 25.0_f32, c_red, 16)
      end
    end
  end

  x.report("FrameDrawBuffers#compile_queue (Full 2D/3D Frame)") do
    bench_arena.tick!
    Diorite::DebugDraw.build_frame_batches(bench_arena, cap_3d_on_top: 1024, cap_3d_depth: 512, cap_2d: 1024)
  end
end

puts ""
puts "========================================================================"
puts "  GC HEAP ALLOCATION VERIFICATION (10,000 FRAMES)                       "
puts "========================================================================"
GC.collect
before_bytes = GC.stats.total_bytes
10_000.times do
  bench_arena.tick!
  Diorite::DebugDraw.build_frame_batches(bench_arena, cap_3d_on_top: 1024, cap_3d_depth: 512, cap_2d: 1024)
end
after_bytes = GC.stats.total_bytes
puts "  Heap bytes allocated across 10,000 frames: #{after_bytes - before_bytes} B"
puts "  Arena peak high-water mark:                #{bench_arena.peak_bytes} B"
puts "========================================================================"
