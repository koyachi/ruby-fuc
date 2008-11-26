# -*- coding: utf-8 -*-
module Fuc
  class << self
    cattr_accessor :processers
    self.processers = []

    def register_process(user_class=Processer, force=false, type='normal')
      def _init(cls, force, type)
        return if !force && %w[Fuc::Processer::NotifyURLsVIA].any?{|c| c == cls.name}
        self.processers << cls.new(self)
      end

      if user_class.instance_of? Array then
        user_class.each do |cls|
          _init(cls, force, type)
        end
      else
        _init(user_class, force, type)
      end
    end
  end

  class Processer
    NAME = 'Processer'
    DESCRIPTION = 'generic processer'

    def initialize(crawler)
      setup()
      @crawler = crawler
    end

    def setup
    end

    def match(url_entry)
      false
    end

    def process(url, content, via)
    end

    def self.inherited(subclass)
      Fuc.register_process subclass
    end

    def log(msg)
    end


    def push_urls(*url_entry)
      @crawler.url_queue.push(*url_entry)
    end

    def push_url(url, via_url, via_info, type='normal')
      @crawler.url_queue.push(Fuc::URLEntry.new(url, {:url => via_url, :info => via_info}, type))
    end

    # FIXME ダサッ
    def download(url, savedir='', type='blob')
      ext = (type != 'blob') ? ".#{type}" : File.extname(url) or ''
      filename = ((savedir == '') ? Fuc.work_dir : savedir) + "/#{Digest::MD5.hexdigest(url)}#{ext}"
      print "  download #{url} to #{filename}\n"
      content = open(url).read
      File.open(filename, "w") {|f|
        f.write content
      }
      [filename, content]
    end

    def nokogiri(content)
      Nokogiri::HTML(content)
    end
  end

  class DownloadProcesser < Processer
    NAME = 'DownloadProcesser'
    DESCRIPTION = 'download somethin'

    def self.inherited(subclass)
      Fuc.register_process(subclass, false, 'downloader')
    end
  end

  class ContentExtractProcesser < Processer
    NAME = 'ContentExtractProcesser'
    DESCRIPTION = 'extract html content'

    def match(url_entry)
      url_entry.type == 'cotent_extracter'
    end

    def process(url, content, via)
      # extract main content
    end

    def self.inherited(subclass)
      Fuc.register_process(subclass, false, 'content_extracter')
    end
  end
end
