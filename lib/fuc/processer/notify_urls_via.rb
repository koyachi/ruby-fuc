# -*- coding: utf-8 -*-
class Fuc::Processer
    # url + title + via表示
  class NotifyURLsVIA < Fuc::Processer
    NAME = 'NotifyURLsVIA'
    DESCRIPTION = 'notify url-via information to consol'

    def match(url_entry)
      url_entry.type.split.include? 'notify'
    end

    def process(url, content, via)
      begin
        title = (content.nil?) ? '' : nokogiri(content).xpath('//title')[0].inner_html.strip
      rescue => e
        print "ERROR #{e.message}\n"
        title = ''
      end
      log <<PRINT
  title:   #{title}
  url:     #{url}
  via:     #{via[:url]}
           #{via[:info]}
PRINT
    end
  end
end
