module Diorite
  class DebugMaterialManager
    @@material_on_top : Godot::StandardMaterial3D? = nil
    @@material_depth_tested : Godot::StandardMaterial3D? = nil

    def self.material_on_top : Godot::StandardMaterial3D
      if mat = @@material_on_top
        return mat
      end

      mat = Godot.create(Godot::StandardMaterial3D)
      mat.set_shading_mode(Godot::BaseMaterial3D::ShadingMode::ShadingModeUnshaded.to_i64)
      mat.set_flag(Godot::StandardMaterial3D::Flags::FlagAlbedoFromVertexColor.to_i64, true)
      mat.set_flag(Godot::StandardMaterial3D::Flags::FlagDisableDepthTest.to_i64, true)
      mat.set_render_priority(127_i64)
      mat.set_cull_mode(Godot::BaseMaterial3D::CullMode::CullDisabled.to_i64)
      mat.set_transparency(Godot::BaseMaterial3D::Transparency::TransparencyAlpha.to_i64)

      @@material_on_top = mat
      mat
    end

    def self.material_depth_tested : Godot::StandardMaterial3D
      if mat = @@material_depth_tested
        return mat
      end

      mat = Godot.create(Godot::StandardMaterial3D)
      mat.set_shading_mode(Godot::BaseMaterial3D::ShadingMode::ShadingModeUnshaded.to_i64)
      mat.set_flag(Godot::StandardMaterial3D::Flags::FlagAlbedoFromVertexColor.to_i64, true)
      mat.set_flag(Godot::StandardMaterial3D::Flags::FlagDisableDepthTest.to_i64, false)
      mat.set_render_priority(0_i64)
      mat.set_cull_mode(Godot::BaseMaterial3D::CullMode::CullDisabled.to_i64)
      mat.set_transparency(Godot::BaseMaterial3D::Transparency::TransparencyAlpha.to_i64)

      @@material_depth_tested = mat
      mat
    end
  end
end
