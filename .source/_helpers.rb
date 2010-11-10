module Helpers
  def link_to_unless_current(text, url)
    normalized_url = url.start_with?(?/) ? url : "/#{url}"
    if normalized_url == page.url
      text
    else
      link_to(text, url)
    end
  end
end