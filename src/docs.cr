# ==============================================================================
# Lapis::Docs System - Master Index & Navigation Hub
# Auto-generated from docs_src/ by Lapis::Docs::Generator
# ==============================================================================

{% unless flag?(:release) %}
module Lapis
  # The `Lapis::Docs` module is the authoritative technical reference, API manual,
  # and learning system for this project.
  #
  # ## Learning Tracks & Topic Index
  #
  # The documentation is paced into 1 distinct tracks:
  #
  # ### 1. General (`GENERAL`)
  # <table>
  #   <thead>
  #     <tr>
  #       <th>Submodule</th>
  #       <th>Title</th>
  #       <th>Description</th>
  #     </tr>
  #   </thead>
  #   <tbody>
  #     <tr>
  #       <td><code>OVERVIEW</code></td>
  #       <td><strong>Diorite Overview & Getting Started</strong></td>
  #       <td>Diorite is a high-performance 2D and 3D debug drawing plugin and frame DSL for Godot Engine 4.8+ powered by the Lapis Crystal toolchain.</td>
  #     </tr>
  #     <tr>
  #       <td><code>PRIMITIVES</code></td>
  #       <td><strong>Diorite Primitives Reference</strong></td>
  #       <td>Complete guide to all 26 procedural 2D and 3D debug drawing primitives supported by Diorite.</td>
  #     </tr>
  #     <tr>
  #       <td><code>NODES</code></td>
  #       <td><strong>Diorite Scene Node System</strong></td>
  #       <td>Using Diorite's exported Node3D and Node2D classes for in-editor placement and persistent hierarchy visualization.</td>
  #     </tr>
  #     <tr>
  #       <td><code>CHARTING</code></td>
  #       <td><strong>Data Visualization and Charting</strong></td>
  #       <td>Complete guide to 2D and 3D Pie charts, Bar charts, Radial gauges, and multi-series telemetry graphs.</td>
  #     </tr>
  #     <tr>
  #       <td><code>GAME_HELPERS</code></td>
  #       <td><strong>Game Spatial Helpers and UX Controls</strong></td>
  #       <td>Comprehensive guide to swept shape casts, splines, actor cards, channels, transform stacks, and freeze mode.</td>
  #     </tr>
  #     <tr>
  #       <td><code>PIPELINE</code></td>
  #       <td><strong>Diorite Render Architecture & Zero-Alloc Pipeline</strong></td>
  #       <td>Architecture of Diorite's batch renderer, priority layering, immediate meshes, and zero-allocation memory recycling.</td>
  #     </tr>
  #   </tbody>
  # </table>
  #
  module Docs
    # **Quick-Start Commands**: Essential make and CLI commands for building, running, and testing.
    #
    # #### Lapis Quick Start:
    # ```bash
    # lapis doctor     # Diagnose developer environment & dependencies
    # lapis new game   # Scaffold brand new Crystal Godot game
    # make all         # Compile bridge, test suites, examples, and sync
    # make test        # Execute specs, in-editor tool tests, and runtime suites
    # make editor      # Launch test project in Godot Editor
    # make docs        # Build offline HTML documentation site in docs/
    # ```
    def self.topic_01_quick_start : Nil; end

    # **Learning Tracks & Reading Paths**: Curated reading order from beginner to engine architect.
    #
    # #### Structured Learning Tracks
    #
    # ##### 1. General (`GENERAL`)
    # - `GENERAL::OVERVIEW`: **Diorite Overview & Getting Started** &mdash; Diorite is a high-performance 2D and 3D debug drawing plugin and frame DSL for Godot Engine 4.8+ powered by the Lapis Crystal toolchain.
    # - `GENERAL::PRIMITIVES`: **Diorite Primitives Reference** &mdash; Complete guide to all 26 procedural 2D and 3D debug drawing primitives supported by Diorite.
    # - `GENERAL::NODES`: **Diorite Scene Node System** &mdash; Using Diorite's exported Node3D and Node2D classes for in-editor placement and persistent hierarchy visualization.
    # - `GENERAL::CHARTING`: **Data Visualization and Charting** &mdash; Complete guide to 2D and 3D Pie charts, Bar charts, Radial gauges, and multi-series telemetry graphs.
    # - `GENERAL::GAME_HELPERS`: **Game Spatial Helpers and UX Controls** &mdash; Comprehensive guide to swept shape casts, splines, actor cards, channels, transform stacks, and freeze mode.
    # - `GENERAL::PIPELINE`: **Diorite Render Architecture & Zero-Alloc Pipeline** &mdash; Architecture of Diorite's batch renderer, priority layering, immediate meshes, and zero-allocation memory recycling.
    #
    def self.topic_02_reading_paths : Nil; end

    # **Master Table of Contents**: Complete hierarchical topic index.
    #
    # #### Complete Documentation Index
    #
    # ##### `GENERAL`
    # - `GENERAL::OVERVIEW`: **Diorite Overview & Getting Started** &mdash; Diorite is a high-performance 2D and 3D debug drawing plugin and frame DSL for Godot Engine 4.8+ powered by the Lapis Crystal toolchain.
    # - `GENERAL::PRIMITIVES`: **Diorite Primitives Reference** &mdash; Complete guide to all 26 procedural 2D and 3D debug drawing primitives supported by Diorite.
    # - `GENERAL::NODES`: **Diorite Scene Node System** &mdash; Using Diorite's exported Node3D and Node2D classes for in-editor placement and persistent hierarchy visualization.
    # - `GENERAL::CHARTING`: **Data Visualization and Charting** &mdash; Complete guide to 2D and 3D Pie charts, Bar charts, Radial gauges, and multi-series telemetry graphs.
    # - `GENERAL::GAME_HELPERS`: **Game Spatial Helpers and UX Controls** &mdash; Comprehensive guide to swept shape casts, splines, actor cards, channels, transform stacks, and freeze mode.
    # - `GENERAL::PIPELINE`: **Diorite Render Architecture & Zero-Alloc Pipeline** &mdash; Architecture of Diorite's batch renderer, priority layering, immediate meshes, and zero-allocation memory recycling.
    #
    def self.topic_03_table_of_contents : Nil; end

    # :nodoc:
    def self.quick_start : Nil; topic_01_quick_start; end
    # :nodoc:
    def self.reading_paths : Nil; topic_02_reading_paths; end
    # :nodoc:
    def self.table_of_contents : Nil; topic_03_table_of_contents; end

    # The `GENERAL` documentation track contains all core guides, architectural references,
    # and usage manuals for Diorite:
    #
    # - `OVERVIEW`: Getting started and fundamental dual workflow.
    # - `PRIMITIVES`: Comprehensive reference of all 26 procedural 2D and 3D shapes.
    # - `NODES`: Scene tree nodes for in-editor placement.
    # - `CHARTING`: Algorithmic 2D/3D pie charts, bar charts, radial dials, and telemetry graphs.
    # - `GAME_HELPERS`: Swept shape casts, splines, actor cards, channels, and freeze mode.
    # - `PIPELINE`: Zero-allocation batch rendering architecture and render priorities.
    module GENERAL
    end
  end
end

require "./docs/general/overview"
require "./docs/general/primitives"
require "./docs/general/nodes"
require "./docs/general/charting"
require "./docs/general/game_helpers"
require "./docs/general/pipeline"

{% end %}
