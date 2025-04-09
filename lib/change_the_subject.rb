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

    final_terms = subject_terms.compact.reject(&:empty?).map do |term|
      replacement = check_for_replacement(term: term)

      subdivision_replacement = check_for_replacement_subdivision(term: replacement)

      subdivision_replacement unless subdivision_replacement.empty?
    end.compact.uniq
    final_terms.flatten
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

  def check_for_replacement_subdivision(term:)
    separators.each do |separator|
      next unless term.include?(separator)

      return replace_subdivisions(term: term, separator: separator)
    end
    term
  end

  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def replace_subdivisions(term:, separator:)
    new_headings = []
    subterms = term.split(separator)
    main_term = subterms[0]

    subterms.each.with_index do |sub_term, index|
      if index.zero?
        new_headings.append(main_term)
      else
        clean_subterm = sub_term.delete_suffix(".")
        term_config = subdivision_term_mapping[clean_subterm]

        if term_config.nil?
          # Append the clean subterm to all existing headings
          new_headings.map! { |heading| "#{heading}#{separator}#{clean_subterm}" }
        else
          existing_headings = new_headings.dup

          if term_config["replacement"].is_a?(Array)
            # Handle multiple replacements
            replacements = term_config["replacement"].map do |replacement|
              # rubocop:disable Metrics/BlockNesting
              if term_config["replacement"].include?(existing_headings.join)
                existing_headings.map { |_heading| replacement }
              else
                existing_headings.map { |heading| "#{heading}#{separator}#{replacement}" }
              end
              # rubocop:enable Metrics/BlockNesting
            end
            new_headings = replacements.flatten
          else
            # Handle single replacement
            replacement = term_config["replacement"]
            new_headings.map! { |heading| "#{heading}#{separator}#{replacement}" }
          end
        end
      end
    end

    new_headings.compact.uniq
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

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

  def replacement_config_for_main_terms(subterms)
    matching_key = main_term_mapping.keys.find do |term_to_replace|
      term_matches_subterms?(term_to_replace, subterms)
    end
    main_term_mapping[matching_key] if matching_key
  end

  def term_matches_subterms?(term, subterms)
    term_as_array = Array(term)
    term_as_array.count.times.all? do |index|
      clean_subterm = subterms[index].delete_suffix(".")
      term_as_array[index] == clean_subterm
    end
  end

  def replacement_terms(configured_term)
    Array(configured_term["replacement"])
  end

  def config
    @config ||= ChangeTheSubject.config_yaml
  end
end
