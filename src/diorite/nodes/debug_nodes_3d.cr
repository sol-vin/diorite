require "lapis"
require "./debug_shape_3d"

module Diorite
  # Node representing an inspector-configurable 3D wireframe bounding box.
  @[Tool]
  node DebugBox3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 0 # Box
      super
    end
  end

  # Node representing an inspector-configurable 3D wireframe sphere.
  @[Tool]
  node DebugSphere3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 1 # Sphere
      super
    end
  end

  # Node representing an inspector-configurable 3D wireframe cylinder.
  @[Tool]
  node DebugCylinder3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 2 # Cylinder
      super
    end
  end

  # Node representing an inspector-configurable 3D wireframe capsule.
  @[Tool]
  node DebugCapsule3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 3 # Capsule
      super
    end
  end

  # Node representing an inspector-configurable 3D line vector.
  @[Tool]
  node DebugLine3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 4 # Line
      super
    end
  end

  # Node representing an inspector-configurable 3D directional arrow with arrowhead.
  @[Tool]
  node DebugArrow3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 5 # Arrow
      super
    end
  end

  # Node representing an inspector-configurable 3-axis position crosshair.
  @[Tool]
  node DebugAxes3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 6 # Gizmo
      super
    end
  end

  # Node representing an inspector-configurable 3D ground reference grid plane.
  @[Tool]
  node DebugGrid3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 7 # Grid
      super
    end
  end

  # Node representing an inspector-configurable 3D sensory vision / detection cone.
  @[Tool]
  node DebugVisionCone3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 9 # VisionCone
      super
    end
  end

  # Node representing an inspector-configurable 3D helical physics spring.
  @[Tool]
  node DebugSpring3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 11 # Spring
      super
    end
  end

  # Node representing an inspector-configurable calibrated distance measurement ruler.
  @[Tool]
  node DebugRuler3D < DebugShape3D do
    def _ready : Void
      self.shape_type = 12 # Ruler
      super
    end
  end
end
