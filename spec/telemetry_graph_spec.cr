require "./spec_helper"

describe Diorite::TelemetryGraph do
  it "records samples up to max_samples and evicts oldest" do
    graph = Diorite::TelemetryGraph.new("FPS", max_samples: 5)

    (1..7).each do |v|
      graph.add_sample(v.to_f32)
    end

    graph.samples.size.should eq(5)
    graph.samples.should eq([3.0_f32, 4.0_f32, 5.0_f32, 6.0_f32, 7.0_f32])
    graph.latest_value.should eq(7.0_f32)
  end

  it "builds graph geometry lines for border and data series" do
    graph = Diorite::TelemetryGraph.new("FPS", max_samples: 4, min_val: 0.0_f32, max_val: 100.0_f32)
    graph.add_sample(20.0_f32)
    graph.add_sample(50.0_f32)
    graph.add_sample(80.0_f32)

    lines = [] of Godot::Vector2
    colors = [] of Godot::Color

    graph.build_geometry(lines, colors)

    # 4 border lines (8 verts) + 2 data plot segments (4 verts) = 12 verts
    lines.size.should eq(12)
    colors.size.should eq(12)
  end

  it "handles flat values without division by zero" do
    graph = Diorite::TelemetryGraph.new("Ping", max_samples: 10) # auto-range
    (1..5).each { graph.add_sample(42.0_f32) }

    lines = [] of Godot::Vector2
    colors = [] of Godot::Color
    graph.build_geometry(lines, colors)

    # 4 border lines (8 verts) + 4 data segments (8 verts) = 16 verts
    lines.size.should eq(16)
  end

  it "handles negative and zero-crossing data series with auto-range" do
    graph = Diorite::TelemetryGraph.new("DeltaY", max_samples: 10)
    graph.add_sample(-50.0_f32)
    graph.add_sample(0.0_f32)
    graph.add_sample(50.0_f32)

    lines = [] of Godot::Vector2
    colors = [] of Godot::Color
    graph.build_geometry(lines, colors)

    lines.size.should eq(12)
    graph.latest_value.should eq(50.0_f32)
  end

  it "renders only the border when no data samples exist" do
    graph = Diorite::TelemetryGraph.new("Empty", max_samples: 10)
    lines = [] of Godot::Vector2
    colors = [] of Godot::Color
    graph.build_geometry(lines, colors)

    # Only 4 border lines = 8 verts
    lines.size.should eq(8)
    graph.latest_value.should eq(0.0_f32)
  end
end
