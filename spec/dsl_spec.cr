require "./spec_helper"

describe Diorite::DebugDraw do
  before_each do
    Diorite::DebugDraw.clear
  end

  it "enqueues 3D primitives through DebugDraw procedural API" do
    c = Godot::Color.new(1, 0, 0, 1)

    Diorite::DebugDraw.line_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 1, 1), c, 1.5_f32)
    Diorite::DebugDraw.arrow_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 2, 0), c, 0.3_f32, 2.0_f32)
    Diorite::DebugDraw.box_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 2, 2), c)
    Diorite::DebugDraw.sphere_3d(Godot::Vector3.new(0, 0, 0), 1.5_f32, c, 16)
    Diorite::DebugDraw.cylinder_3d(Godot::Vector3.new(0, 0, 0), 1.0_f32, 3.0_f32, c)
    Diorite::DebugDraw.capsule_3d(Godot::Vector3.new(0, 0, 0), 0.5_f32, 2.0_f32, c)
    Diorite::DebugDraw.vision_cone_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 0, 1), 60.0_f32, 10.0_f32, c, 16)
    Diorite::DebugDraw.plane_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0), Godot::Vector2.new(5, 5), c)
    Diorite::DebugDraw.grid_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector2.new(10, 10), 10, c)
    Diorite::DebugDraw.position_3d(Godot::Vector3.new(0, 0, 0), 2.0_f32)
    Diorite::DebugDraw.gizmo_3d(Godot::Vector3.new(0, 0, 0), Godot::Basis.new, 1.5_f32)
    Diorite::DebugDraw.camera_frustum_3d(Godot::Vector3.new(0, 0, 0), Godot::Basis.new, 60.0_f32, 0.1_f32, 50.0_f32, 1.777_f32, c)
    Diorite::DebugDraw.points_3d([Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 1, 1)], 0.1_f32, c)
    Diorite::DebugDraw.line_path_3d([Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(1, 0, 1), Godot::Vector3.new(2, 0, 0)], c)
    Diorite::DebugDraw.spring_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 5, 0), 0.5_f32, 10, 32, c)
    Diorite::DebugDraw.ruler_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 2, 2), 0.5_f32, c)
    Diorite::DebugDraw.billboard_square_3d(Godot::Vector3.new(0, 1, 0), 1.0_f32, Godot::Vector3.new(0, 1, 5), c)
    Diorite::DebugDraw.ray_hit_3d(Godot::Vector3.new(0, 5, 0), Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0), c)
    Diorite::DebugDraw.trajectory_arc_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(5, 5, 0), Godot::Vector3.new(0, -9.8, 0), 2.0_f32, 20, c)
    Diorite::DebugDraw.obb_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(2, 2, 2), Godot::Basis.new, c)
    Diorite::DebugDraw.reticle_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0), 0.5_f32, c)
    Diorite::DebugDraw.surface_disk_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0), 1.0_f32, 24, c)
    Diorite::DebugDraw.trail_3d("entity_1", Godot::Vector3.new(0, 1, 2), 20, c)
    Diorite::DebugDraw.text_3d(Godot::Vector3.new(0, 3, 0), "Boss HP: 100", c, 3.0_f32)

    Diorite::DebugDraw.queue.commands_3d.size.should be >= 20
    Diorite::DebugDraw.queue.text_3d.size.should eq(2) # 1 from ruler_3d distance readout + 1 from text_3d

    # Validate duration assignment
    first_cmd = Diorite::DebugDraw.queue.commands_3d.first
    first_cmd.duration.should eq(1.5_f32)
    first_cmd.kind.should eq(Diorite::ShapeKind3D::Line)
  end

  it "enqueues 2D primitives through DebugDraw procedural API" do
    c = Godot::Color.new(0, 1, 0, 1)

    Diorite::DebugDraw.line_2d(Godot::Vector2.new(10, 10), Godot::Vector2.new(100, 100), c, 0.5_f32)
    Diorite::DebugDraw.arrow_2d(Godot::Vector2.new(10, 10), Godot::Vector2.new(50, 50), c, 12.0_f32)
    Diorite::DebugDraw.rect_2d(Godot::Rect2.new(20, 20, 80, 60), c)
    Diorite::DebugDraw.circle_2d(Godot::Vector2.new(150, 150), 40.0_f32, c, 32)
    Diorite::DebugDraw.points_2d([Godot::Vector2.new(0, 0), Godot::Vector2.new(50, 50)], 5.0_f32, c)
    Diorite::DebugDraw.path_2d([Godot::Vector2.new(0, 0), Godot::Vector2.new(100, 50), Godot::Vector2.new(200, 0)], c)
    Diorite::DebugDraw.text_2d(Godot::Vector2.new(16, 16), "FPS: 60", c, 1.0_f32)

    Diorite::DebugDraw.queue.commands_2d.size.should eq(6)
    Diorite::DebugDraw.queue.text_2d.size.should eq(1)
  end

  it "supports frame block syntax with clean delegation" do
    Diorite::DebugDraw.frame do |d|
      d.line_3d(Godot::Vector3.new(0, 0, 0), Godot::Vector3.new(0, 1, 0))
      d.sphere_3d(Godot::Vector3.new(0, 1, 0), 0.5_f32)
      d.circle_2d(Godot::Vector2.new(200, 200), 25.0_f32)
    end

    Diorite::DebugDraw.queue.commands_3d.size.should eq(2)
    Diorite::DebugDraw.queue.commands_2d.size.should eq(1)
  end
end
