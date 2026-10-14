require "lapis"
require "../core/dsl"
require "../core/debug_material"
require "../core/chart_builder"
require "../core/frame_arena_batch"

module Diorite
  # Central coordinator node managing batch immediate-mode rendering for 2D and 3D debug primitives.
  #
  # Maintains high-priority `ImmediateMesh` instances for 3D on-top and depth-tested passes,
  # a dedicated `CanvasLayer` for 2D geometry, and object pools for 2D/3D billboard labels.
  # Per-frame 2D and 3D vertex and color batches are allocated directly from
  # `Lapis::Core::FrameArena` with zero Boehm GC heap allocations.
  #
  # Add this node to your scene or let `MainNode` spawn it automatically.
  @[Tool]
  node DebugDrawManager < Node do
    # Toggles whether all debug primitives and labels are processed and drawn.
    @[Export]
    property enabled : Bool = true

    # Optional on-screen performance and channel HUD overlay.
    @[Export]
    property show_stats : Bool = false

    @mesh_inst_on_top : Godot::MeshInstance3D? = nil
    @immediate_mesh_on_top : Godot::ImmediateMesh? = nil

    @mesh_inst_depth : Godot::MeshInstance3D? = nil
    @immediate_mesh_depth : Godot::ImmediateMesh? = nil

    @canvas_layer : Godot::CanvasLayer? = nil
    @mesh_inst_2d : Godot::MeshInstance2D? = nil
    @immediate_mesh_2d : Godot::ImmediateMesh? = nil

    @label3d_pool = Array(Godot::Label3D).new
    @label2d_pool = Array(Godot::Label).new

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
      return unless @enabled && DebugDraw.queue.enabled

      start_time = Time.instant

      Lapis::Core::FrameArena.frame do |arena|
        buffers = FrameDrawBuffers.from_arena(arena)
        buffers.compile_queue(DebugDraw.queue)
        flush_3d(buffers)
        flush_2d(buffers)
      end

      render_text_3d
      render_text_2d

      DebugDraw.queue.frame_time_us = (Time.instant - start_time).total_microseconds

      if @show_stats
        render_stats_hud
      end

      DebugDraw.queue.step_and_clean(delta)
    end

    private def render_stats_hud : Void
      v3 = DebugDraw.queue.verts_3d_last_frame
      v2 = DebugDraw.queue.verts_2d_last_frame
      us = DebugDraw.queue.frame_time_us.round(1)
      frozen_str = DebugDraw.queue.frozen? ? " [FROZEN]" : ""
      hud_text = "Diorite#{frozen_str} | 3D Verts: #{v3} | 2D Verts: #{v2} | Render: #{us}µs"
      DebugDraw.text_2d(Godot::Vector2.new(16.0_f32, 16.0_f32), hud_text, Godot::Color.new(0.4_f32, 1.0_f32, 0.4_f32, 1.0_f32))
    end

    @[ZeroAllocation]
    private def flush_3d(buffers : FrameDrawBuffers) : Void
      m_top = @immediate_mesh_on_top
      m_depth = @immediate_mesh_depth
      return unless m_top && m_depth

      verts_top = buffers.verts_top
      cols_top = buffers.cols_top
      verts_depth = buffers.verts_depth
      cols_depth = buffers.cols_depth

      # Flush On-Top ImmediateMesh
      m_top.clear_surfaces
      n_top = verts_top.size
      if n_top > 0
        m_top.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_on_top)
        i = 0
        while i < n_top
          m_top.surface_set_color(cols_top.unsafe_fetch(i))
          m_top.surface_add_vertex(verts_top.unsafe_fetch(i))
          i += 1
        end
        m_top.surface_end
      end

      # Flush Depth-Tested ImmediateMesh
      m_depth.clear_surfaces
      n_depth = verts_depth.size
      if n_depth > 0
        m_depth.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_depth_tested)
        j = 0
        while j < n_depth
          m_depth.surface_set_color(cols_depth.unsafe_fetch(j))
          m_depth.surface_add_vertex(verts_depth.unsafe_fetch(j))
          j += 1
        end
        m_depth.surface_end
      end
    end

    @[ZeroAllocation]
    private def flush_2d(buffers : FrameDrawBuffers) : Void
      m_2d = @immediate_mesh_2d
      return unless m_2d

      verts_2d = buffers.verts_2d
      cols_2d = buffers.cols_2d

      m_2d.clear_surfaces
      n_2d = verts_2d.size
      if n_2d > 0
        m_2d.surface_begin(Godot::Mesh::PrimitiveType::PrimitiveLines.to_i64, DebugMaterialManager.material_on_top)
        i = 0
        while i < n_2d
          m_2d.surface_set_color(cols_2d.unsafe_fetch(i))
          m_2d.surface_add_vertex_2d(verts_2d.unsafe_fetch(i))
          i += 1
        end
        m_2d.surface_end
      end
    end

    private def render_text_3d : Void
      queue = DebugDraw.queue
      cmds = queue.text_3d
      active_idx = 0
      i = 0
      n = cmds.size

      while i < n
        cmd = cmds.unsafe_fetch(i)
        if queue.channel_enabled?(cmd.channel)
          if active_idx >= @label3d_pool.size
            lbl = Godot.create(Godot::Label3D)
            lbl.set_billboard_mode(Godot::BaseMaterial3D::BillboardMode::BillboardEnabled.to_i64)
            lbl.set_render_priority(127_i64)
            lbl.set_draw_flag(Godot::Label3D::DrawFlags::FlagDisableDepthTest.to_i64, true)
            lbl.set_font_size(24_i64)
            add_child(lbl)
            @label3d_pool << lbl
          end

          lbl = @label3d_pool.unsafe_fetch(active_idx)
          lbl.set_text(cmd.text)
          lbl.set_position(cmd.position)
          lbl.set_modulate(cmd.color)
          lbl.set_draw_flag(Godot::Label3D::DrawFlags::FlagDisableDepthTest.to_i64, cmd.on_top)
          lbl.set_visible(true)
          active_idx += 1
        end
        i += 1
      end

      # Hide unused labels in pool
      pool_size = @label3d_pool.size
      while active_idx < pool_size
        @label3d_pool.unsafe_fetch(active_idx).set_visible(false)
        active_idx += 1
      end
    end

    private def render_text_2d : Void
      layer = @canvas_layer
      return unless layer

      queue = DebugDraw.queue
      cmds = queue.text_2d
      active_idx = 0
      i = 0
      n = cmds.size

      while i < n
        cmd = cmds.unsafe_fetch(i)
        if queue.channel_enabled?(cmd.channel)
          if active_idx >= @label2d_pool.size
            lbl = Godot.create(Godot::Label)
            lbl.set_z_index(4096_i64)
            lbl.set_z_as_relative(false)
            layer.add_child(lbl)
            @label2d_pool << lbl
          end

          lbl = @label2d_pool.unsafe_fetch(active_idx)
          lbl.set_text(cmd.text)
          lbl.set_position(cmd.position)
          lbl.set_modulate(cmd.color)
          lbl.set_visible(true)
          active_idx += 1
        end
        i += 1
      end

      pool_size = @label2d_pool.size
      while active_idx < pool_size
        @label2d_pool.unsafe_fetch(active_idx).set_visible(false)
        active_idx += 1
      end
    end
  end
end
