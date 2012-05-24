module PseudoColumns
  def self.included(base_class)
    # NOTE: looks like a hack
    base_class.extend ClassMethods if base_class.ancestors.count(self) == 1
  end

  module ClassMethods
    def self.extended(base_class)
      # NOTE: looks like a hack
      base_class.send :initialize_pseudo_columns
    end

    # Callback
    def inherited(child_class)
      child_class.send :initialize_pseudo_columns
      super
    end

    # Provides SQL identifiers for attributes corresponding to columns
    # in the standard form "table_name"."column_name".
    # Can be extended in subclasses to include SQL expressions for
    # virtual columns.
    def sql_for_columns; @sql_for_columns end

    def add_pseudo_columns(sql_for_columns)
      @sql_for_columns.merge! sql_for_columns
    end

    def sql_for_column(col)
      sql_for_columns[col]
    end

    # Cannot use `scope` with `lambda` here because `lambda` would bind
    # to the current ... scope (not in the above sense :)), in particular,
    # `self` would be `PseudoColumns` in all descendants.
    def with_pseudo_columns(*attributes)
      attributes.blank? ? scoped : select(with_pseudo_columns_sql(*attributes))
    end

    private

      def initialize_pseudo_columns
        @sql_for_columns = Hash.new { |hash, key|
          if col = columns_hash[key.to_s]
            hash[key] = %("#{ table_name }"."#{ col.name }")
          end
        }
      end

      def pseudo_columns_sql(*attributes)
        attributes.delete_if { |attr| columns_hash[attr.to_s] }
        attributes.map{ |attr|
          "#{ sql_for_columns[attr] } AS #{ attr.to_s }"
        }.join(', ')
      end

      def with_pseudo_columns_sql(*attributes)
        %("#{ table_name }".*, #{ pseudo_columns_sql(*attributes) })
      end

  end
end
