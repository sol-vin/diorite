require "lapis"
require "../core/dsl"
require "../core/debug_material"

module Diorite
  # Central coordinator node managing batch immediate-mode rendering for 2D and 3D debug primitives.
  #
  # Maintains high-priority `ImmediateMesh` instances for 3D on-top and depth-tested passes,
  # a dedicated `CanvasLayer` for 2D geometry, and object pools for 2D/3D billboard labels.
  #
  # Add this node to your scene or let `MainNode` spawn it automatically.
  @[Tool]
  node DebugDrawManager < Node do
    # Toggles whether all debug primitives and labels are processed and drawn.
    @[Export]
    property enabled : Bool = true

    @mesh_inst_on_top : Godot::MeshInstance3D? = nil
    @immediate_mesh_on_top : Godot::ImmediateMesh? = nil

    @mesh_inst_depth : Godot::MeshInstance3D? = nil
    @immediate_mesh_depth : Godot::ImmediateMesh? = nil

    @canvas_layer : Godot::CanvasLayer? = nil
    @mesh_inst_2d : Godot::MeshInstance2D? = nil
    @immediate_mesh_2d : Godot::ImmediateMesh? = nil

    @label3d_pool = Array(Godot::Label3D).new
    @label2d_pool = Array(Godot::Label).new

    # Pre-allocated vertex buffers to avoid GC pressure
    @verts_top = Array(Godot::Vector3).new(1024)
    @cols_top = Array(Godot::Color).new(1024)
    @verts_depth = Array(Godot::Vector3).new(512)
    @cols_depth = Array(Godot::Color).new(512)
    @verts_2d = Array(Godot::Vector2).new(1024)
    @cols_2d = Array(Godot::Color).new(1024)

    def _ready : Void
      setup_renderers
    end

    private def setup_renderers : Void
      # 1. 3D On-Top Renderer
      mesh_top = Godot.create(Godot::ImmediateMesh)
      inst_top = Godot.create(Godot::MeshInstance3D)
      inst_top.set_mesh(mesh_top)
      inst_top.set_material_override(DebugMaterialManager.material_on_top)
      add_child(inst_top)
      @mesh_inst_on_top = inst_top
      @immediate_mesh_on_top = mesh_top

      # 2. 3D Depth-Tested Renderer
      mesh_depth = Godot.create(Godot::ImmediateMesh)
      inst_depth = Godot.create(Godot::MeshInstance3D)
      inst_depth.set_mesh(mesh_depth)
      inst_depth.set_material_override(DebugMaterialManager.material_depth_tested)
      add_child(inst_depth)
      @mesh_inst_depth = inst_depth
      @immediate_mesh_depth = mesh_depth

      # 3. 2D Canvas Layer & Renderer
      layer = Godot.create(Godot::CanvasLayer)
      layer.set_layer(128_i64)
      add_child(layer)
      @canvas_layer = layer

      mesh_2d = Godot.create(Godot::ImmediateMesh)
      inst_2d = Godot.create(Godot::MeshInstance2D)
      inst_2d.set_mesh(mesh_2d)
      inst_2d.set_z_index(4096_i64)
      inst_2d.set_z_as_relative(false)
      layer.add_child(inst_2d)
      @mesh_inst_2d = inst_2d
      @immediate_mesh_2d = mesh_2d
    end

    def _process(delta : Float64) : Void
      return unless @enabled

      render_3d
      render_2d
      render_text_3d
      render_text_2d

      DebugDraw.queue.step_and_clean(delta)
    end

    private def render_3d : Void
      m_top = @immediate_mesh_on_top
      m_depth = @immediate_mesh_depth
      return unless m_top && m_depth

      @verts_top.clear
      @cols_top.clear
      @verts_depth.clear
      @cols_depth.clear

      # Dispatch each queued 3D command
      DebugDraw.queue.commands_3d.each do |cmd|
        target_verts = cmd.on_top ? @verts_top : @verts_depth
        target_cols = cmd.on_top ? @cols_top : @cols_depth

        case cmd.kind
        when ShapeKind3D::Line
          GeometryBuilder.build_line(cmd.v0, cmd.v1, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Arrow, ShapeKind3D::LineArrow
          GeometryBuilder.build_arrow(cmd.v0, cmd.v1, cmd.color, cmd.f0, target_verts, target_cols)
        when ShapeKind3D::LinePath
          if p = cmd.path
            GeometryBuilder.build_line_path(p, cmd.color, target_verts, target_cols)
          end
        when ShapeKind3D::Box
          GeometryBuilder.build_box(cmd.v0, cmd.v1, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Sphere
          GeometryBuilder.build_sphere(cmd.v0, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Cylinder
          GeometryBuilder.build_cylinder(cmd.v0, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Capsule
          GeometryBuilder.build_capsule(cmd.v0, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Plane
          GeometryBuilder.build_plane(cmd.v0, cmd.v1, Godot::Vector2.new(cmd.f0, cmd.f1), cmd.color, target_verts, target_cols)
        when ShapeKind3D::Points
          if p = cmd.path
            GeometryBuilder.build_points(p, cmd.f0, cmd.color, target_verts, target_cols)
          end
        when ShapeKind3D::Position3D
          GeometryBuilder.build_position_3d(cmd.v0, cmd.f0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Gizmo
          GeometryBuilder.build_gizmo(cmd.v0, cmd.basis, cmd.f0, target_verts, target_cols)
        when ShapeKind3D::Grid
          GeometryBuilder.build_grid(cmd.v0, Godot::Vector2.new(cmd.f0, cmd.f1), cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::CameraFrustum
          GeometryBuilder.build_camera_frustum(cmd.v0, cmd.basis, cmd.f0, cmd.f1, cmd.f2, cmd.f3, cmd.color, target_verts, target_cols)
        when ShapeKind3D::BillboardSquare
          GeometryBuilder.build_billboard_square(cmd.v0, cmd.f0, cmd.v1, cmd.color, target_verts, target_cols)
        when ShapeKind3D::RayHit
          GeometryBuilder.build_ray_hit(cmd.v0, cmd.v1, cmd.v2, cmd.color, target_verts, target_cols)
        when ShapeKind3D::TrajectoryArc
          GeometryBuilder.build_trajectory_arc(cmd.v0, cmd.v1, cmd.v2, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::VisionCone
          GeometryBuilder.build_vision_cone(cmd.v0, cmd.v1, cmd.f0, cmd.f1, cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::OBB
          GeometryBuilder.build_obb(cmd.v0, cmd.v1, cmd.basis, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Spring
          GeometryBuilder.build_spring(cmd.v0, cmd.v1, cmd.f0, cmd.i0, cmd.i1, cmd.color, target_verts, target_cols)
        when ShapeKind3D::SurfaceDisk
          GeometryBuilder.build_surface_disk(cmd.v0, cmd.v1, cmd.f0, cmd.i0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Ruler
          GeometryBuilder.build_ruler(cmd.v0, cmd.v1, cmd.f0, cmd.color, target_verts, target_cols)
        when ShapeKind3D::Reticle
          GeometryBuilder.build_reticle(cmd.v0, cmd.v1, cmd.f0, cmd.color, target_verts, target_cols)
        end
      end

      # Flush On-Top ImmediateMesh
      m_top.clear_surfaces
      if @verts_top.size > 0
        m_top.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_on_top)
        (0...@verts_top.size).each do |i|
          m_top.surface_set_color(@cols_top[i])
          m_top.surface_add_vertex(@verts_top[i])
        end
        m_top.surface_end
      end

      # Flush Depth-Tested ImmediateMesh
      m_depth.clear_surfaces
      if @verts_depth.size > 0
        m_depth.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_depth_tested)
        (0...@verts_depth.size).each do |i|
          m_depth.surface_set_color(@cols_depth[i])
          m_depth.surface_add_vertex(@verts_depth[i])
        end
        m_depth.surface_end
      end
    end

    private def render_2d : Void
      m_2d = @immediate_mesh_2d
      return unless m_2d

      @verts_2d.clear
      @cols_2d.clear

      # 1. 2D Draw Commands
      DebugDraw.queue.commands_2d.each do |cmd|
        case cmd.kind
        when ShapeKind2D::Line
          GeometryBuilder.build_line_2d(cmd.p0, cmd.p1, cmd.color, @verts_2d, @cols_2d)
        when ShapeKind2D::Arrow
          GeometryBuilder.build_arrow_2d(cmd.p0, cmd.p1, cmd.f0, cmd.color, @verts_2d, @cols_2d)
        when ShapeKind2D::Rect
          GeometryBuilder.build_rect_2d(cmd.rect, cmd.color, @verts_2d, @cols_2d)
        when ShapeKind2D::Circle
          GeometryBuilder.build_circle_2d(cmd.p0, cmd.f0, cmd.i0, cmd.color, @verts_2d, @cols_2d)
        when ShapeKind2D::Points
          if pts = cmd.points
            GeometryBuilder.build_points_2d(pts, cmd.f0, cmd.color, @verts_2d, @cols_2d)
          end
        when ShapeKind2D::Path
          if pts = cmd.points
            GeometryBuilder.build_path_2d(pts, cmd.color, @verts_2d, @cols_2d)
          end
        end
      end

      # 2. Telemetry Graphs
      DebugDraw.queue.telemetry_graphs.each_value do |graph|
        graph.build_geometry(@verts_2d, @cols_2d)
      end

      m_2d.clear_surfaces
      if @verts_2d.size > 0
        m_2d.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_on_top)
        (0...@verts_2d.size).each do |i|
          m_2d.surface_set_color(@cols_2d[i])
          m_2d.surface_add_vertex_2d(@verts_2d[i])
        end
        m_2d.surface_end
      end
    end

    private def render_text_3d : Void
      cmds = DebugDraw.queue.text_3d

      # Grow label pool if needed
      while @label3d_pool.size < cmds.size
        lbl = Godot.create(Godot::Label3D)
        lbl.set_billboard_mode(Godot::BaseMaterial3D::BillboardMode::BillboardEnabled.to_i64)
        lbl.set_render_priority(127_i64)
        lbl.set_draw_flag(Godot::Label3D::DrawFlags::FlagDisableDepthTest.to_i64, true)
        lbl.set_font_size(24_i64)
        add_child(lbl)
        @label3d_pool << lbl
      end

      # Update active labels
      cmds.each_with_index do |cmd, idx|
        lbl = @label3d_pool[idx]
        lbl.set_text(cmd.text)
        lbl.set_position(cmd.position)
        lbl.set_modulate(cmd.color)
        lbl.set_draw_flag(Godot::Label3D::DrawFlags::FlagDisableDepthTest.to_i64, cmd.on_top)
        lbl.set_visible(true)
      end

      # Hide unused labels in pool
      (cmds.size...@label3d_pool.size).each do |idx|
        @label3d_pool[idx].set_visible(false)
      end
    end

    private def render_text_2d : Void
      layer = @canvas_layer
      return unless layer

      cmds = DebugDraw.queue.text_2d

      while @label2d_pool.size < cmds.size
        lbl = Godot.create(Godot::Label)
        lbl.set_z_index(4096_i64)
        lbl.set_z_as_relative(false)
        layer.add_child(lbl)
        @label2d_pool << lbl
      end

      cmds.each_with_index do |cmd, idx|
        lbl = @label2d_pool[idx]
        lbl.set_text(cmd.text)
        lbl.set_position(cmd.position)
        lbl.set_modulate(cmd.color)
        lbl.set_visible(true)
      end

      (cmds.size...@label2d_pool.size).each do |idx|
        @label2d_pool[idx].set_visible(false)
      end
    end
  end
end
