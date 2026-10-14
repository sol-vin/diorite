require "lapis"
require "../core/geometry_builder"
require "../core/debug_material"
require "../core/frame_arena_batch"

module Diorite
  # Supported 3D debug shape kinds for categorization and reference.
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

  # Base inspector-configurable 3D debug shape node for placement directly in Godot scenes.
  #
  # Manages the immediate mesh lifecycle, material override (depth-tested vs on-top),
  # and process-loop updates using `Lapis::Core::FrameArena` scratchpad buffers.
  # Concrete subclasses (like `DebugBox3D` or `DebugSphere3D`) implement `build_shape`
  # and `build_shape_arena` to generate their specific wireframe geometry.
  @[Tool]
  node DebugShape3D < Node3D do
    # Primary wireframe line color.
    @[Export]
    property color : Godot::Color = Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 1.0_f32)

    # When true, disables depth testing and renders with priority 127 on top of scene geometry.
    @[Export]
    property draw_on_top : Bool = true

    @mesh_instance : Godot::MeshInstance3D? = nil
    @immediate_mesh : Godot::ImmediateMesh? = nil

    def _ready : Void
      setup_mesh
      rebuild_mesh
    end

    def _process(delta : Float64) : Void
      rebuild_mesh
    end

    protected def build_shape(verts : Array(Godot::Vector3), cols : Array(Godot::Color)) : Void
      # Implemented by shape-specific subclasses
    end

    protected def build_shape_arena(verts : ArenaVertexBuffer(Godot::Vector3), cols : ArenaVertexBuffer(Godot::Color)) : Void
      # Implemented by shape-specific subclasses for zero-allocation FrameArena rendering
    end

    private def setup_mesh : Void
      return if @mesh_instance
      mesh = Godot.create(Godot::ImmediateMesh)
      mesh.init_ref if mesh.get_reference_count == 0
      mesh.reference
      inst = Godot.create(Godot::MeshInstance3D)
      inst.set_mesh(mesh)
      add_child(inst)
      @mesh_instance = inst
      @immediate_mesh = mesh
    end

    private def rebuild_mesh : Void
      m = @immediate_mesh
      inst = @mesh_instance
      return unless m && inst && m.alive? && inst.alive?

      mat = @draw_on_top ? DebugMaterialManager.material_on_top : DebugMaterialManager.material_depth_tested
      return unless mat.alive?
      inst.set_material_override(mat)

      Lapis::Core::FrameArena.scope do |arena|
        batch = FrameLineBatch3D.from_arena(arena, 512)
        verts = batch.verts
        cols = batch.cols

        build_shape_arena(verts, cols)

        m.clear_surfaces
        n = verts.size
        if n > 0
          m.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, mat)
          i = 0
          while i < n
            m.surface_set_color(cols.unsafe_fetch(i))
            m.surface_add_vertex(verts.unsafe_fetch(i))
            i += 1
          end
          m.surface_end
        end
      end
    end
  end
end
