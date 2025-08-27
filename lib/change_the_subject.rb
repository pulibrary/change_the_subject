# frozen_string_literal: true

require "yaml"

# The creation and management of metadata are not neutral activities.
class ChangeTheSubject
  class Error < StandardError; end

  def self.fix(subject_terms:, separators: nil)
    new(separators: separators).fix(subject_terms: subject_terms)
  end

  def self.check_for_replacement(term:, separators: nil)
    new(separators: separators).check_for_replacement(term: term)
  end

  attr_reader :separators

  def initialize(separators: nil)
    @separators = separators || ["—"]
  end

  def main_term_mapping
    @main_term_mapping ||= config["main_term"]
  end

  def subdivision_term_mapping
    @subdivision_term_mapping ||= config["subdivision"]
  end

  # Given an array of subject terms, replace the ones that need replacing
  # @param [<String>] subject_terms
  # @return [<String>]
  def fix(subject_terms:)
    return [] if subject_terms.nil?

    subject_terms.compact.reject(&:empty?).map do |term|
      replacement = check_for_replacement(term: term)
      replacements = Array(replacement)

      replacements.map do |r|
        subdivision_replacement = check_for_replacement_subdivision(term: r)
        subdivision_replacement unless subdivision_replacement.empty?
      end
    end.flatten.compact.uniq
  end

  # Given a term, check whether there is a suggested replacement. If there is, return
  # it. If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def check_for_replacement(term:)
    results = []
    separators.each do |separator|
      subterms = term.split(separator)
      replacement = replacement_config_for_main_terms(subterms)

      next unless replacement

      new_terms = replacement_terms(replacement)

      results.concat(process_new_terms(subterms, new_terms, separator))
    end

    results_replacement_check(results, term)
  end

  def check_for_replacement_subdivision(term:)
    results = []
    separators.each do |separator|
      sub_terms = term.is_a?(Array) ? term : [term]
      sub_terms.each do |sub_term|
        next unless sub_term.include?(separator)

        results.concat(replace_subdivisions(term: sub_term, separator: separator))
      end
    end
    results_replacement_subdivisions_check(results, term)
  end

  def self.config_yaml
    change_the_subject_erb = ERB.new(File.read(change_the_subject_config_file)).result
    YAML.safe_load(change_the_subject_erb, aliases: true)
  rescue StandardError, SyntaxError => error
    raise Error, "#{change_the_subject_config_file} was found, but could not be parsed. \n#{error.inspect}"
  end

  def self.change_the_subject_config_file
    File.join(File.dirname(__FILE__), "../", "config", "change_the_subject.yml")
  end

  private

  def replace_subdivisions(term:, separator:)
    new_headings = Array(term.split(separator)[0])
    process_subterms(term, separator, new_headings)
    new_headings.compact.uniq
  end

  def process_new_terms(subterms, new_terms, separator)
    return unless new_terms.is_a?(Array)

    subject_term = subterms.drop(1).join(separator)
    new_terms.map { |new_term| subject_term.empty? ? new_term : "#{new_term}#{separator}#{subject_term}" }
  end

  def results_replacement_subdivisions_check(results, term)
    return term if results.empty?

    results.size == 1 ? results.first : results.flatten.uniq
  end

  def results_replacement_check(results, term)
    return term if results.empty?

    results.size == 1 ? results.first : results.uniq
  end

  def process_subterms(term, separator, new_headings)
    term.split(separator).each.with_index do |sub_term, index|
      next if index.zero?

      process_subdivision(sub_term, separator, new_headings)
    end
  end

  def process_subdivision(sub_term, separator, new_headings)
    clean_subterm = sub_term.delete_suffix(".")
    term_config = subdivision_term_mapping[clean_subterm]

    if term_config.nil?
      append_original_subterm(sub_term, separator, new_headings)
    else
      process_replacement(term_config, separator, new_headings)
    end
  end

  def append_original_subterm(sub_term, separator, new_headings)
    new_headings.map! { |heading| "#{heading}#{separator}#{sub_term}" }
  end

  def process_replacement(term_config, separator, new_headings)
    existing_headings = new_headings.dup
    if term_config["replacement"].is_a?(Array)
      handle_multiple_replacements(term_config, separator, existing_headings, new_headings)
    else
      handle_single_replacement(term_config["replacement"], separator, new_headings)
    end
  end

  def handle_multiple_replacements(term_config, separator, existing_headings, new_headings)
    replacements = term_config["replacement"].map do |replacement|
      existing_headings.map { |heading| "#{heading}#{separator}#{replacement}" }
    end
    new_headings.replace(replacements.flatten)
  end

  def handle_single_replacement(replacement, separator, new_headings)
    new_headings.map! { |heading| "#{heading}#{separator}#{replacement}" }
  end

  def replacement_config_for_main_terms(subterms)
    normalized_search = subterms.first&.delete_suffix(".")
    main_term_mapping[normalized_search]
  end

  def replacement_terms(configured_term)
    Array(configured_term["replacement"])
  end

  def config
    @config ||= ChangeTheSubject.config_yaml
  end
end
