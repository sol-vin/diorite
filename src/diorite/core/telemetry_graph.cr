module Diorite
  # Data buffer for an individual line series within a multi-series `TelemetryGraph`.
  class TelemetrySeries
    # Name or identifier for this series.
    getter name : String

    # Curve line color.
    getter color : Godot::Color

    # Array storing current active history samples in chronological order.
    getter samples : Array(Float32)

    # Creates a new series buffer.
    def initialize(@name : String, @color : Godot::Color, capacity : Int32 = 60)
      @samples = Array(Float32).new(capacity)
    end

    # Appends a new scalar sample to this series, popping the oldest sample if at capacity.
    def add_sample(value : Number, max_samples : Int32) : Void
      val = value.to_f32
      if @samples.size >= max_samples
        @samples.shift
      end
      @samples << val
    end

    # Returns the most recently appended value, or `0.0` if empty.
    def latest_value : Float32
      @samples.empty? ? 0.0_f32 : @samples.last
    end

    # Clears all collected sample history from this series.
    def clear : Void
      @samples.clear
    end
  end

  # Threshold guideline metadata for telemetry visualization.
  struct TelemetryThreshold
    # Scalar value line location.
    property value : Float32

    # Guideline color.
    property color : Godot::Color

    # Optional descriptive label.
    property label : String

    # Creates a new threshold guideline.
    def initialize(@value : Float32, @color : Godot::Color, @label : String = "")
    end
  end

  # High-performance circular buffer and geometry builder for 2D real-time telemetry sparkline graphs.
  #
  # Retains a fixed window of historical samples and transforms them into 2D line primitives
  # and background border outlines inside a designated canvas viewport rectangle.
  #
  # Supports single-series or multi-series telemetry with horizontal threshold limit indicators.
  #
  # ```crystal
  # graph = TelemetryGraph.new("Frametime", Rect2.new(10, 10, 200, 60), min_val: 0.0, max_val: 33.3)
  # graph.add_sample(16.6)
  # graph.add_threshold(16.66_f32, Color.new(1.0, 0.2, 0.2, 0.8), "60 FPS")
  # graph.add_series_sample("Physics", 8.3, Color.new(0.2, 0.6, 1.0))
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

    # Array storing current active history samples in chronological order for the default series.
    getter samples : Array(Float32)

    # Named series dictionary for multi-metric overlay graphs.
    getter series : Hash(String, TelemetrySeries)

    # List of horizontal threshold guidelines.
    getter thresholds : Array(TelemetryThreshold)

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
      @series = Hash(String, TelemetrySeries).new
      @thresholds = Array(TelemetryThreshold).new
    end

    # Appends a new scalar sample *value* to the primary history ring buffer.
    #
    # Automatically discards the oldest sample if the buffer has reached `max_samples`.
    def add_sample(value : Number) : Void
      val = value.to_f32
      if @samples.size >= @max_samples
        @samples.shift
      end
      @samples << val
    end

    # Appends a new scalar sample to a named series, creating the series if it doesn't already exist.
    def add_series_sample(series_name : String, value : Number, series_color : Godot::Color? = nil) : Void
      col = series_color || @color
      s = (@series[series_name] ||= TelemetrySeries.new(series_name, col, @max_samples))
      s.add_sample(value, @max_samples)
    end

    # Adds a horizontal threshold line across the graph.
    def add_threshold(value : Number, color : Godot::Color = Godot::Color.new(1.0_f32, 0.3_f32, 0.3_f32, 0.8_f32), label : String = "") : Void
      @thresholds << TelemetryThreshold.new(value.to_f32, color, label)
    end

    # Returns the most recently appended value on the primary series, or `0.0` if empty.
    def latest_value : Float32
      @samples.empty? ? 0.0_f32 : @samples.last
    end

    # Clears all collected sample history and thresholds from the graph.
    def clear : Void
      @samples.clear
      @series.each_value(&.clear)
      @thresholds.clear
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

      range = (@max_val - @min_val).abs
      range = 0.0001_f32 if range < 0.0001_f32

      # 2. Threshold lines
      @thresholds.each do |th|
        v = th.value.clamp(@min_val, @max_val)
        norm = (v - @min_val) / range
        py = y1 - norm * h
        lines_out << Godot::Vector2.new(x0, py)
        lines_out << Godot::Vector2.new(x1, py)
        colors_out << th.color
        colors_out << th.color
      end

      # 3. Primary sparkline curve
      render_sample_curve(@samples, @color, x0, y1, w, h, range, lines_out, colors_out)

      # 4. Multi-series sparkline curves
      @series.each_value do |s|
        render_sample_curve(s.samples, s.color, x0, y1, w, h, range, lines_out, colors_out)
      end
    end

    private def render_sample_curve(
      curve_samples : Array(Float32),
      curve_color : Godot::Color,
      x0 : Float32,
      y1 : Float32,
      w : Float32,
      h : Float32,
      range : Float32,
      lines_out : Array(Godot::Vector2),
      colors_out : Array(Godot::Color)
    ) : Void
      n = curve_samples.size
      return if n < 2

      dx = w / (@max_samples - 1).to_f32
      start_offset = (@max_samples - n).to_f32 * dx

      (0...n - 1).each do |i|
        vA = curve_samples[i].clamp(@min_val, @max_val)
        vB = curve_samples[i + 1].clamp(@min_val, @max_val)

        normA = (vA - @min_val) / range
        normB = (vB - @min_val) / range

        pxA = x0 + start_offset + i.to_f32 * dx
        pyA = y1 - normA * h
        pxB = x0 + start_offset + (i + 1).to_f32 * dx
        pyB = y1 - normB * h

        lines_out << Godot::Vector2.new(pxA, pyA)
        lines_out << Godot::Vector2.new(pxB, pyB)
        colors_out << curve_color
        colors_out << curve_color
      end
    end
  end
end
