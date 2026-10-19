require "./ci_workflow"

module Diorite
  module CI
    # Declarative DSL Layer: Ergonomic builder wrapping AddonWorkflowConfig and WorkflowAuditor.
    class WorkflowBuilder
      @addon_name : String = "diorite"
      @entry_point : String = "src/main.cr"
      @godot_version : String = "4.8-beta1"
      @lapis_ref : String = "4.8-beta1"
      @reusable_workflow : String = "sol-vin/lapis/.github/workflows/build-addon.yml"
      @os_matrix : Array(String) = ["ubuntu-latest", "windows-latest"]
      @run_specs : Bool = true
      @run_headless : Bool = true
      @run_benchmarks : Bool = true

      def addon_name(value : String) : self
        @addon_name = value
        self
      end

      def entry(value : String) : self
        @entry_point = value
        self
      end

      def godot_version(value : String) : self
        @godot_version = value
        self
      end

      def lapis_ref(value : String) : self
        @lapis_ref = value
        self
      end

      def reusable_workflow(value : String) : self
        @reusable_workflow = value
        self
      end

      def platforms(*runners : String) : self
        @os_matrix = runners.to_a
        self
      end

      def run_specs(value : Bool = true) : self
        @run_specs = value
        self
      end

      def run_headless(value : Bool = true) : self
        @run_headless = value
        self
      end

      def run_benchmarks(value : Bool = true) : self
        @run_benchmarks = value
        self
      end

      def build : AddonWorkflowConfig
        AddonWorkflowConfig.new(
          addon_name: @addon_name,
          entry_point: @entry_point,
          godot_version: @godot_version,
          lapis_ref: @lapis_ref,
          reusable_workflow: @reusable_workflow,
          os_matrix: @os_matrix,
          run_specs: @run_specs,
          run_headless: @run_headless,
          run_benchmarks: @run_benchmarks
        )
      end

      def to_yaml : String
        WorkflowAuditor.render_yaml(build)
      end
    end

    # Declarative block DSL for constructing an AddonWorkflowConfig.
    def self.workflow(&block : WorkflowBuilder ->) : AddonWorkflowConfig
      builder = WorkflowBuilder.new
      yield builder
      builder.build
    end
  end
end
