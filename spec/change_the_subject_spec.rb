# frozen_string_literal: true

require "spec_helper"

##
# When our catalog records contain outdated subject headings, we need the ability
# to update them at index time to preferred terms.
RSpec.describe ChangeTheSubject do
  context "with the real configuration" do
    it "suggests a replacement" do
      expect(described_class.check_for_replacement("Illegal aliens")).to eq "Undocumented immigrants"
      expect(described_class.check_for_replacement("Illegal immigration")).to eq "Undocumented immigrants"
      expect(described_class.check_for_replacement("Women illegal aliens")).to eq "Women undocumented immigrants"
      expect(described_class.check_for_replacement("Illegal aliens in literature")).to eq "Undocumented immigrants in literature"
      expect(described_class.check_for_replacement("Children of illegal aliens")).to eq "Children of undocumented immigrants"
      expect(described_class.check_for_replacement("Illegal alien children")).to eq "Undocumented immigrant children"
      expect(described_class.check_for_replacement("Illegal immigration in literature")).to eq "Undocumented immigrants in literature"
      expect(described_class.check_for_replacement("Alien criminals")).to eq "Noncitizen criminals"
      expect(described_class.check_for_replacement("Aliens")).to eq "Noncitizens"
      expect(described_class.check_for_replacement("Aliens in art")).to eq "Noncitizens in art"
      expect(described_class.check_for_replacement("Aliens in literature")).to eq "Noncitizens in literature"
      expect(described_class.check_for_replacement("Aliens in mass media")).to eq "Noncitizens in mass media"
      expect(described_class.check_for_replacement("Church work with aliens")).to eq "Church work with noncitizens"
      expect(described_class.check_for_replacement("Officials and employees, Alien")).to eq "Officials and employees, Noncitizen"
      expect(described_class.check_for_replacement("Aliens (Greek law)")).to eq "Noncitizens (Greek law)"
      expect(described_class.check_for_replacement("Aliens (Roman law)")).to eq "Noncitizens (Roman law)"
      expect(described_class.check_for_replacement("Child slaves")).to eq "Enslaved children"
      expect(described_class.check_for_replacement("Indian slaves")).to eq "Enslaved indigenous peoples"
      expect(described_class.check_for_replacement("Older slaves")).to eq "Enslaved older people"
      expect(described_class.check_for_replacement("Slaves")).to eq "Enslaved persons"
      expect(described_class.check_for_replacement("Women slaves")).to eq "Enslaved women"
      expect(described_class.check_for_replacement("Indians of Central America")).to eq("Indigenous peoples of Central America")
      expect(described_class.check_for_replacement("Indians of North America")).to eq("Indigenous peoples of North America")
    end
  end

  context "with a mocked configuration" do
    let(:fixture_config) { File.join("spec", "fixtures", "change_the_subject.yml") }

    before do
      allow(described_class).to receive(:change_the_subject_config_file).and_return(fixture_config)
    end

    around do |example|
      described_class.remove_instance_variable(:@terms_mapping) if described_class.instance_variables.include?(:@terms_mapping)
      described_class.remove_instance_variable(:@config) if described_class.instance_variables.include?(:@config)
      example.run
      described_class.remove_instance_variable(:@terms_mapping) if described_class.instance_variables.include?(:@terms_mapping)
      described_class.remove_instance_variable(:@config) if described_class.instance_variables.include?(:@config)
    end

    context "a term that has not been replaced" do
      let(:subject_term) { "Daffodils" }

      it "returns the term unchanged" do
        expect(described_class.check_for_replacement(subject_term)).to eq subject_term
      end
    end

    context "an array of subject terms" do
      let(:subject_terms) { ["Illegal aliens", "Workplace safety"] }
      let(:fixed_subject_terms) { ["Undocumented immigrants", "Workplace safety"] }

      it "changes only the subject terms that have been configured" do
        expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
      end
    end

    context "handles empty and nil terms" do
      let(:subject_terms) { ["", nil, "", "Workplace safety"] }
      let(:fixed_subject_terms) { ["Workplace safety"] }

      it "return only non-empty terms" do
        expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
      end
    end

    context "subject terms with subheadings" do
      let(:subject_terms) { ["Illegal aliens—United States.", "Workplace safety"] }
      let(:fixed_subject_terms) { ["Undocumented immigrants—United States.", "Workplace safety"] }

      it "changes subfield a and re-assembles the full subject heading" do
        expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
      end
    end

    context "subject terms with both the original and mapped term" do
      let(:subject_terms) { ["Illegal aliens", "Undocumented immigrants"] }
      let(:fixed_subject_terms) { ["Undocumented immigrants"] }

      it "suggests a replacement" do
        expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
      end
    end

    context "subject terms that have empty replacements" do
      let(:subject_terms) { ["Test term", "Illegal aliens"] }
      let(:fixed_subject_terms) { ["Undocumented immigrants"] }

      it "suggests a replacement" do
        expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
      end
    end

    context "Indigenous studies terms" do
      let(:subject_terms) { ["Indians of North America—Connecticut"] }
      let(:fixed_subject_terms) { ["Indigenous peoples of North America—Connecticut"] }

      it "suggests a replacement" do
        expect(described_class.fix(subject_terms)).to eq fixed_subject_terms
      end
    end
  end
end
