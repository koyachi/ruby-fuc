# -*- coding: utf-8 -*-
class Fuc::Processer
    # url + title + via表示
  class NotifyURLsVIA < Fuc::Processer
    NAME = 'NotifyURLsVIA'
    DESCRIPTION = 'notify url-via information to consol'

    def match(url_entry)
#      url_entry.type.split.include? 'notify'
      url_entry.tags.first(:title => 'notify')
    end

#    def process(url, content, via)
    def process(url_entry)
      begin
        title = (url_entry.body.nil?) ? '' : nokogiri(url_entry.body).xpath('//title')[0].inner_html.strip
      rescue => e
        print "ERROR #{e.message}\n"
        title = ''
      end
      log <<PRINT
  title:   #{title}
  url:     #{url_entry.url}
  via:     #{url_entry.via_url}
           #{url_entry.summary}
PRINT
    end
  end
end
