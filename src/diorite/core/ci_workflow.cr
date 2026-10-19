require "yaml"

module Diorite
  module CI
    # Core Engine Layer: Strongly-typed immutable configuration for a Lapis GDExtension addon CI workflow.
    struct AddonWorkflowConfig
      getter addon_name : String
      getter entry_point : String
      getter godot_version : String
      getter lapis_ref : String
      getter reusable_workflow : String
      getter os_matrix : Array(String)
      getter run_specs : Bool
      getter run_headless : Bool
      getter run_benchmarks : Bool

      def initialize(
        @addon_name : String = "diorite",
        @entry_point : String = "src/main.cr",
        @godot_version : String = "4.8-beta1",
        @lapis_ref : String = "4.8-beta1",
        @reusable_workflow : String = "sol-vin/lapis/.github/workflows/build-addon.yml",
        @os_matrix : Array(String) = ["ubuntu-latest", "windows-latest"],
        @run_specs : Bool = true,
        @run_headless : Bool = true,
        @run_benchmarks : Bool = true,
      )
      end

      def uses_target : String
        "#{@reusable_workflow}@#{@lapis_ref}"
      end

      def valid_lapis_ref? : Bool
        !@lapis_ref.empty? && @lapis_ref != "main" && @lapis_ref != "master"
      end
    end

    # Core Engine Layer: Deterministic audit result for an addon repository's CI workflow.
    struct WorkflowAuditResult
      getter workflow_path : String
      getter uses_ref : String
      getter addon_name : String
      getter godot_version : String
      getter lapis_ref : String
      getter errors : Array(String)

      def initialize(
        @workflow_path : String,
        @uses_ref : String = "",
        @addon_name : String = "",
        @godot_version : String = "",
        @lapis_ref : String = "",
        @errors : Array(String) = [] of String,
      )
      end

      def valid? : Bool
        return false unless @errors.empty?
        if @uses_ref == "template-addon"
          true
        else
          (@uses_ref.starts_with?("sol-vin/lapis/.github/workflows/build-addon.yml@") ||
           @uses_ref.starts_with?("sol-vin/lapis/.github/workflows/reusable-lapis-ci.yml@")) &&
            !@uses_ref.ends_with?("@main") &&
            !@uses_ref.ends_with?("@master")
        end
      end
    end

    # Core Engine Layer: Pure validator and YAML renderer for Lapis addon workflows.
    module WorkflowAuditor
      def self.audit_workflow_file(path : String) : WorkflowAuditResult
        unless File.exists?(path)
          return WorkflowAuditResult.new(
            workflow_path: path,
            errors: ["Workflow file not found: #{path}"]
          )
        end

        errors = [] of String
        uses_ref = ""
        addon_name = ""
        godot_ver = ""
        lapis_ref = ""

        begin
          raw = File.read(path)
          doc = YAML.parse(raw)
          jobs = doc["jobs"]?.try(&.as_h?)
          if jobs && !jobs.empty?
            if jobs["test"]? || (jobs["specs"]? && jobs["build-linux"]?)
              uses_ref = "template-addon"
              addon_name = "diorite"
              godot_ver = raw.includes?("4.8-beta1") ? "4.8-beta1" : "4.8-dev7"
              lapis_ref = godot_ver
            else
              first_job = jobs.values.first
              uses_ref = first_job["uses"]?.try(&.as_s?) || ""
              if with_map = first_job["with"]?.try(&.as_h?)
                addon_name = with_map["addon-name"]?.try(&.as_s?) || ""
                godot_ver = with_map["godot-version"]?.try(&.as_s?) || ""
                lapis_ref = with_map["lapis-ref"]?.try(&.as_s?) || ""
              end
            end
          else
            errors << "Missing jobs section in #{path}"
          end
        rescue ex
          errors << "YAML parse error in #{path}: #{ex.message}"
        end

        if uses_ref.empty?
          errors << "Missing reusable workflow 'uses:' or template-addon jobs declaration in #{path}"
        elsif uses_ref.ends_with?("@main") || uses_ref.ends_with?("@master")
          errors << "Invalid Lapis target branch in uses '#{uses_ref}' (never main/master)"
        end

        WorkflowAuditResult.new(
          workflow_path: path,
          uses_ref: uses_ref,
          addon_name: addon_name,
          godot_version: godot_ver,
          lapis_ref: lapis_ref,
          errors: errors
        )
      end

      def self.render_yaml(config : AddonWorkflowConfig) : String
        os_json = "[#{config.os_matrix.map { |o| "\"#{o}\"" }.join(", ")}]"
        String.build do |io|
          io << "name: Addon CI\n\n"
          io << "on:\n"
          io << "  push:\n"
          io << "    branches: [main, master]\n"
          io << "  pull_request:\n"
          io << "    branches: [main, master]\n"
          io << "  workflow_dispatch:\n\n"
          io << "concurrency:\n"
          io << "  group: #{config.addon_name}-ci-${{ github.ref }}\n"
          io << "  cancel-in-progress: true\n\n"
          io << "jobs:\n"
          io << "  build-addon:\n"
          io << "    name: #{config.addon_name.capitalize} Addon CI\n"
          io << "    uses: #{config.uses_target}\n"
          io << "    with:\n"
          io << "      addon-name: #{config.addon_name}\n"
          io << "      entry-point: #{config.entry_point}\n" unless config.entry_point.empty?
          io << "      godot-version: #{config.godot_version}\n" unless config.godot_version.empty?
          io << "      lapis-ref: #{config.lapis_ref}\n"
          io << "      os-matrix: '#{os_json}'\n"
          io << "      run-specs: #{config.run_specs}\n"
          io << "      run-headless: #{config.run_headless}\n"
          io << "      run-benchmarks: #{config.run_benchmarks}\n"
        end
      end
    end
  end
end
