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

    model_scope = @model.scoped

    table_name = @model.table_name

    @filtering_attributes.each do |attr|

      filtering_value = @filtering_values[attr]

      next if filtering_value.nil?

      column_name = attr.to_s

      filtering_column_type = @model.columns_hash[column_name].type

      column_sql = %'"#{ table_name }"."#{ column_name }"'

      case filtering_column_type
      when :string
        model_scope =
          model_scope.where("UPPER(#{ column_sql }) LIKE ?", filtering_value)

      when :boolean
        model_scope =
          model_scope.where("#{ column_sql } = ?", filtering_value)

      when :integer
        case filtering_value
        when Hash
          if filtering_value.key?(:min)
            unless filtering_value[:min] == -Float::INFINITY
              model_scope =
                model_scope.where("#{ column_sql } >= ?", filtering_value[:min])
            end
          end
          if filtering_value.key?(:max)
            unless filtering_value[:max] == Float::INFINITY
              model_scope =
                model_scope.where("#{ column_sql } <= ?", filtering_value[:max])
            end
          end
        when Set
          model_scope =
            model_scope.where("#{ column_sql } IN (?)", filtering_value)
        when Range
          unless filtering_value.first == -Float::INFINITY
            model_scope =
              model_scope.where("#{ column_sql } >= ?", filtering_value.first)
          end
          unless filtering_value.last == Float::INFINITY
            model_scope =
              if filtering_value.exclude_end?
                model_scope.where("#{ column_sql } < ?", filtering_value.last)
              else
                model_scope.where("#{ column_sql } <= ?", filtering_value.last)
              end
          end
        else
          model_scope =
            model_scope.where("#{ column_sql } = ?", filtering_value)
        end

      when :date
        case filtering_value
        when Hash
          if filtering_value.key?(:from)
            model_scope =
              model_scope.where("#{ column_sql } >= ?", filtering_value[:from])
          end
          if filtering_value.key?(:until)
            model_scope =
              model_scope.where("#{ column_sql } <= ?", filtering_value[:until])
          end
        when Set
          model_scope =
            model_scope.where("#{ column_sql } IN (?)", filtering_value)
        when Range
          unless filtering_value.first == -Float::INFINITY
            model_scope =
              model_scope.where("#{ column_sql } >= ?", filtering_value.first)
          end
          unless filtering_value.last == Float::INFINITY
            model_scope =
              if filtering_value.exclude_end?
                model_scope.where("#{ column_sql } < ?", filtering_value.last)
              else
                model_scope.where("#{ column_sql } <= ?", filtering_value.last)
              end
          end
        else
          model_scope =
            model_scope.where("#{ column_sql } = ?", filtering_value)
        end
      end
    end

    model_scope
  end

  def filtering_attributes_as_simple_nested_hash

    filtering_simple_hash = {}

    @filtering_attributes.each do |attr|

      filtering_value = @filtering_values[attr]

      next if filtering_value.nil?

      filtering_column_type = @model.attribute_type(attr)

      case filtering_column_type
      when :string
        filtering_simple_hash[attr] = filtering_value

      when :boolean
        filtering_simple_hash[attr] = filtering_value

      when :integer
        case filtering_value
        when Hash
          filtering_simple_hash[attr] = {}
          if filtering_value.key?(:min)
            unless filtering_value[:min] == -Float::INFINITY
              filtering_simple_hash[attr][:min] = filtering_value[:min]
            end
          end
          if filtering_value.key?(:max)
            unless filtering_value[:max] == Float::INFINITY
              filtering_simple_hash[attr][:max] = filtering_value[:max]
            end
          end
        when Set
          filtering_simple_hash[attr] = filtering_value.to_a
        when Range
          filtering_simple_hash[attr] = {}
          unless filtering_value.first == -Float::INFINITY
            filtering_simple_hash[attr][:min] = filtering_value.first
          end
          unless filtering_value.last == Float::INFINITY
            filtering_simple_hash[attr][:max] = filtering_value.last
          end
        else
          filtering_simple_hash[attr] = filtering_value
        end

      when :date
        case filtering_value
        when Hash
          filtering_simple_hash[attr] = {}
          if filtering_value.key?(:from)
            filtering_simple_hash[attr][:from] = filtering_value[:from]
          end
          if filtering_value.key?(:until)
            filtering_simple_hash[attr][:until] = filtering_value[:until]
          end
        when Set
          filtering_simple_hash[attr] = filtering_value.to_a
        when Range
          filtering_simple_hash[attr] = {}
          unless filtering_value.first == -Float::INFINITY
            filtering_simple_hash[attr][:from] = filtering_value.first
          end
          unless filtering_value.last == Float::INFINITY
            filtering_simple_hash[attr][:until] = filtering_value.last
          end
        else
          filtering_simple_hash[attr] = filtering_value
        end
      end
    end

    filtering_simple_hash
  end
end

class FriendlyRelationFilter < SimpleRelationFilter

  def set_filtering_values_from_text_hash(filtering_text_hash)

    self.filtering_values = {}

    columns_hash = model.columns_hash

    filtering_attributes.each do |attr|

      next unless (value = filtering_text_hash[attr.to_s]) &&
                  (column = columns_hash[attr.to_s])

      attr = attr.to_sym

      case column.type
      when :string
        unless value.blank?
          filtering_values[attr] =
            value.mb_chars.upcase.to_s.sub(/\%*\z/, '%')
        end

      when :boolean
        unless value.nil?
          case value
          when true, /\Ayes\z/i, /\Atrue\z/i, /\Ay\z/i, /\At\z/i, 1, '1'
            filtering_values[attr] = true
          when false, /\Ano\z/i, /\Afalse\z/i, /\An\z/i, /\Af\z/i, 0, '0'
            filtering_values[attr] = false
          end
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
