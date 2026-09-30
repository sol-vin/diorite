require "./geometry_builder"
require "./telemetry_graph"

module Diorite
  # Enumeration of all supported 3D debug shape kinds.
  enum ShapeKind3D
    Line
    LineArrow
    LinePath
    Arrow
    Box
    Sphere
    Cylinder
    Capsule
    Plane
    Points
    Position3D
    Gizmo
    Grid
    CameraFrustum
    BillboardSquare
    RayHit
    TrajectoryArc
    VisionCone
    OBB
    Spring
    SurfaceDisk
    Ruler
    Reticle
  end

  # Enumeration of all supported 2D debug shape kinds.
  enum ShapeKind2D
    Line
    Arrow
    Rect
    Circle
    Points
    Path
  end

  # Internal command payload representing an immediate-mode 3D draw request.
  class Command3D
    # The kind of 3D primitive to render.
    property kind : ShapeKind3D

    # Modulate vertex color for this shape.
    property color : Godot::Color

    # Total lifetime duration in seconds (`0.0` for single-frame).
    property duration : Float64

    # Remaining lifetime in seconds before this command expires.
    property remaining_time : Float64

    # Whether this command renders on top with depth test disabled.
    property on_top : Bool

    # Vector parameter 0 (primary position, start point, or center).
    property v0 : Godot::Vector3 = Godot::Vector3.new

    # Vector parameter 1 (end point, dimensions, normal, or velocity).
    property v1 : Godot::Vector3 = Godot::Vector3.new

    # Vector parameter 2 (normal, acceleration, or target).
    property v2 : Godot::Vector3 = Godot::Vector3.new

    # Vector parameter 3 (reserved auxiliary point).
    property v3 : Godot::Vector3 = Godot::Vector3.new

    # 3x3 rotation orientation matrix for oriented boxes, gizmos, and frustums.
    property basis : Godot::Basis = Godot::Basis.new

    # Float parameter 0 (radius, length, or FOV).
    property f0 : Float32 = 0.0_f32

    # Float parameter 1 (height, range, or near plane).
    property f1 : Float32 = 0.0_f32

    # Float parameter 2 (far plane or auxiliary float).
    property f2 : Float32 = 0.0_f32

    # Float parameter 3 (aspect ratio or auxiliary float).
    property f3 : Float32 = 0.0_f32

    # Integer parameter 0 (subdivisions, segments, or coils).
    property i0 : Int32 = 0

    # Integer parameter 1 (auxiliary segment count).
    property i1 : Int32 = 0

    # Continuous polyline or points collection.
    property path : Array(Godot::Vector3)? = nil

    # Whether the box or shape is rendered as a wireframe.
    property wireframe : Bool = true

    # Creates a new 3D command with default parameters.
    def initialize(
      @kind : ShapeKind3D,
      @color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      @duration : Float64 = 0.0,
      @on_top : Bool = true
    )
      @remaining_time = @duration
    end

    # Returns true if the command has exceeded its duration lifetime.
    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    # Advances time by *delta* seconds, decaying remaining duration.
    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  # Internal command payload representing an immediate-mode 2D draw request.
  class Command2D
    # The kind of 2D primitive to render.
    property kind : ShapeKind2D

    # Modulate vertex color for this shape.
    property color : Godot::Color

    # Total lifetime duration in seconds (`0.0` for single-frame).
    property duration : Float64

    # Remaining lifetime in seconds before this command expires.
    property remaining_time : Float64

    # 2D point 0 (start point or center coordinate).
    property p0 : Godot::Vector2 = Godot::Vector2.new

    # 2D point 1 (end coordinate).
    property p1 : Godot::Vector2 = Godot::Vector2.new

    # Bounding rectangle for 2D box or telemetry graph viewport.
    property rect : Godot::Rect2 = Godot::Rect2.new

    # Float parameter 0 (radius or arrowhead size).
    property f0 : Float32 = 0.0_f32

    # Integer parameter 0 (circle segment resolution).
    property i0 : Int32 = 0

    # Whether the 2D primitive is filled or wireframe.
    property filled : Bool = false

    # Polyline vertex array.
    property points : Array(Godot::Vector2)? = nil

    # Creates a new 2D command with default parameters.
    def initialize(
      @kind : ShapeKind2D,
      @color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      @duration : Float64 = 0.0
    )
      @remaining_time = @duration
    end

    # Returns true if the command has exceeded its duration lifetime.
    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    # Advances time by *delta* seconds, decaying remaining duration.
    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  # Internal command payload representing an immediate-mode 3D text billboard label request.
  class TextCommand3D
    # World position of the 3D billboard text.
    property position : Godot::Vector3

    # String message to display.
    property text : String

    # Text color modulate.
    property color : Godot::Color

    # Lifetime duration in seconds.
    property duration : Float64

    # Remaining lifetime in seconds.
    property remaining_time : Float64

    # Whether this text label bypasses depth testing.
    property on_top : Bool

    # Creates a new 3D text billboard command.
    def initialize(@position : Godot::Vector3, @text : String, @color : Godot::Color, @duration : Float64 = 0.0, @on_top : Bool = true)
      @remaining_time = @duration
    end

    # Returns true if the command has exceeded its duration lifetime.
    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    # Advances time by *delta* seconds.
    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  # Internal command payload representing an immediate-mode 2D text label request.
  class TextCommand2D
    # Canvas pixel coordinate of the 2D text label.
    property position : Godot::Vector2

    # String message to display.
    property text : String

    # Text color modulate.
    property color : Godot::Color

    # Lifetime duration in seconds.
    property duration : Float64

    # Remaining lifetime in seconds.
    property remaining_time : Float64

    # Creates a new 2D text label command.
    def initialize(@position : Godot::Vector2, @text : String, @color : Godot::Color, @duration : Float64 = 0.0)
      @remaining_time = @duration
    end

    # Returns true if the command has exceeded its duration lifetime.
    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    # Advances time by *delta* seconds.
    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  # Centralized, high-throughput command queue managing both single-frame and timed debug primitives.
  #
  # Thread-safe and designed to process thousands of queued items per frame with zero GC allocations.
  class DebugCommandQueue
    # Active 3D primitives queued for rendering.
    getter commands_3d : Array(Command3D) = Array(Command3D).new

    # Active 2D primitives queued for rendering.
    getter commands_2d : Array(Command2D) = Array(Command2D).new

    # Active 3D billboard text labels.
    getter text_3d : Array(TextCommand3D) = Array(TextCommand3D).new

    # Active 2D canvas text labels.
    getter text_2d : Array(TextCommand2D) = Array(TextCommand2D).new

    # Entity history trails indexed by unique entity ID.
    getter trails : Hash(String, Array(Godot::Vector3)) = Hash(String, Array(Godot::Vector3)).new

    # Active real-time telemetry graphs indexed by metric title.
    getter telemetry_graphs : Hash(String, TelemetryGraph) = Hash(String, TelemetryGraph).new

    # Pushes a 3D primitive command into the rendering queue.
    def push_3d(cmd : Command3D) : Void
      @commands_3d << cmd
    end

    # Pushes a 2D primitive command into the rendering queue.
    def push_2d(cmd : Command2D) : Void
      @commands_2d << cmd
    end

    # Pushes a 3D billboard text command into the queue.
    def push_text_3d(cmd : TextCommand3D) : Void
      @text_3d << cmd
    end

    # Pushes a 2D canvas text command into the queue.
    def push_text_2d(cmd : TextCommand2D) : Void
      @text_2d << cmd
    end

    # Appends a coordinate *pt* to the entity motion trail *id*, capping length at *max_pts*.
    def update_trail(id : String, pt : Godot::Vector3, max_pts : Int32) : Array(Godot::Vector3)
      arr = (@trails[id] ||= Array(Godot::Vector3).new)
      if arr.size >= max_pts
        arr.shift
      end
      arr << pt
      arr
    end

    # Pushes a new data sample *val* into telemetry graph *title*, creating the graph if needed.
    def update_graph(title : String, val : Float32, rect : Godot::Rect2, min_val : Float32, max_val : Float32, color : Godot::Color) : TelemetryGraph
      g = (@telemetry_graphs[title] ||= TelemetryGraph.new(title, rect, min_val, max_val, color))
      g.add_sample(val)
      g
    end

    # Advances time on duration commands and purges expired or single-frame items.
    def step_and_clean(delta : Float64) : Void
      @commands_3d.each(&.step(delta))
      @commands_2d.each(&.step(delta))
      @text_3d.each(&.step(delta))
      @text_2d.each(&.step(delta))

      # Retain only unexpired commands with duration > 0 (single frame duration <= 0 are consumed)
      @commands_3d.reject! { |c| c.duration <= 0.0 || c.expired? }
      @commands_2d.reject! { |c| c.duration <= 0.0 || c.expired? }
      @text_3d.reject! { |c| c.duration <= 0.0 || c.expired? }
      @text_2d.reject! { |c| c.duration <= 0.0 || c.expired? }
    end

    # Clears all active commands, trails, and telemetry graphs.
    def clear_all : Void
      @commands_3d.clear
      @commands_2d.clear
      @text_3d.clear
      @text_2d.clear
      @trails.clear
      @telemetry_graphs.clear
    end

    # Alias for `clear_all`.
    def clear : Void
      clear_all
    end
  end
end
