require "./spec_helper"

private C_RED     = Godot::Color.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32)
private C_GREEN   = Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32)
private C_BLUE    = Godot::Color.new(0.0_f32, 0.5_f32, 1.0_f32, 1.0_f32)
private C_YELLOW  = Godot::Color.new(1.0_f32, 1.0_f32, 0.0_f32, 1.0_f32)
private C_CYAN    = Godot::Color.new(0.0_f32, 1.0_f32, 1.0_f32, 1.0_f32)
private C_MAGENTA = Godot::Color.new(1.0_f32, 0.0_f32, 1.0_f32, 1.0_f32)
private C_WHITE   = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32)
private C_ORANGE  = Godot::Color.new(1.0_f32, 0.5_f32, 0.0_f32, 1.0_f32)
private C_GRAY    = Godot::Color.new(0.5_f32, 0.5_f32, 0.5_f32, 1.0_f32)

describe Diorite::ArenaVertexBuffer do
  before_each do
    Lapis::Core::FrameArena.current.tick!
  end

  it "allocates a zero-allocation vertex buffer from Lapis::Core::FrameArena" do
    arena = Lapis::Core::FrameArena.current
    arena.tick!
    initial_used = arena.bytes_used

    buf = Diorite::ArenaVertexBuffer(Godot::Vector3).from_arena(arena, 64)
    buf.capacity.should eq(64)
    buf.size.should eq(0)
    buf.empty?.should be_true
    buf.full?.should be_false
    arena.bytes_used.should be > initial_used
  end

  it "shares size counter across pass-by-value copies" do
    arena = Lapis::Core::FrameArena.current
    buf = Diorite::ArenaVertexBuffer(Godot::Vector3).from_arena(arena, 32)

    # Pass by value to GeometryBuilder
    Diorite::GeometryBuilder.build_line(
      Godot::Vector3.new(0, 0, 0),
      Godot::Vector3.new(10, 20, 30),
      C_RED,
      buf,
      Diorite::ArenaVertexBuffer(Godot::Color).from_arena(arena, 32)
    )

    # Original struct instance sees the updated size
    buf.size.should eq(2)
    buf[0].x.should eq(0.0)
    buf[1].x.should eq(10.0)
    buf[1].y.should eq(20.0)
    buf[1].z.should eq(30.0)
  end

  it "pushes line pairs and exposes active slices and ArenaBuffers" do
    arena = Lapis::Core::FrameArena.current
    buf = Diorite::ArenaVertexBuffer(Godot::Vector2).from_arena(arena, 8)

    p1 = Godot::Vector2.new(1.0_f32, 2.0_f32)
    p2 = Godot::Vector2.new(3.0_f32, 4.0_f32)
    buf.push_line(p1, p2).should be_true
    buf.size.should eq(2)

    slice = buf.to_slice
    slice.size.should eq(2)
    slice[0].should eq(p1)
    slice[1].should eq(p2)

    arena_buf = buf.to_arena_buffer
    arena_buf.size.should eq(2)
    arena_buf[0].should eq(p1)
    arena_buf[1].should eq(p2)

    buf.clear
    buf.size.should eq(0)
    buf.empty?.should be_true
  end

  it "enforces capacity limits safely without overflowing" do
    arena = Lapis::Core::FrameArena.current
    buf = Diorite::ArenaVertexBuffer(Godot::Vector3).from_arena(arena, 2)

    v = Godot::Vector3.new(1, 1, 1)
    buf.push(v).should be_true
    buf.push(v).should be_true
    buf.full?.should be_true
    buf.push(v).should be_false
    buf.size.should eq(2)
  end
end

describe Diorite::FrameLineBatch3D do
  before_each do
    Lapis::Core::FrameArena.current.tick!
  end

  it "accumulates 3D primitives via GeometryBuilder into FrameArena buffers" do
    batch = Diorite::FrameLineBatch3D.from_arena(Lapis::Core::FrameArena.current, 1024)
    batch.empty?.should be_true

    Diorite::GeometryBuilder.build_box(
      Godot::Vector3.new(0, 0, 0),
      Godot::Vector3.new(2, 2, 2),
      C_CYAN,
      batch.verts,
      batch.cols
    )

    # Box has 12 edges = 24 vertices
    batch.vertex_count.should eq(24)
    batch.line_count.should eq(12)
    batch.vertices.size.should eq(24)
    batch.colors.size.should eq(24)

    Diorite::GeometryBuilder.build_sphere(
      Godot::Vector3.new(5, 5, 5),
      1.0_f32,
      8,
      C_YELLOW,
      batch.verts,
      batch.cols
    )

    # Sphere with 8 rings = 3 rings * 8 * 2 = 48 vertices (total 72)
    batch.vertex_count.should eq(72)
    batch.line_count.should eq(36)
  end

  it "supports direct push_line and push_vertex" do
    batch = Diorite::FrameLineBatch3D.from_arena(Lapis::Core::FrameArena.current, 16)
    batch.push_line(
      Godot::Vector3.new(0, 0, 0),
      Godot::Vector3.new(1, 2, 3),
      C_GREEN
    ).should be_true

    batch.vertex_count.should eq(2)
    batch.line_count.should eq(1)
    batch.vertices[1].z.should eq(3.0)
    batch.colors[0].should eq(C_GREEN)
  end
end

describe Diorite::FrameLineBatch2D do
  before_each do
    Lapis::Core::FrameArena.current.tick!
  end

  it "accumulates 2D primitives and charts into FrameArena buffers" do
    batch = Diorite::FrameLineBatch2D.from_arena(Lapis::Core::FrameArena.current, 2048)

    Diorite::GeometryBuilder.build_rect_2d(
      Godot::Rect2.new(10.0_f32, 20.0_f32, 100.0_f32, 50.0_f32),
      C_CYAN,
      batch.verts,
      batch.cols
    )
    batch.vertex_count.should eq(8)

    bars = [
      Diorite::BarData.new("A", 10.0_f32, C_RED),
      Diorite::BarData.new("B", 20.0_f32, C_GREEN),
      Diorite::BarData.new("C", 30.0_f32, C_BLUE),
    ]
    Diorite::ChartBuilder.build_bar_chart_2d(
      Godot::Rect2.new(0.0_f32, 0.0_f32, 120.0_f32, 60.0_f32),
      bars,
      false,
      batch.verts,
      batch.cols
    )
    batch.vertex_count.should be > 8
    batch.vertices.size.should eq(batch.colors.size)
  end

  it "renders TelemetryGraph directly into FrameLineBatch2D" do
    graph = Diorite::TelemetryGraph.new(
      "FPS",
      Godot::Rect2.new(10.0_f32, 10.0_f32, 200.0_f32, 80.0_f32),
      0.0_f32,
      120.0_f32,
      C_GREEN,
      32
    )
    graph.add_sample(60.0_f32)
    graph.add_sample(62.0_f32)
    graph.add_sample(59.0_f32)

    batch = Diorite::FrameLineBatch2D.from_arena(Lapis::Core::FrameArena.current, 512)
    graph.build_geometry(batch.verts, batch.cols)

    batch.vertex_count.should be > 8
    batch.vertices.size.should eq(batch.colors.size)
  end
end

describe Diorite::FrameDrawBuffers do
  before_each do
    Diorite::DebugDraw.clear
    Diorite::DebugDraw.enabled = true
    Lapis::Core::FrameArena.current.tick!
  end

  it "compiles a full DebugCommandQueue into on-top 3D, depth 3D, and 2D arena batches" do
    # 3D on-top commands (on_top = true default)
    Diorite::DebugDraw.line_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 1, 1), C_RED)
    Diorite::DebugDraw.box_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 2, 2), C_GREEN)
    Diorite::DebugDraw.line_path_3d([Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 0, 0), Godot::Vector3.new(2, 1, 0)], C_BLUE)

    # 3D depth-tested commands (on_top = false)
    Diorite::DebugDraw.sphere_3d(Godot::Vector3.new(0, 2, 0), 1.5_f32, C_YELLOW, 8, 0.0, false)

    # 2D commands
    Diorite::DebugDraw.line_2d(Godot::Vector2.new(0, 0), Godot::Vector2.new(50, 50), C_WHITE)
    Diorite::DebugDraw.rect_2d(Godot::Rect2.new(10.0_f32, 10.0_f32, 40.0_f32, 20.0_f32), C_CYAN)
    Diorite::DebugDraw.path_2d([Godot::Vector2.new(0, 0), Godot::Vector2.new(10, 10), Godot::Vector2.new(20, 5)], C_ORANGE)
    Diorite::DebugDraw.stat_graph_2d("frame_ms", 8.3_f32)
    Diorite::DebugDraw.stat_graph_2d("frame_ms", 8.1_f32)

    buffers = Diorite::DebugDraw.build_frame_batches(
      Lapis::Core::FrameArena.current,
      cap_3d_on_top: 4096,
      cap_3d_depth: 4096,
      cap_2d: 4096
    )

    # 3D on-top: line (2) + box (24) + path of 3 points (4) = 30 vertices
    buffers.batch_3d_on_top.vertex_count.should eq(30)
    buffers.batch_3d_on_top.line_count.should eq(15)

    # 3D depth: sphere with 8 segments = 48 vertices
    buffers.batch_3d_depth.vertex_count.should eq(48)

    # 2D: line (2) + rect (8) + path (4) + telemetry graph (>8)
    buffers.batch_2d.vertex_count.should be > 14
    buffers.total_vertex_count.should eq(
      buffers.batch_3d_on_top.vertex_count +
      buffers.batch_3d_depth.vertex_count +
      buffers.batch_2d.vertex_count
    )
  end

  it "allocates single-frame path_3d and path_2d slices directly in Lapis::Core::FrameArena" do
    arena = Lapis::Core::FrameArena.current
    arena.tick!
    before_bytes = arena.bytes_used

    pts3 = {Godot::Vector3.new(1, 2, 3), Godot::Vector3.new(4, 5, 6), Godot::Vector3.new(7, 8, 9)}
    Diorite::DebugDraw.line_path_3d(pts3, C_CYAN, 0.0)

    pts2 = {Godot::Vector2.new(10, 20), Godot::Vector2.new(30, 40)}
    Diorite::DebugDraw.line_path_2d(pts2, C_MAGENTA, 0.0)

    # Arena bytes were advanced for both slices
    arena.bytes_used.should be > before_bytes

    cmd3 = Diorite::DebugDraw.queue.commands_3d.last
    cmd3.path_slice.size.should eq(3)
    cmd3.path.should be_nil

    cmd2 = Diorite::DebugDraw.queue.commands_2d.last
    cmd2.points_slice.size.should eq(2)
    cmd2.points.should be_nil
  end
end

describe "Diorite Two-Tier Declarative FrameBatch DSL" do
  before_each do
    Lapis::Core::FrameArena.current.tick!
  end

  it "supports Diorite.frame and Diorite.scoped_frame declarative builders" do
    arena = Lapis::Core::FrameArena.current
    arena.tick!
    mark = arena.mark

    Diorite.scoped_frame(arena, cap_3d_on_top: 2048, cap_3d_depth: 2048, cap_2d: 2048) do |ctx|
      ctx.draw_3d(on_top: true) do |b3|
        b3.line(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 0, 0), C_RED)
        b3.box(Godot::Vector3.new(0, 1, 0), Godot::Vector3.new(1, 1, 1), C_GREEN)
        b3.gizmo(Godot::Vector3.new(0, 0, 0), Godot::Basis.new, 2.0_f32)
      end

      ctx.draw_3d(on_top: false) do |b3|
        b3.sphere(Godot::Vector3.new(0, 0, 0), 1.0_f32, C_BLUE, 8)
      end

      ctx.draw_2d do |b2|
        b2.line(Godot::Vector2.new(0, 0), Godot::Vector2.new(10, 10), C_WHITE)
        b2.rect(Godot::Rect2.new(5.0_f32, 5.0_f32, 20.0_f32, 20.0_f32), C_CYAN)
      end

      # line (2) + box (24) + gizmo (3 arrows * 18 = 54) = 80
      ctx.buffers.batch_3d_on_top.vertex_count.should eq(2 + 24 + 54)
      ctx.buffers.batch_3d_depth.vertex_count.should eq(48)
      ctx.buffers.batch_2d.vertex_count.should eq(2 + 8)
    end

    # Scoped frame restores the arena offset on exit
    arena.bytes_used.should eq(mark)
  end

  it "supports DebugDraw.batch_3d and DebugDraw.batch_2d ergonomics" do
    b3 = Diorite::DebugDraw.batch_3d(max_vertices: 512) do |draw|
      draw.arrow(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 5, 0), C_YELLOW)
      draw.grid(Godot::Vector3.new(0, 0, 0), Godot::Vector2.new(10.0_f32, 10.0_f32), 4, C_GRAY)
    end
    b3.vertex_count.should be > 10

    b2 = Diorite::DebugDraw.batch_2d(max_vertices: 512) do |draw|
      draw.circle(Godot::Vector2.new(100, 100), 25.0_f32, C_GREEN, 16)
      draw.arc(Godot::Vector2.new(100, 100), 30.0_f32, 0.0_f32, Math::PI.to_f32, 8, C_CYAN)
    end
    b2.vertex_count.should eq(16 * 2 + 8 * 2)
  end

  it "executes 1,000 full 2D/3D immediate-mode frame batches with zero GC heap allocations" do
    arena = Lapis::Core::FrameArena.new(4 * 1024 * 1024)
    rect = Godot::Rect2.new(10.0_f32, 10.0_f32, 50.0_f32, 50.0_f32)

    # Warm-up pass
    arena.frame do |a|
      Diorite.frame(a, cap_3d_on_top: 1024, cap_3d_depth: 512, cap_2d: 1024) do |ctx|
        ctx.box(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 1, 1), C_CYAN)
        ctx.sphere(Godot::Vector3.new(2, 2, 2), 1.0_f32, C_RED, 8)
        ctx.arrow(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 3, 0), C_YELLOW)
        ctx.rect_2d(rect, C_GREEN)
        ctx.circle_2d(Godot::Vector2.new(50, 50), 20.0_f32, C_MAGENTA, 12)
      end
    end

    GC.collect
    bytes_before = GC.stats.total_bytes

    1000.times do
      arena.frame do |a|
        Diorite.frame(a, cap_3d_on_top: 1024, cap_3d_depth: 512, cap_2d: 1024) do |ctx|
          ctx.box(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 1, 1), C_CYAN)
          ctx.sphere(Godot::Vector3.new(2, 2, 2), 1.0_f32, C_RED, 8)
          ctx.arrow(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 3, 0), C_YELLOW)
          ctx.rect_2d(rect, C_GREEN)
          ctx.circle_2d(Godot::Vector2.new(50, 50), 20.0_f32, C_MAGENTA, 12)
        end
      end
    end

    bytes_after = GC.stats.total_bytes
    (bytes_after - bytes_before).should eq(0)
    arena.stats.frame_count.should be >= 1000
    arena.bytes_used.should eq(0)
  end
end
