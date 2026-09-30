# Generated strongly typed wrapper for GDScript node `MyCrystalNode`
# Script Path:
module Godot
  class MyCrystalNode < Godot::Node
    def initialize(pointer : Void* = Pointer(Void).null)
      super(pointer)
    end

    def self.from(node : Godot::Object) : self
      new(node.pointer)
    end

    # Property `my_var` (Godot::Int32?)
    def my_var : Int64
      call_i64("get", "my_var")
    end

    def my_var=(val) : Void
      call("set", "my_var", val)
    end
  end
end

alias MyCrystalNode = Godot::MyCrystalNode
