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

  def terms_mapping
    @terms_mapping ||= config
  end

  def main_term_mapping
    @main_term_mapping ||= terms_mapping["main_term"]
  end

  def subdivision_term_mapping
    @subdivision_term_mapping ||= terms_mapping["subdivision"]
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
      subdivision_replacement = check_for_replacement_subdivision(term: replacement)

      subdivision_replacement unless subdivision_replacement.empty?
    end.compact.uniq
  end

  # Given a term, check whether there is a suggested replacement. If there is, return
  # it. If there is not, return the term unaltered.
  # @param [String] term
  # @return [String]
  def check_for_replacement(term:)
    separators.each do |separator|
      subterms = term.split(separator)
      replacement = replacement_config_for_main_terms(subterms)
      next unless replacement

      new_terms = replacement_terms(replacement)
      return subterms.drop(new_terms.count)
                     .prepend(new_terms)
                     .join(separator)
    end

    term
  end

  # rubocop:disable Metrics/MethodLength
  def check_for_replacement_subdivision(term:)
    separators.each do |separator|
      next unless term.include?(separator)

      subterms = term.split(separator)
      subterms.each.with_index do |sub_term, index|
        next if index.zero?

        term_config = subdivision_term_mapping[sub_term]
        next unless term_config

        subterms[index] = term_config["replacement"]
      end

      return subterms.join(separator)
    end
    term
  end
  # rubocop:enable Metrics/MethodLength

  private

  def replacement_config_for_main_terms(subterms)
    matching_key = main_term_mapping.keys.find do |term_to_replace|
      term_matches_subterms?(term_to_replace, subterms)
    end
    main_term_mapping[matching_key] if matching_key
  end

  def term_matches_subterms?(term, subterms)
    term_as_array = Array(term)
    term_as_array.count.times.all? do |index|
      term_as_array[index] == subterms[index]
    end
  end

  def replacement_terms(configured_term)
    Array(configured_term["replacement"])
  end

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
