require "active_support/core_ext/module/delegation"
require "active_support/core_ext/object/blank"

module Administrate
  class Search
    def initialize(resolver, term)
      @resolver = resolver
      @term = term
    end

    def run
      if @term.blank?
        resource_class.all
      else
        resource_class.where(query, *search_terms)
      end
    end

    private

    delegate :resource_class, to: :resolver

    def query
      search_attributes.map do |attr|
        case attribute_types[attr].searchable?
        when :uuid && term_uuid?
          "#{attr} = ?"
        when :array
          "? = any(attr)"
        when true
          "lower(#{attr}) LIKE ?"
        end
      end.compact.join(" OR ")
    end

    def search_terms
      search_attributes.map do |attr|
        case attribute_types[attr].searchable?
        when :uuid && term_uuid?
          term.downcase
        when :array
          term.downcase
        when true
          "%#{term.downcase}%"
        end
      end.compact
    end

    def term_uuid?
      term =~ /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/
    end

    def search_attributes
      attribute_types.keys.select do |attribute|
        attribute_types[attribute].searchable?
      end
    end

    def attribute_types
      resolver.dashboard_class::ATTRIBUTE_TYPES
    end

    attr_reader :resolver, :term
  end
end
