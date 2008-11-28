class Fuc::Processer
  module Downloader
    def convert_url(url)
      url
    end

#    def process(url, content, via)
    def process(url_entry)
      download(convert_url(url_entry.url))
      url_entry.checked = true
      url_entry.save
    end
  end

  class ImageDownloader < Fuc::Processer
    NAME = 'ImageDownloader'
    DESCRIPTION = 'download image files url end with [jpg|jpeg|png|gif]'

    include Fuc::Processer::Downloader

    def match(url_entry)
      url_entry.url =~ %r!.*.[jpg|jpeg|png|gif]$!i
    end
  end

  class MusicDownloader < Fuc::Processer
    NAME = 'MusicDownloader'
    DESCRIPTION = 'download music files url end with [mp3]'

    include Fuc::Processer::Downloader

    def match(url_entry)
      url_entry.url =~ %r!.*.mp3!
    end
  end

#  class VideoDownloader < Fuc::Processer
#    include Fuc::Processer::Downloader
#
#    def match(url_entry)
#    end
#  end
end
