# frozen_string_literal: true

require "spec_helper"

##
# When our catalog records contain outdated subject headings, we need the ability
# to update them at index time to preferred terms.
RSpec.describe ChangeTheSubject do
  context "with the real configuration" do
    it "suggests a replacement" do
      expect(described_class.check_for_replacement(term: "Illegal aliens")).to eq "Undocumented immigrants"
      expect(described_class.check_for_replacement(term: "Illegal immigration")).to eq "Undocumented immigrants"
      expect(described_class.check_for_replacement(term: "Women illegal aliens")).to eq "Women undocumented immigrants"
      expect(described_class.check_for_replacement(term: "Illegal aliens in literature")).to eq "Undocumented immigrants in literature"
      expect(described_class.check_for_replacement(term: "Children of illegal aliens")).to eq "Children of undocumented immigrants"
      expect(described_class.check_for_replacement(term: "Illegal alien children")).to eq "Undocumented immigrant children"
      expect(described_class.check_for_replacement(term: "Illegal immigration in literature")).to eq "Undocumented immigrants in literature"
      expect(described_class.check_for_replacement(term: "Alien criminals")).to eq "Noncitizen criminals"
      expect(described_class.check_for_replacement(term: "Aliens")).to eq "Noncitizens"
      expect(described_class.check_for_replacement(term: "Aliens in art")).to eq "Noncitizens in art"
      expect(described_class.check_for_replacement(term: "Aliens in literature")).to eq "Noncitizens in literature"
      expect(described_class.check_for_replacement(term: "Aliens in mass media")).to eq "Noncitizens in mass media"
      expect(described_class.check_for_replacement(term: "Church work with aliens")).to eq "Church work with noncitizens"
      expect(described_class.check_for_replacement(term: "Officials and employees, Alien")).to eq "Officials and employees, Noncitizen"
      expect(described_class.check_for_replacement(term: "Aliens (Greek law)")).to eq "Noncitizens (Greek law)"
      expect(described_class.check_for_replacement(term: "Aliens (Roman law)")).to eq "Noncitizens (Roman law)"
      expect(described_class.check_for_replacement(term: "Child slaves")).to eq "Enslaved children"
      expect(described_class.check_for_replacement(term: "Indian slaves")).to eq "Enslaved Indigenous peoples"
      expect(described_class.check_for_replacement(term: "Older slaves")).to eq "Enslaved older people"
      expect(described_class.check_for_replacement(term: "Slaves")).to eq "Enslaved persons"
      expect(described_class.check_for_replacement(term: "Women slaves")).to eq "Enslaved women"
      expect(described_class.check_for_replacement(term: "East Indians")).to eq("Indians (India)")
      expect(described_class.check_for_replacement(term: "Indians")).to eq("Indigenous peoples of the Western Hemisphere")
      expect(described_class.check_for_replacement(term: "Indians of North America")).to eq("Indigenous peoples of North America")
      expect(described_class.check_for_replacement(term: "Gender identity disorders in adolescence")).to eq("Gender dysphoria in adolescence")
    end
  end

  context "a term that has not been replaced" do
    let(:subject_term) { "Daffodils" }

    it "returns the term unchanged" do
      expect(described_class.check_for_replacement(term: subject_term)).to eq subject_term
    end
  end

  context "an array of subject terms" do
    let(:subject_terms) { ["Illegal aliens", "Workplace safety"] }
    let(:fixed_subject_terms) { ["Undocumented immigrants", "Workplace safety"] }

    it "changes only the subject terms that have been configured" do
      expect(described_class.fix(subject_terms: subject_terms)).to eq fixed_subject_terms
    end
  end

  context "handles empty and nil terms" do
    let(:subject_terms) { ["", nil, "", "Workplace safety"] }
    let(:fixed_subject_terms) { ["Workplace safety"] }

    it "return only non-empty terms" do
      expect(described_class.fix(subject_terms: subject_terms)).to eq fixed_subject_terms
    end
  end

  context "subject terms with subheadings" do
    let(:subject_terms) { ["Illegal aliens—United States.", "Workplace safety"] }
    let(:fixed_subject_terms) { ["Undocumented immigrants—United States.", "Workplace safety"] }

    it "changes subfield a and re-assembles the full subject heading" do
      expect(described_class.fix(subject_terms: subject_terms)).to eq fixed_subject_terms
    end
  end

  context "subject terms with both the original and mapped term" do
    let(:subject_terms) { ["Illegal aliens", "Undocumented immigrants"] }
    let(:fixed_subject_terms) { ["Undocumented immigrants"] }

    it "suggests a replacement" do
      expect(described_class.fix(subject_terms: subject_terms)).to eq fixed_subject_terms
    end
  end

  context "subject terms that have empty replacements" do
    let(:subject_terms) { ["Test term", "Illegal aliens"] }
    let(:fixed_subject_terms) { ["Undocumented immigrants"] }
    let(:fixture_config) { File.join("spec", "fixtures", "change_the_subject.yml") }

    before do
      allow(File).to receive(:join).and_return(fixture_config)
    end

    it "suggests a replacement" do
      expect(described_class.fix(subject_terms: subject_terms)).to eq fixed_subject_terms
    end
  end

  context "with a subject term with a default separator" do
    let(:subject_terms) { ["Indians of North America—Connecticut"] }
    let(:fixed_subject_terms) { ["Indigenous peoples of North America—Connecticut"] }

    it "uses correct separators" do
      expect(described_class.fix(subject_terms: subject_terms)).to eq fixed_subject_terms
    end
  end

  context "with alternate separators" do
    let(:subject_terms) do
      ["Indians of North America || Connecticut",
       "Indians of North America — New York"]
    end
    let(:fixed_subject_terms) { ["Indigenous peoples of North America || Connecticut", "Indigenous peoples of North America — New York"] }

    it "uses correct separators" do
      expect(described_class.fix(subject_terms: subject_terms, separators: [" || ", " — "])).to eq fixed_subject_terms
    end
  end

  context "with an unparseable configuration file" do
    before do
      allow(YAML).to receive(:safe_load).and_raise(StandardError)
    end

    it "raises a ChangeTheSubjectError" do
      expect { described_class.fix(subject_terms: ["term"]) }.to raise_error(ChangeTheSubject::Error, /was found, but could not be parsed/)
    end
  end
end
