require "./spec_helper"

describe Diorite::GeometryBuilder do
  describe "3D Shape Casts and Splines" do
    it "builds sphere cast geometry with connecting rays and hit cross" do
      verts = Array(Godot::Vector3).new
      cols = Array(Godot::Color).new

      Diorite::GeometryBuilder.build_sphere_cast(
        from: Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
        to: Godot::Vector3.new(0.0_f32, 5.0_f32, 0.0_f32),
        radius: 0.5_f32,
        hit: true,
        color: Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32),
        verts: verts,
        cols: cols
      )

      # 2 spheres (12 rings * 3 orthogonal rings * 2 verts each = 72 verts each) + 4 connectors (8 verts) + 2 hit cross lines (4 verts) = 156 verts
      verts.size.should be >= 150
      verts.size.should eq(cols.size)
    end

    it "builds capsule cast and box cast geometry" do
      verts_cap = Array(Godot::Vector3).new
      cols_cap = Array(Godot::Color).new

      Diorite::GeometryBuilder.build_capsule_cast(
        from: Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
        to: Godot::Vector3.new(5.0_f32, 0.0_f32, 0.0_f32),
        radius: 0.5_f32,
        height: 1.8_f32,
        hit: false,
        color: Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32),
        verts: verts_cap,
        cols: cols_cap
      )

      verts_cap.size.should be > 100

      verts_box = Array(Godot::Vector3).new
      cols_box = Array(Godot::Color).new

      Diorite::GeometryBuilder.build_box_cast(
        from: Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
        to: Godot::Vector3.new(0.0_f32, 0.0_f32, 5.0_f32),
        size: Godot::Vector3.new(1.0_f32, 1.0_f32, 1.0_f32),
        hit: false,
        color: Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32),
        verts: verts_box,
        cols: cols_box
      )

      # 2 boxes (24 verts each) + 8 corner connector lines (16 verts) = 64 verts
      verts_box.size.should eq(64)
    end

    it "builds cubic Bézier and Catmull-Rom spline curves" do
      verts_bez = Array(Godot::Vector3).new
      cols_bez = Array(Godot::Color).new

      p0 = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      p1 = Godot::Vector3.new(1.0_f32, 3.0_f32, 0.0_f32)
      p2 = Godot::Vector3.new(3.0_f32, 3.0_f32, 0.0_f32)
      p3 = Godot::Vector3.new(4.0_f32, 0.0_f32, 0.0_f32)

      Diorite::GeometryBuilder.build_bezier_cubic(p0, p1, p2, p3, 20, Godot::Color.new(1.0_f32, 1.0_f32, 0.0_f32, 1.0_f32), verts_bez, cols_bez, show_hull: true)

      # 3 control hull segments (6 verts) + 20 curve segments (40 verts) = 46 verts
      verts_bez.size.should eq(46)

      verts_spline = Array(Godot::Vector3).new
      cols_spline = Array(Godot::Color).new
      pts = [
        Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
        Godot::Vector3.new(2.0_f32, 3.0_f32, 1.0_f32),
        Godot::Vector3.new(5.0_f32, 2.0_f32, 2.0_f32),
        Godot::Vector3.new(8.0_f32, 0.0_f32, 0.0_f32),
      ]

      Diorite::GeometryBuilder.build_catmull_rom(pts, 10, Godot::Color.new(0.0_f32, 1.0_f32, 1.0_f32, 1.0_f32), verts_spline, cols_spline)
      verts_spline.size.should be > 40
    end

    it "builds 3D cone, circle, and actor card" do
      verts_cone = Array(Godot::Vector3).new
      cols_cone = Array(Godot::Color).new

      Diorite::GeometryBuilder.build_cone_3d(
        tip: Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
        dir: Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32),
        length: 5.0_f32,
        angle_rad: 0.5_f32,
        segments: 16,
        color: Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
        verts: verts_cone,
        cols: cols_cone
      )

      verts_cone.size.should be > 30

      verts_circ = Array(Godot::Vector3).new
      cols_circ = Array(Godot::Color).new
      Diorite::GeometryBuilder.build_circle_3d(
        center: Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
        normal: Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
        radius: 2.0_f32,
        segments: 24,
        color: Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
        verts: verts_circ,
        cols: cols_circ
      )

      verts_circ.size.should eq(48)

      verts_card = Array(Godot::Vector3).new
      cols_card = Array(Godot::Color).new
      Diorite::GeometryBuilder.build_actor_card_3d(
        position: Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32),
        size: Godot::Vector2.new(1.5_f32, 1.0_f32),
        color: Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
        verts: verts_card,
        cols: cols_card
      )

      # 1 anchor pole (2 verts) + 4 box edges (8 verts) = 10 verts
      verts_card.size.should eq(10)
    end
  end

  describe "2D Spatial Helpers" do
    it "builds 2D stadium capsule, vision cone, arc, sector, and ruler" do
      verts_cap = Array(Godot::Vector2).new
      cols_cap = Array(Godot::Color).new
      Diorite::GeometryBuilder.build_capsule_2d(
        p0: Godot::Vector2.new(50.0_f32, 50.0_f32),
        p1: Godot::Vector2.new(150.0_f32, 50.0_f32),
        radius: 20.0_f32,
        color: Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
        verts: verts_cap,
        cols: cols_cap,
        segments: 12
      )
      # 2 parallel lines (4 verts) + 2 semicircles (12 segments * 2 verts * 2 caps = 48 verts) = 52 verts
      verts_cap.size.should eq(52)

      verts_cone = Array(Godot::Vector2).new
      cols_cone = Array(Godot::Color).new
      Diorite::GeometryBuilder.build_vision_cone_2d(
        origin: Godot::Vector2.new(100.0_f32, 100.0_f32),
        dir: Godot::Vector2.new(1.0_f32, 0.0_f32),
        distance: 80.0_f32,
        angle_rad: 1.047_f32, # ~60 deg
        segments: 16,
        color: Godot::Color.new(0.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
        verts: verts_cone,
        cols: cols_cone
      )
      # 16 arc segments (32 verts) + 2 boundary rays (4 verts) = 36 verts
      verts_cone.size.should eq(36)

      verts_ruler = Array(Godot::Vector2).new
      cols_ruler = Array(Godot::Color).new
      Diorite::GeometryBuilder.build_ruler_2d(
        from: Godot::Vector2.new(0.0_f32, 0.0_f32),
        to: Godot::Vector2.new(100.0_f32, 0.0_f32),
        color: Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
        verts: verts_ruler,
        cols: cols_ruler,
        tick_step: 25.0_f32,
        tick_size: 10.0_f32
      )
      # Main line (2 verts) + 2 caps (4 verts) + 3 interior ticks at 25, 50, 75 (6 verts) = 12 verts
      verts_ruler.size.should eq(12)
    end
  end
end
