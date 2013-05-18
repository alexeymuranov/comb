require 'set'
require './lib/format_validators' # custom validator

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

    def add_attribute_constraints(attribute_constraints)
      @attribute_constraints.merge! attribute_constraints
    end

    def attribute_constraints_on(attr)
      @attribute_constraints[attr]
    end

    private

      def initialize_attribute_constraints
        @validator_classes_on = Hash.new { |hash, attr|
          hash[attr] = validators_on(attr).map(&:class).to_set
        }
        @attribute_constraints = Hash.new { |hash, attr|
          h = {}

          h[:required] = validator_classes_on(attr).include?(
                           ActiveModel::Validations::PresenceValidator)
          inclusion_validator = validators_on(attr).find { |v|
            v.is_a?(ActiveModel::Validations::InclusionValidator)
          }

          if validator_classes_on(attr).include?(EmailFormatValidator)
            h[:format] = :email
          elsif validator_classes_on(attr).include?(TelephoneFormatValidator)
            h[:format] = :telephone
          elsif validator_classes_on(attr).include?(URLFormatValidator)
            h[:format] = :url
          end

          inclusion_validator = validators_on(attr).find { |v|
            v.is_a?(ActiveModel::Validations::InclusionValidator)
          }
          if inclusion_validator
            h[:allowed_values] = inclusion_validator.options[:in]
          end

          hash[attr] = h
        }
      end

  end
end
