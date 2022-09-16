# frozen_string_literal: true

require "yaml"

# The creation and management of metadata are not neutral activities.
class ChangeTheSubject
  class Error < StandardError; end

  def self.fix(subject_terms:, separator: nil)
    new(separator: separator).fix(subject_terms: subject_terms)
  end

  def self.check_for_replacement(term:, separator: nil)
    new(separator: separator).check_for_replacement(term: term)
  end

  attr_reader :separator

  def initialize(separator: nil)
    @separator = separator || "—"
  end

  def terms_mapping
    @terms_mapping ||= config
  end

  # Given an array of subject terms, replace the ones that need replacing
  # @param [<String>] subject_terms
  # @return [<String>]
  def fix(subject_terms:)
    return [] if subject_terms.nil?

    subject_terms = subject_terms.compact.reject(&:empty?)
    return [] if subject_terms.empty? || subject_terms.nil?

    subject_terms.map do |term|
      replacement = check_for_replacement(term: term)
      replacement unless replacement.empty?
    end.compact.uniq
  end

  # Given a term, check whether there is a suggested replacement. If there is, return
  # it. If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def check_for_replacement(term:)
    subterms = term.split(separator)
    subfield_a = subterms.first
    replacement = terms_mapping[subfield_a]
    return term unless replacement

    subterms.delete(subfield_a)
    subterms.prepend(replacement["replacement"])
    subterms.join(separator)
  end

  private

  def config
    @config ||= config_yaml
  end

  def config_yaml
    change_the_subject_erb = ERB.new(File.read(change_the_subject_config_file)).result
    YAML.safe_load(change_the_subject_erb, aliases: true)
  rescue StandardError, SyntaxError => e
    raise Error, "#{change_the_subject_config_file} was found, but could not be parsed. \n#{e.inspect}"
  end

  def change_the_subject_config_file
    File.join(File.dirname(__FILE__), "../", "config", "change_the_subject.yml")
  end
end
