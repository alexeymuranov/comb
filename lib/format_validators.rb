class EmailFormatValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    unless value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      object.errors[attribute] <<
        (options[:message] || I18n.t('errors.messages.email_format'))
    end
  end
end

class TelephoneFormatValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    unless value =~ /\A\s*\+?(\d+(\-|\ +))*\d+\s*\z/i
      object.errors[attribute] <<
        (options[:message] || I18n.t('errors.messages.telephone_format'))
    end
  end
end

class URLFormatValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    # TODO: implement a validation if it seems useful
    unless true
      object.errors[attribute] <<
        (options[:message] || I18n.t('errors.messages.url_format'))
    end
  end
end
