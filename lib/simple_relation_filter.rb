require 'set'

class SimpleRelationFilter
  attr_reader   :model                 # Class
  attr_accessor :filtering_values      # Hash
  attr_accessor :filtering_attributes  # Array

  def initialize(model)
    @model = model
    @filtering_values = {}
    @filtering_attributes = []
  end

  # def update(filtering_values, filtering_attributes = nil)
  #   @filtering_values.update(filtering_values)
  #   @filtering_attributes += filtering_attributes || @filtering_values.keys
  #   @filtering_attributes.uniq!
  # end

  def to_scope

    table_name = @model.table_name

    @filtering_attributes.select { |attr|
      @filtering_values.key?(attr)
    }.reduce(@model.scoped) { |model_scope, attr|

      filtering_value = @filtering_values[attr]

      filtering_column_type = @model.attribute_type(attr)

      column_sql = %'"#{ table_name }"."#{ attr }"'

      case filtering_column_type
      when :string
        case filtering_value
        when Set
          model_scope.where("#{ column_sql } IN (?)", filtering_value)
        else
          model_scope.where("#{ column_sql } LIKE ?", filtering_value)
        end

      when :boolean
        model_scope.where("#{ column_sql } = ?", filtering_value)

      when :integer
        case filtering_value
        when Hash
          new_model_scope = model_scope
          if filtering_value.key?(:min)
            unless filtering_value[:min] == -Float::INFINITY
              new_model_scope =
                model_scope.where("#{ column_sql } >= ?", filtering_value[:min])
            end
          end
          if filtering_value.key?(:max)
            unless filtering_value[:max] == Float::INFINITY
              new_model_scope =
                model_scope.where("#{ column_sql } <= ?", filtering_value[:max])
            end
          end
          new_model_scope
        when Set
          model_scope.where("#{ column_sql } IN (?)", filtering_value)
        when Range
          new_model_scope = model_scope
          unless filtering_value.first == -Float::INFINITY
            new_model_scope =
              model_scope.where("#{ column_sql } >= ?", filtering_value.first)
          end
          unless filtering_value.last == Float::INFINITY
            new_model_scope =
              if filtering_value.exclude_end?
                model_scope.where("#{ column_sql } < ?", filtering_value.last)
              else
                model_scope.where("#{ column_sql } <= ?", filtering_value.last)
              end
          end
          new_model_scope
        else
          model_scope.where("#{ column_sql } = ?", filtering_value)
        end

      when :date
        case filtering_value
        when Hash
          new_model_scope = model_scope
          if filtering_value.key?(:from)
            new_model_scope =
              model_scope.where("#{ column_sql } >= ?", filtering_value[:from])
          end
          if filtering_value.key?(:until)
            new_model_scope =
              model_scope.where("#{ column_sql } <= ?", filtering_value[:until])
          end
          new_model_scope
        when Set
          model_scope.where("#{ column_sql } IN (?)", filtering_value)
        when Range
          new_model_scope = model_scope
          unless filtering_value.first == -Float::INFINITY
            new_model_scope =
              model_scope.where("#{ column_sql } >= ?", filtering_value.first)
          end
          unless filtering_value.last == Float::INFINITY
            new_model_scope =
              if filtering_value.exclude_end?
                model_scope.where("#{ column_sql } < ?", filtering_value.last)
              else
                model_scope.where("#{ column_sql } <= ?", filtering_value.last)
              end
          end
          new_model_scope
        else
          model_scope.where("#{ column_sql } = ?", filtering_value)
        end
      else
        model_scope
      end
    }
  end

  def filtering_values_as_simple_nested_hash

    @filtering_attributes.select { |attr|
      @filtering_values.key?(attr)
    }.reduce({}) { |hash, attr|

      filtering_value = @filtering_values[attr]

      filtering_column_type = @model.attribute_type(attr)

      case filtering_column_type
      when :string
        case filtering_value
        when Set
          hash[attr] = filtering_value.to_a
        else
          hash[attr] = filtering_value
        end

      when :boolean
        hash[attr] = filtering_value

      when :integer
        case filtering_value
        when Hash
          hash[attr] = {}
          if filtering_value.key?(:min)
            unless filtering_value[:min] == -Float::INFINITY
              hash[attr][:min] = filtering_value[:min]
            end
          end
          if filtering_value.key?(:max)
            unless filtering_value[:max] == Float::INFINITY
              hash[attr][:max] = filtering_value[:max]
            end
          end
        when Set
          hash[attr] = filtering_value.to_a
        when Range
          hash[attr] = {}
          unless filtering_value.first == -Float::INFINITY
            hash[attr][:min] = filtering_value.first
          end
          unless filtering_value.last == Float::INFINITY
            hash[attr][:max] = filtering_value.last
          end
        else
          hash[attr] = filtering_value
        end

      when :date
        case filtering_value
        when Hash
          hash[attr] = {}
          if filtering_value.key?(:from)
            hash[attr][:from] = filtering_value[:from]
          end
          if filtering_value.key?(:until)
            hash[attr][:until] = filtering_value[:until]
          end
        when Set
          hash[attr] = filtering_value.to_a
        when Range
          hash[attr] = {}
          unless filtering_value.first == -Float::INFINITY
            hash[attr][:from] = filtering_value.first
          end
          unless filtering_value.last == Float::INFINITY
            hash[attr][:until] = filtering_value.last
          end
        else
          hash[attr] = filtering_value
        end
      end
      hash
    }
  end
end

class FriendlyRelationFilter < SimpleRelationFilter

  def set_filtering_values_from_text_hash(filtering_text_hash)

    self.filtering_values = {}

    filtering_attributes.each do |attr|

      next unless value = filtering_text_hash[attr.to_s]

      case model.attribute_type(attr)
      when :string
        case value
        when Set, Array
          filtering_values[attr] = value.map!(&:to_s).to_set
        else
          unless value.blank?
            filtering_values[attr] = value.sub(/\%*\z/, '%')
          end
        end

      when :boolean
        case value
        when nil
        when true, /\Ayes\z/i, /\Atrue\z/i, /\Ay\z/i, /\At\z/i, 1, '1'
          filtering_values[attr] = true
        when false, /\Ano\z/i, /\Afalse\z/i, /\An\z/i, /\Af\z/i, 0, '0'
          filtering_values[attr] = false
        end

      when :integer
        case value
        when Hash
          minimum = value[:min]
          minimum = minimum.blank? ? nil : minimum.to_i
          maximum = value[:max]
          maximum = maximum.blank? ? nil : maximum.to_i
          if minimum || maximum
            filtering_values[attr] =
              (minimum || -Float::INFINITY)..(maximum || Float::INFINITY)
          end
        when Set, Array
          filtering_values[attr] = value.map!(&:to_i).to_set
        else
          filtering_values[attr] = value.to_i
        end

      when :date
        case value
        when Hash
          start_date = value[:from] || value[:min]
          start_date = start_date.blank? ? nil : start_date.to_date
          end_date = value[:until] || value[:max]
          end_date = end_date.blank? ? nil : end_date.to_date
          if start_date || end_date
            filtering_values[attr] = {}
            filtering_values[attr][:from]  = start_date unless start_date.nil?
            filtering_values[attr][:until] = end_date   unless end_date.nil?
          end
        when Set, Array
          filtering_values[attr] = value.map!(&:to_date).to_set
        else
          filtering_values[attr] = value.to_date
        end
      end
    end
  end
end
