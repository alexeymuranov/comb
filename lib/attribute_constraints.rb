require 'set'

module AttributeConstraints # TESTME
  def self.included(base_class)
    # NOTE: looks like a hack
    base_class.extend ClassMethods if base_class.ancestors.count(self) == 1
  end

  module ClassMethods
    def self.extended(base_class)
      # NOTE: looks like a hack
      base_class.send :initialize_attribute_constraints
    end

    # Callback
    def inherited(child_class)
      child_class.send :initialize_attribute_constraints
      super
    end

    def validator_classes_on(attr)
      @validator_classes_on[attr]
    end

    def attribute_constraints; @attribute_constraints end

    def validator_classes_on; @validator_classes_on end

    def add_attribute_constraints(attribute_constraints)
      @attribute_constraints.merge! attribute_constraints
    end

    def attribute_constraint(attr)
      attribute_constraints[attr]
    end

    private

      def initialize_attribute_constraints
        @attribute_constraints = Hash.new { |hash, attr|
          hash[attr] = Hash.new { |h, c|
            case c
            when :required
              h[c] = validator_classes_on(attr).include?(
                ActiveModel::Validations::PresenceValidator)
            when :allowed_values
              inclusion_validator = validators_on(attr).find { |v|
                v.is_a?(ActiveModel::Validations::InclusionValidator)
              }
              h[c] = inclusion_validator ?
                inclusion_validator.options[:in] : :all
            end
          }
        }
        @validator_classes_on = Hash.new { |hash, attr|
          hash[attr] = validators_on(attr).map(&:class).to_set
        }
      end

  end
end
