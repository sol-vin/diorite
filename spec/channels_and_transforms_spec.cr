require "./spec_helper"

describe "Channels, Transforms, and Freeze Mode" do
  before_each do
    Diorite::DebugDraw.clear
    Diorite::DebugDraw.unfreeze!
  end

  it "filters and scopes commands by channel" do
    Diorite::DebugDraw.channel("ai") do |d|
      d.line_3d(Godot::Vector3.new, Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32))
      d.text_2d(Godot::Vector2.new(10.0_f32, 10.0_f32), "AI Debug")
    end

    Diorite::DebugDraw.queue.commands_3d.size.should eq(1)
    Diorite::DebugDraw.queue.commands_3d.first.channel.should eq("ai")
    Diorite::DebugDraw.queue.text_2d.first.channel.should eq("ai")

    # Disable channel
    Diorite::DebugDraw.disable_channel("ai")
    Diorite::DebugDraw.channel_enabled?("ai").should be_false

    # Re-enable channel
    Diorite::DebugDraw.enable_channel("ai")
    Diorite::DebugDraw.channel_enabled?("ai").should be_true
  end

  it "transforms 3D positions and orientations through local transform stack" do
    xform = Godot::Transform3D.new(Godot::Basis.new, Godot::Vector3.new(10.0_f32, 20.0_f32, 30.0_f32))

    Diorite::DebugDraw.with_transform(xform) do
      Diorite::DebugDraw.line_3d(Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32), Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32))
    end

    cmd = Diorite::DebugDraw.queue.commands_3d.first
    cmd.v0.should eq(Godot::Vector3.new(10.0_f32, 20.0_f32, 30.0_f32))
    cmd.v1.should eq(Godot::Vector3.new(11.0_f32, 20.0_f32, 30.0_f32))

    # Transform stack pops automatically
    Diorite::DebugDraw.current_transform.should be_nil
  end

  it "supports nested transform stacks" do
    xform1 = Godot::Transform3D.new(Godot::Basis.new, Godot::Vector3.new(10.0_f32, 0.0_f32, 0.0_f32))
    xform2 = Godot::Transform3D.new(Godot::Basis.new, Godot::Vector3.new(5.0_f32, 0.0_f32, 0.0_f32))

    Diorite::DebugDraw.with_transform(xform1) do
      Diorite::DebugDraw.with_transform(xform2) do
        Diorite::DebugDraw.line_3d(Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32), Godot::Vector3.new(2.0_f32, 0.0_f32, 0.0_f32))
      end
    end

    cmd = Diorite::DebugDraw.queue.commands_3d.first
    cmd.v0.x.should eq(15.0_f32)
    cmd.v1.x.should eq(17.0_f32)
  end

  it "pauses command decay during freeze mode" do
    Diorite::DebugDraw.line_3d(Godot::Vector3.new, Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32), duration: 2.0)

    # Freeze active
    Diorite::DebugDraw.freeze!
    Diorite::DebugDraw.frozen?.should be_true

    Diorite::DebugDraw.queue.step_and_clean(1.0)
    Diorite::DebugDraw.queue.commands_3d.first.remaining_time.should eq(2.0)

    # Unfreeze
    Diorite::DebugDraw.unfreeze!
    Diorite::DebugDraw.frozen?.should be_false

    Diorite::DebugDraw.queue.step_and_clean(0.5)
    Diorite::DebugDraw.queue.commands_3d.first.remaining_time.should eq(1.5)
  end

  it "toggles master enabled switch" do
    Diorite::DebugDraw.enabled = false
    Diorite::DebugDraw.enabled.should be_false

    Diorite::DebugDraw.enabled = true
    Diorite::DebugDraw.enabled.should be_true
  end
end
