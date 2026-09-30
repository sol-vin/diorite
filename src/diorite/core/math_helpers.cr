module Diorite
  module MathHelpers
    PI = 3.14159265358979323846_f32
    TAU = 6.28318530717958647692_f32

    def self.deg_to_rad(degrees : Number) : Float32
      (degrees.to_f32 * PI) / 180.0_f32
    end

    def self.rad_to_deg(radians : Number) : Float32
      (radians.to_f32 * 180.0_f32) / PI
    end

    # Finds a perpendicular vector to the given normalized vector.
    def self.find_perpendicular(normal : Godot::Vector3) : Godot::Vector3
      n = normal.normalized
      # If normal is roughly parallel to Y axis, use X axis cross product
      if n.x.abs < 0.9_f32 && n.z.abs < 0.9_f32
        Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32).cross(n).normalized
      else
        Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32).cross(n).normalized
      end
    end

    # Constructs an orthonormal basis (u, v) on the plane perpendicular to normal.
    def self.orthonormal_plane(normal : Godot::Vector3) : Tuple(Godot::Vector3, Godot::Vector3)
      u = find_perpendicular(normal)
      v = normal.cross(u).normalized
      {u, v}
    end

    # Rotates a 3D point around an arbitrary axis by theta radians using Rodrigues' formula.
    def self.rotate_around_axis(point : Godot::Vector3, axis : Godot::Vector3, theta : Float32) : Godot::Vector3
      k = axis.normalized
      cos_t = Math.cos(theta).to_f32
      sin_t = Math.sin(theta).to_f32
      point * cos_t + k.cross(point) * sin_t + k * (k.dot(point) * (1.0_f32 - cos_t))
    end
  end
end
