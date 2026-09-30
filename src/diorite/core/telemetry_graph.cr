module Diorite
  class TelemetryGraph
    getter title : String
    getter rect : Godot::Rect2
    getter min_val : Float32
    getter max_val : Float32
    getter color : Godot::Color
    getter max_samples : Int32
    getter samples : Array(Float32)

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

    def add_sample(value : Number) : Void
      val = value.to_f32
      if @samples.size >= @max_samples
        @samples.shift
      end
      @samples << val
    end

    def latest_value : Float32
      @samples.empty? ? 0.0_f32 : @samples.last
    end

    # Builds line segments and outline for rendering the 2D graph
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
      
      # Top
      lines_out << Godot::Vector2.new(x0, y0)
      lines_out << Godot::Vector2.new(x1, y0)
      colors_out << border_color; colors_out << border_color
      # Right
      lines_out << Godot::Vector2.new(x1, y0)
      lines_out << Godot::Vector2.new(x1, y1)
      colors_out << border_color; colors_out << border_color
      # Bottom
      lines_out << Godot::Vector2.new(x1, y1)
      lines_out << Godot::Vector2.new(x0, y1)
      colors_out << border_color; colors_out << border_color
      # Left
      lines_out << Godot::Vector2.new(x0, y1)
      lines_out << Godot::Vector2.new(x0, y0)
      colors_out << border_color; colors_out << border_color

      # 2. Data line plot
      return if @samples.size < 2

      range = @max_val - @min_val
      range = 0.0001_f32 if range.abs < 0.00001_f32
      step_x = w / (@max_samples - 1).to_f32

      start_idx = @max_samples - @samples.size

      (0...@samples.size - 1).each do |i|
        v0 = @samples[i]
        v1 = @samples[i + 1]

        t0 = ((v0 - @min_val) / range).clamp(0.0_f32, 1.0_f32)
        t1 = ((v1 - @min_val) / range).clamp(0.0_f32, 1.0_f32)

        px0 = x0 + (start_idx + i) * step_x
        py0 = y1 - t0 * h
        px1 = x0 + (start_idx + i + 1) * step_x
        py1 = y1 - t1 * h

        lines_out << Godot::Vector2.new(px0, py0)
        lines_out << Godot::Vector2.new(px1, py1)
        colors_out << @color
        colors_out << @color
      end
    end
  end
end
