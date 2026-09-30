module Diorite
  # High-performance circular buffer and geometry builder for 2D real-time telemetry sparkline graphs.
  #
  # Retains a fixed window of historical samples and transforms them into 2D line primitives
  # and background border outlines inside a designated canvas viewport rectangle.
  #
  # ```crystal
  # graph = TelemetryGraph.new("Frametime", Rect2.new(10, 10, 200, 60), min_val: 0.0, max_val: 33.3)
  # graph.add_sample(16.6)
  # ```
  class TelemetryGraph
    # Title or metric name displayed above the graph.
    getter title : String

    # 2D screen coordinate bounding rectangle for the graph box.
    getter rect : Godot::Rect2

    # Expected lower value bound for normalization.
    getter min_val : Float32

    # Expected upper value bound for normalization.
    getter max_val : Float32

    # Primary line and border outline color.
    getter color : Godot::Color

    # Maximum historical sample capacity before older values are evicted.
    getter max_samples : Int32

    # Array storing current active history samples in chronological order.
    getter samples : Array(Float32)

    # Creates a new `TelemetryGraph` with the given configuration parameters.
    def initialize(
      @title : String,
      @rect : Godot::Rect2 = Godot::Rect2.new(20.0_f32, 20.0_f32, 160.0_f32, 50.0_f32),
      @min_val : Float32 = 0.0_f32,
      @max_val : Float32 = 100.0_f32,
      @color : Godot::Color = Godot::Color.new(0.2_f32, 0.9_f32, 0.3_f32, 1.0_f32),
      @max_samples : Int32 = 60
    )
      @samples = Array(Float32).new(@max_samples)
    end

    # Appends a new scalar sample *value* to the history ring buffer.
    #
    # Automatically discards the oldest sample if the buffer has reached `max_samples`.
    def add_sample(value : Number) : Void
      val = value.to_f32
      if @samples.size >= @max_samples
        @samples.shift
      end
      @samples << val
    end

    # Returns the most recently appended value, or `0.0` if empty.
    def latest_value : Float32
      @samples.empty? ? 0.0_f32 : @samples.last
    end

    # Clears all collected sample history from the graph.
    def clear : Void
      @samples.clear
    end

    # Builds line segments and background boundary outlines for rendering on the 2D canvas.
    #
    # Appends vertices directly to *lines_out* and corresponding vertex colors to *colors_out*.
    def build_geometry(
      lines_out : Array(Godot::Vector2),
      colors_out : Array(Godot::Color)
    ) : Void
      # 1. Background boundary rectangle lines
      x0 = @rect.position.x
      y0 = @rect.position.y
      w = @rect.size.x
      h = @rect.size.y
      x1 = x0 + w
      y1 = y0 + h

      border_color = Godot::Color.new(0.4_f32, 0.4_f32, 0.4_f32, 0.7_f32)

      # Top border
      lines_out << Godot::Vector2.new(x0, y0)
      lines_out << Godot::Vector2.new(x1, y0)
      colors_out << border_color; colors_out << border_color

      # Right border
      lines_out << Godot::Vector2.new(x1, y0)
      lines_out << Godot::Vector2.new(x1, y1)
      colors_out << border_color; colors_out << border_color

      # Bottom border
      lines_out << Godot::Vector2.new(x1, y1)
      lines_out << Godot::Vector2.new(x0, y1)
      colors_out << border_color; colors_out << border_color

      # Left border
      lines_out << Godot::Vector2.new(x0, y1)
      lines_out << Godot::Vector2.new(x0, y0)
      colors_out << border_color; colors_out << border_color

      # 2. Sparkline curve
      n = @samples.size
      return if n < 2

      range = (@max_val - @min_val).abs
      range = 0.0001_f32 if range < 0.0001_f32

      dx = w / (@max_samples - 1).to_f32
      start_offset = (@max_samples - n).to_f32 * dx

      (0...n - 1).each do |i|
        vA = @samples[i].clamp(@min_val, @max_val)
        vB = @samples[i + 1].clamp(@min_val, @max_val)

        normA = (vA - @min_val) / range
        normB = (vB - @min_val) / range

        pxA = x0 + start_offset + i.to_f32 * dx
        pyA = y1 - normA * h
        pxB = x0 + start_offset + (i + 1).to_f32 * dx
        pyB = y1 - normB * h

        lines_out << Godot::Vector2.new(pxA, pyA)
        lines_out << Godot::Vector2.new(pxB, pyB)
        colors_out << @color
        colors_out << @color
      end
    end
  end
end
