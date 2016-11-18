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
        when :exact
          "#{attr} = ?"
        when :array
          "#{attr} = ?"
        else
          "lower(#{attr}) LIKE ?"
        end
      end.join(" OR ")
    end

    def search_terms
      search_attributes.map do |attr|
        case attribute_types[attr].searchable?
        when :exact
          term.downcase
        when :array
          term.downcase
        else
          "%#{term.downcase}%"
        end
      end
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
