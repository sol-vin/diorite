require "lapis"
require "./core/math_helpers"
require "./core/telemetry_graph"
require "./core/geometry_builder"
require "./core/debug_command"
require "./core/chart_builder"
require "./core/frame_arena_batch"
require "./core/debug_material"
require "./core/ci_workflow"
require "./core/ci_dsl"
require "./core/dsl"
require "./nodes/debug_draw_manager"
require "./nodes/debug_shape_3d"
require "./nodes/debug_nodes_3d"
require "./nodes/debug_shape_2d"

# Top-level namespace alias for ergonomics
DebugDraw = Diorite::DebugDraw

# The **Diorite** debug drawing library for Godot Engine 4.8+.
#
# Provides both a node-based scene system and an immediate-mode DSL for
# rendering 2D and 3D debug visualizations with maximum visual priority.
module Diorite
  # Current version of the Diorite debug library.
  VERSION = "0.1.1"
end
