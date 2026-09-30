require "./spec_helper"

describe Diorite::DebugCommandQueue do
  it "pushes and consumes single-frame 3D and 2D commands" do
    queue = Diorite::DebugCommandQueue.new

    cmd3d = Diorite::Command3D.new(Diorite::ShapeKind3D::Line, duration: 0.0)
    cmd2d = Diorite::Command2D.new(Diorite::ShapeKind2D::Circle, duration: 0.0)

    queue.push_3d(cmd3d)
    queue.push_2d(cmd2d)

    queue.commands_3d.size.should eq(1)
    queue.commands_2d.size.should eq(1)

    # After step, single-frame commands (duration == 0.0) are cleared
    queue.step_and_clean(0.016)
    queue.commands_3d.size.should eq(0)
    queue.commands_2d.size.should eq(0)
  end

  it "persists duration-based commands until expiration" do
    queue = Diorite::DebugCommandQueue.new

    cmd = Diorite::Command3D.new(Diorite::ShapeKind3D::Box, duration: 1.0)
    queue.push_3d(cmd)

    # Step half a second
    queue.step_and_clean(0.5)
    queue.commands_3d.size.should eq(1)
    cmd.remaining_time.should be_close(0.5, 0.01)

    # Step another 0.6 seconds -> expired
    queue.step_and_clean(0.6)
    queue.commands_3d.size.should eq(0)
  end

  it "correctly manages motion trail FIFO point buffer" do
    queue = Diorite::DebugCommandQueue.new

    (1..5).each do |i|
      queue.update_trail("player", Godot::Vector3.new(i.to_f32, 0, 0), max_pts: 3)
    end

    pts = queue.trails["player"]
    pts.size.should eq(3)
    # The oldest points (1, 2) should be evicted; remaining are (3, 4, 5)
    pts[0].x.should eq(3.0_f32)
    pts[1].x.should eq(4.0_f32)
    pts[2].x.should eq(5.0_f32)
  end
end
