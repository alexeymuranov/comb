# encoding: UTF-8 (magic comment)

class CTT2013

  private

    def set_locale(locale)
      I18n.locale = @locale = locale
      @other_locales = LOCALES - [@locale]
    end

    def locale
      @locale || DEFAULT_LOCALE
    end

    def set_page(page)
      @page = page
      @base_title = t('base_co_m_b_page_title')
      @title =
        "#{ @base_title } | #{ t(:title, :scope => page_i18n_scope(@page)) }"
    end

    def page
      @page
    end

    # def locale_from_user_input(suggested_locale)
    #   suggested_locale = suggested_locale.to_s.downcase
    #   LOCALES.find{|l| l.to_s == suggested_locale } || DEFAULT_LOCALE
    # end

    # def page_from_user_input(suggested_page)
    #   suggested_page = suggested_page.to_s.downcase
    #   PUBLIC_PAGES.find{|p| p.to_s == suggested_page } || COMB_HOME_PAGE
    # end

end
