require "./spec_helper"

describe Diorite::GeometryBuilder do
  it "builds a simple line" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1.0, 0.0, 0.0, 1.0)
    p0 = Godot::Vector3.new(0, 0, 0)
    p1 = Godot::Vector3.new(0, 1, 0)

    Diorite::GeometryBuilder.build_line(p0, p1, color, verts, cols)
    verts.size.should eq(2)
    cols.size.should eq(2)
    verts[0].should eq(p0)
    verts[1].should eq(p1)
  end

  it "builds an arrow with shaft and fins" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0.0, 1.0, 0.0, 1.0)
    from = Godot::Vector3.new(0, 0, 0)
    to = Godot::Vector3.new(0, 2, 0)

    Diorite::GeometryBuilder.build_arrow(from, to, color, 0.3_f32, verts, cols)
    # 1 shaft line (2 verts) + 4 fins * 2 lines (16 verts) = 18 verts
    verts.size.should eq(18)
    cols.size.should eq(18)
  end

  it "builds a line path" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 1, 1, 1)
    pts = [
      Godot::Vector3.new(0, 0, 0),
      Godot::Vector3.new(1, 1, 0),
      Godot::Vector3.new(2, 0, 0),
      Godot::Vector3.new(3, 1, 0)
    ]

    Diorite::GeometryBuilder.build_line_path(pts, color, verts, cols)
    # 3 segments = 6 verts
    verts.size.should eq(6)
  end

  it "builds a 3D box with 12 wireframe edges (24 vertices)" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 0, 0, 1)

    Diorite::GeometryBuilder.build_box(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 2, 2), color, verts, cols)
    # 12 edges * 2 vertices = 24 vertices
    verts.size.should eq(24)
    cols.size.should eq(24)
  end

  it "builds a 3D sphere with 3 orthogonal rings" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0, 1, 0, 1)

    Diorite::GeometryBuilder.build_sphere(Godot::Vector3.new(0, 0, 0), 1.0_f32, 16, color, verts, cols)
    # 3 rings * 16 segments * 2 vertices = 96 vertices
    verts.size.should eq(96)
  end

  it "builds a cylinder with top, bottom, and vertical ribs" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0, 0, 1, 1)

    Diorite::GeometryBuilder.build_cylinder(Godot::Vector3.new(0, 0, 0), 1.0_f32, 2.0_f32, 16, color, verts, cols)
    # 2 rings * 16 segments * 2 verts = 64 verts + 4 ribs * 2 verts = 72 verts
    verts.size.should eq(72)
  end

  it "builds a capsule" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 1, 0, 1)

    Diorite::GeometryBuilder.build_capsule(Godot::Vector3.new(0, 0, 0), 0.5_f32, 2.0_f32, 16, color, verts, cols)
    verts.size.should be > 40
  end

  it "builds a plane with border, diagonal cross, and normal arrow" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0.5, 0.5, 0.5, 1)

    Diorite::GeometryBuilder.build_plane(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0), Godot::Vector2.new(4, 4), color, verts, cols)
    # 4 border lines (8) + 2 diagonals (4) + arrow (18) = 30 verts
    verts.size.should eq(30)
  end

  it "builds a 3D position marker (3 crossing axes)" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 1, 1, 1)

    Diorite::GeometryBuilder.build_position_3d(Godot::Vector3.new(1, 2, 3), 1.0_f32, color, verts, cols)
    # 3 lines = 6 verts
    verts.size.should eq(6)
  end

  it "builds an RGB coordinate gizmo" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color

    Diorite::GeometryBuilder.build_gizmo(Godot::Vector3.new(0, 0, 0), Godot::Basis.new, 1.0_f32, verts, cols)
    # 3 arrows * 18 verts = 54 verts
    verts.size.should eq(54)
    # Verify RGB colors exist
    cols.any? { |c| c.r > 0.8_f32 && c.g < 0.3_f32 }.should be_true # Red (X)
    cols.any? { |c| c.g > 0.8_f32 && c.r < 0.3_f32 }.should be_true # Green (Y)
    cols.any? { |c| c.b > 0.8_f32 && c.r < 0.3_f32 }.should be_true # Blue (Z)
  end

  it "builds a grid" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0.5, 0.5, 0.5, 1)

    Diorite::GeometryBuilder.build_grid(Godot::Vector3.new(0, 0, 0), Godot::Vector2.new(10, 10), 10, color, verts, cols)
    # 11 lines X (22 verts) + 11 lines Z (22 verts) = 44 verts
    verts.size.should eq(44)
  end

  it "builds a camera frustum" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 1, 1, 1)

    Diorite::GeometryBuilder.build_camera_frustum(Godot::Vector3.new(0, 0, 0), Godot::Basis.new, 60.0_f32, 0.1_f32, 10.0_f32, 1.777_f32, color, verts, cols)
    # Near quad (8) + Far quad (8) + 4 edges (8) = 24 verts
    verts.size.should eq(24)
  end

  it "builds innovative item: raycast hit with incident line, normal arrow, and impact ring" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 0.8, 0, 1)

    Diorite::GeometryBuilder.build_ray_hit(Godot::Vector3.new(0, 5, 0), Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0), color, verts, cols)
    # Incident ray (2) + normal arrow (18) + impact ring (32) = 52 verts
    verts.size.should eq(52)
  end

  it "builds innovative item: trajectory arc and impact ring" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0, 1, 0, 1)

    Diorite::GeometryBuilder.build_trajectory_arc(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(5, 5, 0), Godot::Vector3.new(0, -9.8, 0), 1.0_f32, 20, color, verts, cols)
    # 20 arc steps * 2 (40 verts) + 16-segment impact ring * 2 (32 verts) = 72 verts
    verts.size.should eq(72)
  end

  it "builds innovative item: vision cone" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(0, 1, 1, 1)

    Diorite::GeometryBuilder.build_vision_cone(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 0, 1), 45.0_f32, 10.0_f32, 16, color, verts, cols)
    # Perimeter ring (32) + 4 boundary rays (8) + center bore (2) = 42 verts
    verts.size.should eq(42)
  end

  it "builds innovative item: oriented bounding box (OBB)" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 0, 1, 1)

    Diorite::GeometryBuilder.build_obb(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 3, 4), Godot::Basis.new, color, verts, cols)
    # 12 edges * 2 = 24 verts
    verts.size.should eq(24)
  end

  it "builds innovative item: helical spring" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 1, 0, 1)

    Diorite::GeometryBuilder.build_spring(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 5, 0), 0.3_f32, 5, 10, color, verts, cols)
    verts.size.should be > 50
  end

  it "builds innovative item: distance measurement ruler" do
    verts = [] of Godot::Vector3
    cols = [] of Godot::Color
    color = Godot::Color.new(1, 1, 1, 1)

    Diorite::GeometryBuilder.build_ruler(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(5, 0, 0), 0.2_f32, color, verts, cols)
    # Main line (2) + 2 end caps (4) + 4 intermediate ticks (8) = 14 verts
    verts.size.should eq(14)
  end

  it "builds 2D primitives (line, arrow, rect, circle)" do
    verts = [] of Godot::Vector2
    cols = [] of Godot::Color
    col = Godot::Color.new(1, 1, 1, 1)

    # Line
    Diorite::GeometryBuilder.build_line_2d(Godot::Vector2.new(0, 0), Godot::Vector2.new(10, 10), col, verts, cols)
    verts.size.should eq(2)

    # Arrow
    verts.clear; cols.clear
    Diorite::GeometryBuilder.build_arrow_2d(Godot::Vector2.new(0, 0), Godot::Vector2.new(50, 0), 10.0_f32, col, verts, cols)
    verts.size.should eq(6) # line (2) + 2 fin lines (4) = 6

    # Rect
    verts.clear; cols.clear
    Diorite::GeometryBuilder.build_rect_2d(Godot::Rect2.new(0, 0, 20, 20), col, verts, cols)
    verts.size.should eq(8) # 4 sides * 2 = 8

    # Circle
    verts.clear; cols.clear
    Diorite::GeometryBuilder.build_circle_2d(Godot::Vector2.new(50, 50), 20.0_f32, 16, col, verts, cols)
    verts.size.should eq(32) # 16 segments * 2 = 32
  end
end
