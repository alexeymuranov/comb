require 'set'

module AttributeMutability # TESTME
  def self.included(base_class)
    # NOTE: looks like a hack
    base_class.extend ClassMethods if base_class.ancestors.count(self) == 1
  end

  module ClassMethods
    def self.extended(base_class)
      # NOTE: looks like a hack
      base_class.send :initialize_attribute_mutability
    end

    # Callback
    def inherited(child_class)
      child_class.send :initialize_attribute_mutability
      super
    end

    def attr_readonly?(attr)
      @attribute_readonly[attr.to_s]
    end

    private

      def initialize_attribute_mutability
        @attribute_readonly = Hash.new { |hash, attr|
          hash[attr] = readonly_attributes.include?(attr.to_s)
        }
      end

  end

  def attr_editable?(attr)
    !self.class.attr_readonly?(attr) || new_record?
  end
end
