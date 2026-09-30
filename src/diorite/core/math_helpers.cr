module Diorite
  # Pure mathematical utilities and vector transformations for debug geometry generation.
  module MathHelpers
    # Standard circle constant PI (π).
    PI = 3.14159265358979323846_f32

    # Circle constant TAU (2π), representing one full turn in radians.
    TAU = 6.28318530717958647692_f32

    # Converts an angle from degrees to radians.
    def self.deg_to_rad(degrees : Number) : Float32
      (degrees.to_f32 * PI) / 180.0_f32
    end

    # Converts an angle from radians to degrees.
    def self.rad_to_deg(radians : Number) : Float32
      (radians.to_f32 * 180.0_f32) / PI
    end

    # Finds a perpendicular unit vector to the given normalized vector *normal*.
    #
    # Avoids gimbal singularities by checking alignment with coordinate axes.
    #
    # ```crystal
    # norm = Vector3.new(0, 1, 0)
    # perp = MathHelpers.find_perpendicular(norm)
    # ```
    def self.find_perpendicular(normal : Godot::Vector3) : Godot::Vector3
      n = normal.normalized
      # If normal is roughly parallel to Y axis, use X axis cross product
      if n.x.abs < 0.9_f32 && n.z.abs < 0.9_f32
        Godot::Vector3.new(1.0_f32, 0.0_f32, 0.0_f32).cross(n).normalized
      else
        Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32).cross(n).normalized
      end
    end

    # Constructs an orthonormal basis `(u, v)` spanning the plane perpendicular to *normal*.
    #
    # Both vectors are unit length and orthogonal to each other and to *normal*.
    #
    # ```crystal
    # u, v = MathHelpers.orthonormal_plane(surface_normal)
    # ```
    def self.orthonormal_plane(normal : Godot::Vector3) : Tuple(Godot::Vector3, Godot::Vector3)
      u = find_perpendicular(normal)
      v = normal.cross(u).normalized
      {u, v}
    end

    # Rotates a 3D *point* around an arbitrary *axis* by *theta* radians using Rodrigues' formula.
    #
    # ```crystal
    # rotated = MathHelpers.rotate_around_axis(pt, Vector3.new(0, 1, 0), Math::PI / 2)
    # ```
    def self.rotate_around_axis(point : Godot::Vector3, axis : Godot::Vector3, theta : Float32) : Godot::Vector3
      k = axis.normalized
      cos_t = Math.cos(theta).to_f32
      sin_t = Math.sin(theta).to_f32
      point * cos_t + k.cross(point) * sin_t + k * (k.dot(point) * (1.0_f32 - cos_t))
    end
  end
end
