require "lapis"
require "../core/geometry_builder"
require "../core/debug_material"

module Diorite
  # Supported 2D debug shape kinds for categorization and reference.
  enum Shape2DType
    Line
    Arrow
    Rect
    Circle
  end

  # Base inspector-configurable 2D debug shape node rendered on Godot's canvas.
  #
  # Supports live-previewing in the Godot Editor (`@[Tool]` mode) and updates wireframe
  # geometry dynamically whenever properties are modified in the Inspector or script.
  # Concrete subclasses (like `DebugRect2D` or `DebugCircle2D`) implement `build_shape`.
  @[Tool]
  node DebugShape2D < Node2D do
    # Line and outline color.
    @[Export]
    property color : Godot::Color = Godot::Color.new(0.2_f32, 1.0_f32, 0.4_f32, 1.0_f32)

    # When true, elevates z_index to 4096 so the shape renders on top of canvas elements.
    @[Export]
    property draw_on_top : Bool = true

    @mesh_instance : Godot::MeshInstance2D? = nil
    @immediate_mesh : Godot::ImmediateMesh? = nil
    @verts = Array(Godot::Vector2).new(256)
    @cols = Array(Godot::Color).new(256)

    def _ready : Void
      setup_mesh
      rebuild_mesh
    end

    def _process(delta : Float64) : Void
      rebuild_mesh
    end

    protected def build_shape(verts : Array(Godot::Vector2), cols : Array(Godot::Color)) : Void
      # Implemented by shape-specific subclasses
    end

    private def setup_mesh : Void
      return if @mesh_instance
      if @draw_on_top
        set_z_index(4096_i64)
        set_z_as_relative(false)
      end

      mesh = Godot.create(Godot::ImmediateMesh)
      mesh.init_ref if mesh.get_reference_count == 0
      mesh.reference
      inst = Godot.create(Godot::MeshInstance2D)
      inst.set_mesh(mesh)
      add_child(inst)
      @mesh_instance = inst
      @immediate_mesh = mesh
    end

    private def rebuild_mesh : Void
      m = @immediate_mesh
      inst = @mesh_instance
      return unless m && inst && m.alive? && inst.alive?

      @verts.clear
      @cols.clear

      build_shape(@verts, @cols)

      m.clear_surfaces
      if @verts.size > 0
        m.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_on_top)
        (0...@verts.size).each do |i|
          m.surface_set_color(@cols[i])
          m.surface_add_vertex_2d(@verts[i])
        end
        m.surface_end
      end
    end
  end

  # Node representing an inspector-configurable 2D debug line.
  @[Tool]
  node DebugLine2D < DebugShape2D do
    # Relative target vector endpoint.
    @[Export]
    property target : Godot::Vector2 = Godot::Vector2.new(100.0_f32, 100.0_f32)

    protected def build_shape(verts : Array(Godot::Vector2), cols : Array(Godot::Color)) : Void
      origin = Godot::Vector2.new(0.0_f32, 0.0_f32)
      GeometryBuilder.build_line_2d(origin, @target, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 2D directional arrow.
  @[Tool]
  node DebugArrow2D < DebugShape2D do
    # Relative target vector endpoint.
    @[Export]
    property target : Godot::Vector2 = Godot::Vector2.new(100.0_f32, 100.0_f32)

    # Size of the arrow head lines.
    @[Export]
    property head_size : Float32 = 12.0_f32

    protected def build_shape(verts : Array(Godot::Vector2), cols : Array(Godot::Color)) : Void
      origin = Godot::Vector2.new(0.0_f32, 0.0_f32)
      GeometryBuilder.build_arrow_2d(origin, @target, @head_size, @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 2D wireframe rectangle.
  @[Tool]
  node DebugRect2D < DebugShape2D do
    # Dimensions for Rect shapes.
    @[Export]
    property rect_size : Godot::Vector2 = Godot::Vector2.new(80.0_f32, 50.0_f32)

    protected def build_shape(verts : Array(Godot::Vector2), cols : Array(Godot::Color)) : Void
      origin = Godot::Vector2.new(0.0_f32, 0.0_f32)
      GeometryBuilder.build_rect_2d(Godot::Rect2.new(origin.x, origin.y, @rect_size.x, @rect_size.y), @color, verts, cols)
    end
  end

  # Node representing an inspector-configurable 2D wireframe circle.
  @[Tool]
  node DebugCircle2D < DebugShape2D do
    # Radius for Circle shapes.
    @[Export]
    property radius : Float32 = 40.0_f32

    # Perimeter segment resolution for Circle shapes.
    @[Export]
    property segments : Int32 = 24

    protected def build_shape(verts : Array(Godot::Vector2), cols : Array(Godot::Color)) : Void
      origin = Godot::Vector2.new(0.0_f32, 0.0_f32)
      GeometryBuilder.build_circle_2d(origin, @radius, @segments, @color, verts, cols)
    end
  end
end
