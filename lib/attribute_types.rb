module AttributeTypes
  def self.included(base_class)
    # NOTE: looks like a hack
    base_class.extend ClassMethods if base_class.ancestors.count(self) == 1
  end

  module ClassMethods
    def self.extended(base_class)
      # NOTE: looks like a hack
      base_class.send :initialize_attribute_types
    end

    # Callback
    def inherited(child_class)
      child_class.send :initialize_attribute_types
      super
    end

    # Returns standard types (`:string`, `:integer`, etc.) for attributes
    # corresponding to columns by essentially calling
    # `#columns_hash[attribute].type`.
    # Can be extended in subclasses to virtual columns.
    def attribute_types; @attribute_types end

    def add_attribute_types(attribute_types)
      @attribute_types.merge! attribute_types
    end

    def attribute_type(attr)
      attribute_types[attr]
    end

    private

      def initialize_attribute_types
        @attribute_types = Hash.new { |hash, key|
          if col = columns_hash[key.to_s]
            hash[key] = col.type
          end
        }
      end

  end
end
