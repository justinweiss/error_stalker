require 'will_paginate/view_helpers/link_renderer'

module ErrorStalker
  # +will_paginate+ doesn't have built-in sinatra support, so this
  # LinkRenderer subclass implements the +url+ method to work with
  # sinatra-style request hashes.
  class SinatraLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer
    protected

    # Returns the URL for the given +page+
    def url(page)
      url = @template.request.url
      params = @template.request.params.dup
      if page == 1
        params.delete("page")
      else
        params["page"] = page
      end
      
      @template.request.path + "?" + params.map {|k, v| "#{Rack::Utils.escape(k)}=#{Rack::Utils.escape(v)}"}.join("&")
    end
  end
end

WillPaginate::ViewHelpers.pagination_options[:renderer] = ErrorStalker::SinatraLinkRenderer
