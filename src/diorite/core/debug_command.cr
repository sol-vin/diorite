require "./geometry_builder"
require "./telemetry_graph"

module Diorite
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

  enum ShapeKind2D
    Line
    Arrow
    Rect
    Circle
    Points
  end

  class Command3D
    property kind : ShapeKind3D
    property color : Godot::Color
    property duration : Float64
    property remaining_time : Float64
    property on_top : Bool

    # Geometry storage
    property v0 : Godot::Vector3 = Godot::Vector3.new
    property v1 : Godot::Vector3 = Godot::Vector3.new
    property v2 : Godot::Vector3 = Godot::Vector3.new
    property v3 : Godot::Vector3 = Godot::Vector3.new
    property basis : Godot::Basis = Godot::Basis.new
    property f0 : Float32 = 0.0_f32
    property f1 : Float32 = 0.0_f32
    property f2 : Float32 = 0.0_f32
    property f3 : Float32 = 0.0_f32
    property i0 : Int32 = 0
    property i1 : Int32 = 0
    property path : Array(Godot::Vector3)? = nil
    property wireframe : Bool = true

    def initialize(
      @kind : ShapeKind3D,
      @color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      @duration : Float64 = 0.0,
      @on_top : Bool = true
    )
      @remaining_time = @duration
    end

    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  class Command2D
    property kind : ShapeKind2D
    property color : Godot::Color
    property duration : Float64
    property remaining_time : Float64
    property p0 : Godot::Vector2 = Godot::Vector2.new
    property p1 : Godot::Vector2 = Godot::Vector2.new
    property rect : Godot::Rect2 = Godot::Rect2.new
    property f0 : Float32 = 0.0_f32
    property i0 : Int32 = 0
    property filled : Bool = false
    property points : Array(Godot::Vector2)? = nil

    def initialize(
      @kind : ShapeKind2D,
      @color : Godot::Color = Godot::Color.new(1.0_f32, 1.0_f32, 1.0_f32, 1.0_f32),
      @duration : Float64 = 0.0
    )
      @remaining_time = @duration
    end

    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  class TextCommand3D
    property position : Godot::Vector3
    property text : String
    property color : Godot::Color
    property duration : Float64
    property remaining_time : Float64
    property on_top : Bool

    def initialize(@position : Godot::Vector3, @text : String, @color : Godot::Color, @duration : Float64 = 0.0, @on_top : Bool = true)
      @remaining_time = @duration
    end

    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  class TextCommand2D
    property position : Godot::Vector2
    property text : String
    property color : Godot::Color
    property duration : Float64
    property remaining_time : Float64

    def initialize(@position : Godot::Vector2, @text : String, @color : Godot::Color, @duration : Float64 = 0.0)
      @remaining_time = @duration
    end

    def expired? : Bool
      @duration > 0.0 && @remaining_time <= 0.0
    end

    def step(delta : Float64) : Void
      if @duration > 0.0
        @remaining_time -= delta
      end
    end
  end

  class DebugCommandQueue
    getter commands_3d : Array(Command3D) = Array(Command3D).new
    getter commands_2d : Array(Command2D) = Array(Command2D).new
    getter text_3d : Array(TextCommand3D) = Array(TextCommand3D).new
    getter text_2d : Array(TextCommand2D) = Array(TextCommand2D).new
    getter trails : Hash(String, Array(Godot::Vector3)) = Hash(String, Array(Godot::Vector3)).new
    getter telemetry_graphs : Hash(String, TelemetryGraph) = Hash(String, TelemetryGraph).new

    def push_3d(cmd : Command3D) : Void
      @commands_3d << cmd
    end

    def push_2d(cmd : Command2D) : Void
      @commands_2d << cmd
    end

    def push_text_3d(cmd : TextCommand3D) : Void
      @text_3d << cmd
    end

    def push_text_2d(cmd : TextCommand2D) : Void
      @text_2d << cmd
    end

    def update_trail(id : String, pt : Godot::Vector3, max_pts : Int32) : Array(Godot::Vector3)
      arr = (@trails[id] ||= Array(Godot::Vector3).new)
      if arr.size >= max_pts
        arr.shift
      end
      arr << pt
      arr
    end

    def update_graph(title : String, val : Float32, rect : Godot::Rect2, min_val : Float32, max_val : Float32, color : Godot::Color) : TelemetryGraph
      g = (@telemetry_graphs[title] ||= TelemetryGraph.new(title, rect, min_val, max_val, color))
      g.add_sample(val)
      g
    end

    # Advance time on duration commands and purge expired or single-frame items
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

    def clear_all : Void
      @commands_3d.clear
      @commands_2d.clear
      @text_3d.clear
      @text_2d.clear
      @trails.clear
      @telemetry_graphs.clear
    end
  end
end
