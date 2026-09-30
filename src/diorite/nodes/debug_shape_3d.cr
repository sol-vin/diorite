require "lapis"
require "../core/geometry_builder"
require "../core/debug_material"

module Diorite
  enum Shape3DType
    Box
    Sphere
    Cylinder
    Capsule
    Line
    Arrow
    Gizmo
    Grid
    Plane
    VisionCone
    TrajectoryArc
    Spring
    Ruler
    BillboardSquare
  end

  # Inspector-configurable 3D debug shape node for placement directly in Godot scenes.
  #
  # Supports live-previewing in the Godot Editor (`@[Tool]` mode) and updates wireframe geometry
  # dynamically whenever properties are modified in the Inspector or script.
  @[Tool]
  node DebugShape3D < Node3D do
    # Target shape type index corresponding to `Shape3DType`.
    @[Export]
    property shape_type : Int32 = 0 # Shape3DType::Box

    # Primary wireframe line color.
    @[Export]
    property color : Godot::Color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32)

    # When true, disables depth testing and renders with priority 127 on top of scene geometry.
    @[Export]
    property draw_on_top : Bool = true

    # Dimensions for Box, Plane, and Grid shapes.
    @[Export]
    property size : Godot::Vector3 = Godot::Vector3.new(1.0_f32, 1.0_f32, 1.0_f32)

    # Radius for Sphere, Cylinder, Capsule, Gizmo, and Spring shapes.
    @[Export]
    property radius : Float32 = 1.0_f32

    # Vertical height for Cylinder and Capsule shapes.
    @[Export]
    property height : Float32 = 2.0_f32

    # Target vector coordinate for Line, Arrow, VisionCone, Spring, and Ruler shapes.
    @[Export]
    property target : Godot::Vector3 = Godot::Vector3.new(0.0_f32, 0.0_f32, 2.0_f32)

    # Field-of-view angle in degrees for VisionCone shapes.
    @[Export]
    property angle_deg : Float32 = 45.0_f32

    # Maximum sensory distance for VisionCone shapes.
    @[Export]
    property range : Float32 = 8.0_f32

    # Number of complete spiral rotations for Spring shapes.
    @[Export]
    property coils : Int32 = 8

    # Grid subdivision count for Grid shapes.
    @[Export]
    property subdivisions : Int32 = 10

    @mesh_instance : Godot::MeshInstance3D? = nil
    @immediate_mesh : Godot::ImmediateMesh? = nil
    @verts = Array(Godot::Vector3).new(512)
    @cols = Array(Godot::Color).new(512)

    def _ready : Void
      setup_mesh
      rebuild_mesh
    end

    def _process(delta : Float64) : Void
      rebuild_mesh
    end

    private def setup_mesh : Void
      mesh = Godot.create(Godot::ImmediateMesh)
      inst = Godot.create(Godot::MeshInstance3D)
      inst.set_mesh(mesh)
      add_child(inst)
      @mesh_instance = inst
      @immediate_mesh = mesh
    end

    private def rebuild_mesh : Void
      m = @immediate_mesh
      inst = @mesh_instance
      return unless m && inst

      mat = @draw_on_top ? DebugMaterialManager.material_on_top : DebugMaterialManager.material_depth_tested
      inst.set_material_override(mat)

      @verts.clear
      @cols.clear

      center = Godot::Vector3.new(0.0_f32, 0.0_f32, 0.0_f32)

      case @shape_type
      when 0 # Box
        GeometryBuilder.build_box(center, @size, @color, @verts, @cols)
      when 1 # Sphere
        GeometryBuilder.build_sphere(center, @radius, 16, @color, @verts, @cols)
      when 2 # Cylinder
        GeometryBuilder.build_cylinder(center, @radius, @height, 16, @color, @verts, @cols)
      when 3 # Capsule
        GeometryBuilder.build_capsule(center, @radius, @height, 16, @color, @verts, @cols)
      when 4 # Line
        GeometryBuilder.build_line(center, @target, @color, @verts, @cols)
      when 5 # Arrow
        GeometryBuilder.build_arrow(center, @target, @color, 0.3_f32, @verts, @cols)
      when 6 # Gizmo
        GeometryBuilder.build_gizmo(center, Godot::Basis.new, @radius, @verts, @cols)
      when 7 # Grid
        GeometryBuilder.build_grid(center, Godot::Vector2.new(@size.x, @size.z), @subdivisions, @color, @verts, @cols)
      when 8 # Plane
        GeometryBuilder.build_plane(center, Godot::Vector3.new(0, 1, 0), Godot::Vector2.new(@size.x, @size.z), @color, @verts, @cols)
      when 9 # VisionCone
        GeometryBuilder.build_vision_cone(center, @target.normalized, @angle_deg, @range, 24, @color, @verts, @cols)
      when 10 # TrajectoryArc
        GeometryBuilder.build_trajectory_arc(center, @target * 5.0_f32, Godot::Vector3.new(0, -9.8, 0), 2.0_f32, 30, @color, @verts, @cols)
      when 11 # Spring
        GeometryBuilder.build_spring(center, @target, @radius * 0.25_f32, @coils, 16, @color, @verts, @cols)
      when 12 # Ruler
        GeometryBuilder.build_ruler(center, @target, 0.2_f32, @color, @verts, @cols)
      when 13 # BillboardSquare
        GeometryBuilder.build_billboard_square(center, @radius, Godot::Vector3.new(0, 0, 5), @color, @verts, @cols)
      else
        GeometryBuilder.build_box(center, @size, @color, @verts, @cols)
      end

      m.clear_surfaces
      if @verts.size > 0
        m.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, mat)
        (0...@verts.size).each do |i|
          m.surface_set_color(@cols[i])
          m.surface_add_vertex(@verts[i])
        end
        m.surface_end
      end
    end
  end
end
