# ==============================================================================
# Auto-generated from docs_src by Lapis::Docs::Generator
# ==============================================================================

{% unless flag?(:release) %}
module Lapis
  module Docs
    module GENERAL
      # # Diorite Scene Node System
      #
      # Using Diorite's exported Node3D and Node2D classes for in-editor placement and persistent hierarchy visualization.
      #
      # ## Overview
      #
      # In addition to the immediate-mode Frame DSL, Diorite provides concrete Node classes
      # that integrate directly with Godot's Scene Tree, Inspector, and in-editor gizmo system.
      # Nodes can be added in the Godot Editor or instantiated via code, providing persistent visual indicators
      # that follow spatial parent transformations.
      #
      # ### Key Topics
      #
      # <table>
      #   <thead>
      #     <tr>
      #       <th>Topic</th>
      #       <th>Description</th>
      #     </tr>
      #   </thead>
      #   <tbody>
      #     <tr>
      #       <td><a href="#topic_01_3d_shape_nodes%3ANil-class-method"><strong>3D Shape Nodes</strong></a></td>
      #       <td>DebugLine3D, DebugArrow3D, DebugBox3D, DebugSphere3D, DebugCylinder3D, DebugCapsule3D, DebugVisionCone3D, DebugAxes3D, DebugGrid3D, DebugSpring3D, DebugRuler3D.</td>
      #     </tr>
      #     <tr>
      #       <td><a href="#topic_02_2d_shape_nodes%3ANil-class-method"><strong>2D Shape Nodes</strong></a></td>
      #       <td>DebugLine2D, DebugArrow2D, DebugRect2D, DebugCircle2D.</td>
      #     </tr>
      #   </tbody>
      # </table>
      #
      # ## Code Examples
      #
      # ### Adding a Debug Box to a Scene
      #
      # ```crystal
      # box = Diorite::DebugBox3D.new
      # box.box_size = Godot::Vector3.new(2, 2, 2)
      # box.color = Godot::Color.new(0, 1, 0, 1)
      # box.wireframe = true
      # add_child(box)
      # ```
      #
      # ### Adding a Debug Vision Cone to an AI Actor
      #
      # ```crystal
      # cone = Diorite::DebugVisionCone3D.new
      # cone.cone_angle = 75.0_f32
      # cone.cone_range = 15.0_f32
      # cone.color = Godot::Color.new(1, 0.2, 0.2, 0.8)
      # npc.add_child(cone)
      # ```
      #
      # ## Pitfalls & Best Practices
      #
      # - Always add nodes to the scene tree (`add_child`) so that `_ready` initializes their internal MeshInstance and materials.
      # - Toggling `wireframe` alters the underlying primitive topology; prefer configuring wireframe mode at spawn time.
      #
      # ## Frequently Asked Questions
      #
      # - **Q: Can I inspect and tweak debug node properties in the Godot Editor Inspector?**<br/>
      #   *A:* Yes, all properties (`@box_size`, `@color`, `@cone_angle`, etc.) are exported with `@[Export]` annotations.
      # - **Q: Do node-based shapes persist between frames?**<br/>
      #   *A:* Yes, nodes exist in the scene tree until explicitly removed with `queue_free`.
      module NODES
        # **3D Shape Nodes**: DebugLine3D, DebugArrow3D, DebugBox3D, DebugSphere3D, DebugCylinder3D, DebugCapsule3D, DebugVisionCone3D, DebugAxes3D, DebugGrid3D, DebugSpring3D, DebugRuler3D.
        def self.topic_01_3d_shape_nodes : Nil; end

        # **2D Shape Nodes**: DebugLine2D, DebugArrow2D, DebugRect2D, DebugCircle2D.
        def self.topic_02_2d_shape_nodes : Nil; end

        # **Example: Adding a Debug Box to a Scene**
        #
        # ```crystal
        # box = Diorite::DebugBox3D.new
        # box.box_size = Godot::Vector3.new(2, 2, 2)
        # box.color = Godot::Color.new(0, 1, 0, 1)
        # box.wireframe = true
        # add_child(box)
        # ```
        def self.example_01_adding_debug_box : Nil; end

        # **Example: Adding a Debug Vision Cone to an AI Actor**
        #
        # ```crystal
        # cone = Diorite::DebugVisionCone3D.new
        # cone.cone_angle = 75.0_f32
        # cone.cone_range = 15.0_f32
        # cone.color = Godot::Color.new(1, 0.2, 0.2, 0.8)
        # npc.add_child(cone)
        # ```
        def self.example_02_adding_debug_vision_cone : Nil; end
      end
    end
  end
end
{% end %}
