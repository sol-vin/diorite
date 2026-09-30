require "./spec_helper"

describe Diorite::MathHelpers do
  it "converts degrees to radians and radians to degrees" do
    Diorite::MathHelpers.deg_to_rad(0.0_f32).should be_close(0.0_f32, 0.0001_f32)
    Diorite::MathHelpers.deg_to_rad(90.0_f32).should be_close(Math::PI.to_f32 / 2.0_f32, 0.0001_f32)
    Diorite::MathHelpers.deg_to_rad(180.0_f32).should be_close(Math::PI.to_f32, 0.0001_f32)
    Diorite::MathHelpers.deg_to_rad(360.0_f32).should be_close(Diorite::MathHelpers::TAU, 0.0001_f32)

    Diorite::MathHelpers.rad_to_deg(0.0_f32).should be_close(0.0_f32, 0.0001_f32)
    Diorite::MathHelpers.rad_to_deg(Math::PI.to_f32).should be_close(180.0_f32, 0.0001_f32)
    Diorite::MathHelpers.rad_to_deg(Diorite::MathHelpers::TAU).should be_close(360.0_f32, 0.0001_f32)
  end

  it "computes a valid perpendicular vector for any direction" do
    directions = [
      Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32),
      Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32), # Up vector edge case
      Godot::Vector3.new(0.0_f32, -1.0_f32, 0.0_f32), # Down vector edge case
      Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32),
      Godot::Vector3.new(0.577_f32, 0.577_f32, 0.577_f32).normalized,
      Godot::Vector3.new(-2.3_f32, 4.1_f32, -0.9_f32).normalized
    ]

    directions.each do |dir|
      perp = Diorite::MathHelpers.find_perpendicular(dir)
      # Check orthogonal (dot product is zero)
      dot = dir.dot(perp)
      dot.abs.should be_close(0.0_f32, 0.001_f32)
      # Check normalized
      perp.length.should be_close(1.0_f32, 0.001_f32)
    end
  end

  it "constructs a valid orthonormal basis plane (u, v) for a normal vector" do
    normals = [
      Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
      Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32),
      Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32),
      Godot::Vector3.new(0.0_f32, -1.0_f32, 0.0_f32),
      Godot::Vector3.new(0.7071_f32, 0.0_f32, 0.7071_f32).normalized,
      Godot::Vector3.new(0.3_f32, 0.8_f32, -0.5_f32).normalized
    ]

    normals.each do |n|
      u, v = Diorite::MathHelpers.orthonormal_plane(n)

      # Magnitudes are unit length
      u.length.should be_close(1.0_f32, 0.001_f32)
      v.length.should be_close(1.0_f32, 0.001_f32)

      # Mutually perpendicular to normal and each other
      u.dot(n).abs.should be_close(0.0_f32, 0.001_f32)
      v.dot(n).abs.should be_close(0.0_f32, 0.001_f32)
      u.dot(v).abs.should be_close(0.0_f32, 0.001_f32)
    end
  end

  it "rotates a vector around an arbitrary axis using Rodrigues' formula" do
    vec = Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32)
    axis_y = Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32)

    # 90 degrees around Y: (1, 0, 0) -> (0, 0, -1) in Godot coordinate system
    rotated_90 = Diorite::MathHelpers.rotate_around_axis(vec, axis_y, Math::PI.to_f32 * 0.5_f32)
    rotated_90.x.should be_close(0.0_f32, 0.001_f32)
    rotated_90.y.should be_close(0.0_f32, 0.001_f32)
    rotated_90.z.should be_close(-1.0_f32, 0.001_f32)
    rotated_90.length.should be_close(1.0_f32, 0.001_f32)

    # 180 degrees around Y: (1, 0, 0) -> (-1, 0, 0)
    rotated_180 = Diorite::MathHelpers.rotate_around_axis(vec, axis_y, Math::PI.to_f32)
    rotated_180.x.should be_close(-1.0_f32, 0.001_f32)
    rotated_180.y.should be_close(0.0_f32, 0.001_f32)
    rotated_180.z.should be_close(0.0_f32, 0.001_f32)

    # 360 degrees rotation returns to initial vector
    rotated_360 = Diorite::MathHelpers.rotate_around_axis(vec, axis_y, Diorite::MathHelpers::TAU)
    rotated_360.x.should be_close(1.0_f32, 0.001_f32)
    rotated_360.y.should be_close(0.0_f32, 0.001_f32)
    rotated_360.z.should be_close(0.0_f32, 0.001_f32)
  end
end
