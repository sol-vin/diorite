require "lapis"
require "../core/geometry_builder"
require "../core/debug_material"

module Diorite
  # Supported 2D debug shape kinds for node-based rendering.
  enum Shape2DType
    Line
    Arrow
    Rect
    Circle
  end

  # Inspector-configurable 2D debug shape node rendered on Godot's canvas.
  #
  # Supports live-previewing in the Godot Editor (`@[Tool]` mode) and updates wireframe
  # geometry dynamically whenever properties are modified in the Inspector or script.
  @[Tool]
  node DebugShape2D < Node2D do
    # Target 2D shape kind index (0=Line, 1=Arrow, 2=Rect, 3=Circle).
    @[Export]
    property shape_type : Int32 = 0

    # Line and outline color.
    @[Export]
    property color : Godot::Color = Godot::Color.new(0.2_f32, 1.0_f32, 0.4_f32, 1.0_f32)

    # Relative target vector endpoint for Line and Arrow shapes.
    @[Export]
    property target : Godot::Vector2 = Godot::Vector2.new(100.0_f32, 100.0_f32)

    # Dimensions for Rect shapes.
    @[Export]
    property rect_size : Godot::Vector2 = Godot::Vector2.new(80.0_f32, 50.0_f32)

    # Radius for Circle shapes.
    @[Export]
    property radius : Float32 = 40.0_f32

    # Perimeter segment resolution for Circle shapes.
    @[Export]
    property segments : Int32 = 24

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

    private def setup_mesh : Void
      if @draw_on_top
        set_z_index(4096_i64)
        set_z_as_relative(false)
      end

      mesh = Godot.create(Godot::ImmediateMesh)
      inst = Godot.create(Godot::MeshInstance2D)
      inst.set_mesh(mesh)
      add_child(inst)
      @mesh_instance = inst
      @immediate_mesh = mesh
    end

    private def rebuild_mesh : Void
      m = @immediate_mesh
      return unless m

      @verts.clear
      @cols.clear

      origin = Godot::Vector2.new(0.0_f32, 0.0_f32)

      case @shape_type
      when 0 # Line
        GeometryBuilder.build_line_2d(origin, @target, @color, @verts, @cols)
      when 1 # Arrow
        GeometryBuilder.build_arrow_2d(origin, @target, 12.0_f32, @color, @verts, @cols)
      when 2 # Rect
        GeometryBuilder.build_rect_2d(Godot::Rect2.new(origin.x, origin.y, @rect_size.x, @rect_size.y), @color, @verts, @cols)
      when 3 # Circle
        GeometryBuilder.build_circle_2d(origin, @radius, @segments, @color, @verts, @cols)
      end

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
    def _ready : Void
      self.shape_type = 0 # Line
      super
    end
  end

  # Node representing an inspector-configurable 2D directional arrow.
  @[Tool]
  node DebugArrow2D < DebugShape2D do
    def _ready : Void
      self.shape_type = 1 # Arrow
      super
    end
  end

  # Node representing an inspector-configurable 2D wireframe rectangle.
  @[Tool]
  node DebugRect2D < DebugShape2D do
    def _ready : Void
      self.shape_type = 2 # Rect
      super
    end
  end

  # Node representing an inspector-configurable 2D wireframe circle.
  @[Tool]
  node DebugCircle2D < DebugShape2D do
    def _ready : Void
      self.shape_type = 3 # Circle
      super
    end
  end
end
