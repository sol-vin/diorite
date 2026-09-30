require "lapis"
require "./debug_shape_3d"

module Diorite
  @[Tool]
  node DebugBox3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 0 # Box
      super
    end
  end

  @[Tool]
  node DebugSphere3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 1 # Sphere
      super
    end
  end

  @[Tool]
  node DebugCylinder3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 2 # Cylinder
      super
    end
  end

  @[Tool]
  node DebugCapsule3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 3 # Capsule
      super
    end
  end

  @[Tool]
  node DebugLine3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 4 # Line
      super
    end
  end

  @[Tool]
  node DebugArrow3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 5 # Arrow
      super
    end
  end

  @[Tool]
  node DebugAxes3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 6 # Gizmo
      super
    end
  end

  @[Tool]
  node DebugGrid3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 7 # Grid
      super
    end
  end

  @[Tool]
  node DebugVisionCone3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 9 # VisionCone
      super
    end
  end

  @[Tool]
  node DebugSpring3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 11 # Spring
      super
    end
  end

  @[Tool]
  node DebugRuler3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 12 # Ruler
      super
    end
  end
end
