require "lapis"
require "./diorite/diorite"
require "./demo/**"

require "./docs"



# Main root node for the Diorite project
@[Tool]
node MainNode < Node3D do
  signal initialized

  def _ready : Void
    Godot.print("==================================================")
    Godot.print("[Diorite] Booting Diorite Debug Draw Showcase")
    Godot.print("==================================================")

    # 1. Ensure DebugDrawManager exists in scene
    unless has_node(Godot::NodePath.new("DebugDrawManager"))
      mgr = Diorite::DebugDrawManager.new
      mgr.set_name("DebugDrawManager")
      add_child(mgr)
      Godot.print("[Diorite] Spawned DebugDrawManager coordinator")
    end

    # 2. Ensure DemoController exists in scene
    unless has_node(Godot::NodePath.new("DemoController"))
      demo = DemoController.new
      demo.set_name("DemoController")
      add_child(demo)
      Godot.print("[Diorite] Spawned DemoController showcase")
    end

    emit_initialized
  end
end
