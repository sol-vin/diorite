require "lapis"
require "./debug_shape_3d"

module Diorite
  # Node representing an inspector-configurable 3D wireframe bounding box.
  @[Tool]
  node DebugBox3D < DebugShape3D do
    # Dimensions of the bounding box.
    @[Export]
    property size : Godot::Vector3 = Godot::Vector3.new(1.0_f32, 1.0_f32, 1.0_f32)

    def box_size : Godot::Vector3
      @size
    end

    def box_size=(val : Godot::Vector3) : Void
      @size = val
    end

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_box(center, @size, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_box(center, @size, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D wireframe sphere.
  @[Tool]
  node DebugSphere3D < DebugShape3D do
    # Outer radius of the sphere.
    @[Export]
    property radius : Float32 = 1.0_f32

    # Ring / perimeter resolution.
    @[Export]
    property rings : Int32 = 16

    def segments : Int32
      @rings
    end

    def segments=(val : Int32) : Void
      @rings = val
    end

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_sphere(center, @radius, @rings, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_sphere(center, @radius, @rings, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D wireframe cylinder.
  @[Tool]
  node DebugCylinder3D < DebugShape3D do
    # Base and cap radius.
    @[Export]
    property radius : Float32 = 1.0_f32

    # Total height along Y axis.
    @[Export]
    property height : Float32 = 2.0_f32

    # Perimeter segment resolution.
    @[Export]
    property segments : Int32 = 16

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_cylinder(center, @radius, @height, @segments, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_cylinder(center, @radius, @height, @segments, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D wireframe capsule.
  @[Tool]
  node DebugCapsule3D < DebugShape3D do
    # Dome and cylinder radius.
    @[Export]
    property radius : Float32 = 1.0_f32

    # Total vertical height.
    @[Export]
    property height : Float32 = 2.0_f32

    # Perimeter segment resolution.
    @[Export]
    property segments : Int32 = 16

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_capsule(center, @radius, @height, @segments, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_capsule(center, @radius, @height, @segments, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D line vector.
  @[Tool]
  node DebugLine3D < DebugShape3D do
    # Relative target vector endpoint.
    @[Export]
    property target : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 2.0_f32)

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_line(center, @target, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_line(center, @target, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D directional arrow with arrowhead.
  @[Tool]
  node DebugArrow3D < DebugShape3D do
    # Relative target vector endpoint.
    @[Export]
    property target : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 2.0_f32)

    # Size of the arrowhead cone fin lines.
    @[Export]
    property head_size : Float32 = 0.3_f32

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_arrow(center, @target, @color, @head_size, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_arrow(center, @target, @color, @head_size, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3-axis position crosshair.
  @[Tool]
  node DebugAxes3D < DebugShape3D do
    # Axis length / scale.
    @[Export]
    property size : Float32 = 1.0_f32

    def radius : Float32
      @size
    end

    def radius=(val : Float32) : Void
      @size = val
    end

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_gizmo(center, Godot::Basis.new, @size, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_gizmo(center, Godot::Basis.new, @size, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D ground reference grid plane.
  @[Tool]
  node DebugGrid3D < DebugShape3D do
    # Width and depth dimensions for the grid plane.
    @[Export]
    property size : Godot::Vector2 = Godot::Vector2.new(10.0_f32, 10.0_f32)

    # Number of grid subdivisions.
    @[Export]
    property subdivisions : Int32 = 10

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_grid(center, @size, @subdivisions, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_grid(center, @size, @subdivisions, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D sensory vision / detection cone.
  @[Tool]
  node DebugVisionCone3D < DebugShape3D do
    # Forward look direction or target offset.
    @[Export]
    property target : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32)

    # Field-of-view angle in degrees.
    @[Export]
    property angle_deg : Float32 = 45.0_f32

    # Maximum sensory distance.
    @[Export]
    property range : Float32 = 8.0_f32

    # Arc segment count.
    @[Export]
    property segments : Int32 = 24

    def cone_angle : Float32
      @angle_deg
    end

    def cone_angle=(val : Float32) : Void
      @angle_deg = val
    end

    def cone_range : Float32
      @range
    end

    def cone_range=(val : Float32) : Void
      @range = val
    end

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      dir = @target.length_squared > 0.0001_f32 ? @target.normalized : Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32)
      GeometryBuilder.build_vision_cone(center, dir, @angle_deg, @range, @segments, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      dir = @target.length_squared > 0.0001_f32 ? @target.normalized : Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32)
      GeometryBuilder.build_vision_cone(center, dir, @angle_deg, @range, @segments, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 3D helical physics spring.
  @[Tool]
  node DebugSpring3D < DebugShape3D do
    # Relative target vector endpoint.
    @[Export]
    property target : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 2.0_f32)

    # Helical coil radius.
    @[Export]
    property radius : Float32 = 0.5_f32

    # Number of complete spiral rotations.
    @[Export]
    property coils : Int32 = 8

    # Segments per coil.
    @[Export]
    property segments : Int32 = 16

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_spring(center, @target, @radius, @coils, @segments, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_spring(center, @target, @radius, @coils, @segments, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable calibrated distance measurement ruler.
  @[Tool]
  node DebugRuler3D < DebugShape3D do
    # Relative target vector endpoint.
    @[Export]
    property target : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 2.0_f32)

    # Distance between calibration tick marks.
    @[Export]
    property tick_size : Float32 = 0.2_f32

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_ruler(center, @target, @tick_size, @color, verts, cols)
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)
      GeometryBuilder.build_ruler(center, @target, @tick_size, @color, verts, cols)
    end
  end
end
