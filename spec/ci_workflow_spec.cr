require "./spec_helper"

describe Diorite::CI do
  it "constructs AddonWorkflowConfig via the Two-Tier Diorite::CI.workflow DSL" do
    cfg = Diorite::CI.workflow do |ci|
      ci.addon_name "diorite"
      ci.entry "src/main.cr"
      ci.godot_version "4.8-dev7"
      ci.lapis_ref "4.8-dev7"
      ci.platforms "ubuntu-latest", "windows-latest"
      ci.run_specs true
      ci.run_headless true
      ci.run_benchmarks true
    end

    cfg.addon_name.should eq("diorite")
    cfg.entry_point.should eq("src/main.cr")
    cfg.godot_version.should eq("4.8-dev7")
    cfg.lapis_ref.should eq("4.8-dev7")
    cfg.uses_target.should eq("sol-vin/lapis/.github/workflows/build-addon.yml@4.8-dev7")
    cfg.valid_lapis_ref?.should be_true
  end

  it "rejects main and master as Lapis target branch references" do
    bad_main = Diorite::CI.workflow { |ci| ci.lapis_ref "main" }
    bad_main.valid_lapis_ref?.should be_false

    bad_master = Diorite::CI.workflow { |ci| ci.lapis_ref "master" }
    bad_master.valid_lapis_ref?.should be_false
  end

  it "verifies .github/workflows/ci.yml adopts template-addon multi-platform CI workflow on 4.8-beta1" do
    wf_path = File.expand_path("../.github/workflows/ci.yml", __DIR__)
    audit = Diorite::CI::WorkflowAuditor.audit_workflow_file(wf_path)

    audit.valid?.should be_true
    audit.uses_ref.should eq("template-addon")
    audit.addon_name.should eq("diorite")
    audit.godot_version.should eq("4.8-beta1")
    audit.lapis_ref.should eq("4.8-beta1")
    audit.errors.should be_empty
  end
end
