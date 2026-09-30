require "./spec_helper"

describe Diorite::ChartBuilder do
  it "builds 2D pie chart geometry with outer rims and spokes" do
    slices = [
      Diorite::PieSlice.new("Physics", 60.0_f32, Godot::Color.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32)),
      Diorite::PieSlice.new("Render", 40.0_f32, Godot::Color.new(0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32)),
    ]
    verts = Array(Godot::Vector2).new
    cols = Array(Godot::Color).new

    Diorite::ChartBuilder.build_pie_chart_2d(
      center: Godot::Vector2.new(100.0_f32, 100.0_f32),
      radius: 50.0_f32,
      inner_radius: 0.0_f32,
      slices: slices,
      verts: verts,
      cols: cols
    )

    verts.size.should be > 20
    verts.size.should eq(cols.size)
  end

  it "builds 2D donut chart with inner rim" do
    slices = [
      Diorite::PieSlice.new("A", 50.0_f32, Godot::Color.new(1.0_f32, 1.0_f32, 0.0_f32, 1.0_f32)),
      Diorite::PieSlice.new("B", 50.0_f32, Godot::Color.new(0.0_f32, 1.0_f32, 1.0_f32, 1.0_f32)),
    ]
    verts = Array(Godot::Vector2).new
    cols = Array(Godot::Color).new

    Diorite::ChartBuilder.build_pie_chart_2d(
      center: Godot::Vector2.new(100.0_f32, 100.0_f32),
      radius: 50.0_f32,
      inner_radius: 25.0_f32,
      slices: slices,
      verts: verts,
      cols: cols
    )

    verts.size.should be > 40
    verts.size.should eq(cols.size)
  end

  it "builds 3D pie chart geometry oriented by normal" do
    slices = [
      Diorite::PieSlice.new("Slice1", 10.0_f32, Godot::Color.new(1.0_f32, 0.0_f32, 0.0_f32, 1.0_f32)),
      Diorite::PieSlice.new("Slice2", 20.0_f32, Godot::Color.new(0.0_f32, 0.0_f32, 1.0_f32, 1.0_f32)),
    ]
    verts = Array(Godot::Vector3).new
    cols = Array(Godot::Color).new

    Diorite::ChartBuilder.build_pie_chart_3d(
      center: Godot::Vector3.new(0.0_f32, 2.0_f32, 0.0_f32),
      normal: Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
      radius: 2.0_f32,
      inner_radius: 0.5_f32,
      slices: slices,
      verts: verts,
      cols: cols
    )

    verts.size.should be > 20
    verts.size.should eq(cols.size)
  end

  it "builds 2D vertical and horizontal bar charts" do
    bars = [
      Diorite::BarData.new("Entities", 150.0_f32, Godot::Color.new(0.2_f32, 0.8_f32, 0.2_f32, 1.0_f32)),
      Diorite::BarData.new("Particles", 300.0_f32, Godot::Color.new(0.8_f32, 0.2_f32, 0.2_f32, 1.0_f32)),
    ]
    verts_v = Array(Godot::Vector2).new
    cols_v = Array(Godot::Color).new

    Diorite::ChartBuilder.build_bar_chart_2d(
      rect: Godot::Rect2.new(10.0_f32, 10.0_f32, 200.0_f32, 100.0_f32),
      bars: bars,
      horizontal: false,
      verts: verts_v,
      cols: cols_v
    )

    # 4 lines for axis (2 segments * 2) + 2 bars * 4 edges * 2 vertices = 4 + 16 = 20 vertices
    verts_v.size.should eq(20)

    verts_h = Array(Godot::Vector2).new
    cols_h = Array(Godot::Color).new

    Diorite::ChartBuilder.build_bar_chart_2d(
      rect: Godot::Rect2.new(10.0_f32, 10.0_f32, 200.0_f32, 100.0_f32),
      bars: bars,
      horizontal: true,
      verts: verts_h,
      cols: cols_h
    )

    verts_h.size.should eq(20)
  end

  it "builds 2D and 3D radial gauges" do
    verts_2d = Array(Godot::Vector2).new
    cols_2d = Array(Godot::Color).new

    Diorite::ChartBuilder.build_gauge_2d(
      center: Godot::Vector2.new(150.0_f32, 150.0_f32),
      radius: 40.0_f32,
      value: 65.0_f32,
      min_val: 0.0_f32,
      max_val: 100.0_f32,
      color: Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
      verts: verts_2d,
      cols: cols_2d
    )

    verts_2d.size.should be > 40
    verts_2d.size.should eq(cols_2d.size)

    verts_3d = Array(Godot::Vector3).new
    cols_3d = Array(Godot::Color).new

    Diorite::ChartBuilder.build_gauge_3d(
      center: Godot::Vector3.new(0.0_f32, 1.0_f32, 0.0_f32),
      normal: Godot::Vector3.new(0.0_f32, 0.0_f32, 1.0_f32),
      radius: 1.5_f32,
      value: 80.0_f32,
      min_val: 0.0_f32,
      max_val: 100.0_f32,
      color: Godot::Color.new(0.2_f32, 0.8_f32, 1.0_f32, 1.0_f32),
      verts: verts_3d,
      cols: cols_3d
    )

    verts_3d.size.should be > 40
    verts_3d.size.should eq(cols_3d.size)
  end
end

describe Diorite::TelemetryGraph do
  it "supports multi-series and threshold guidelines" do
    graph = Diorite::TelemetryGraph.new("Performance", Godot::Rect2.new(0.0_f32, 0.0_f32, 100.0_f32, 50.0_f32), 0.0_f32, 100.0_f32)
    graph.add_sample(16.6_f32)
    graph.add_sample(20.0_f32)

    graph.add_series_sample("Physics", 8.3_f32, Godot::Color.new(0.2_f32, 0.5_f32, 1.0_f32, 1.0_f32))
    graph.add_series_sample("Physics", 10.0_f32, Godot::Color.new(0.2_f32, 0.5_f32, 1.0_f32, 1.0_f32))

    graph.add_threshold(16.66_f32, Godot::Color.new(1.0_f32, 0.2_f32, 0.2_f32, 0.8_f32), "60 FPS")

    lines = Array(Godot::Vector2).new
    colors = Array(Godot::Color).new

    graph.build_geometry(lines, colors)

    # 4 border segments (8 verts) + 1 threshold line (2 verts) + 1 primary sparkline segment (2 verts) + 1 series segment (2 verts) = 14 verts
    lines.size.should eq(14)
    lines.size.should eq(colors.size)
  end
end
