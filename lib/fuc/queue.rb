# -*- coding: utf-8 -*-
module Fuc
  class URLEntry
    DEFAULT_TYPE = 'normal'
    attr_accessor :url, :via, :type

    def initialize(url, via, type=DEFAULT_TYPE)
      @url = url
      @via = via
      @type = type
    end
  end

  class URLQueue
    def initialize
      @slot = {}
      @current_slot = 0
      @host_index = []
    end

    def push(url_entry)
      host = URI.split(url_entry.url)[2]
      @slot[host] = [] if @slot[host].nil?
      @slot[host].push(url_entry)
      unless @host_index.include? host then
        @host_index.push host
      end
    end

    def _pop_one
      host = @host_index[@current_slot]
      url_entry = @slot[host].pop || nil
      @host_index.delete host if url_entry == nil
      @current_slot = (@current_slot < @host_index.length - 1) ? @current_slot + 1 : 0
      url_entry
    end

    # host毎にプロセス分けて並列処理するようなときはhostsとあわせてこっち使う
    def _pop_by_host(host)
      @slot[host].pop
    end

    def pop(*args)
      case args.length
      when 0
        _pop_one
      when 1
        _pop_by_host(args[0])
      end
    end

    def hosts
      @slot.keys
    end
  end

  class URLCache
    FILE_PATH = 'url_queue.dump'

    def initialize
      @@list = []
      @@checked_at = {}
      @@response = {}
      load
    end

    def push(url, response, expire=0)
      if find?(url, expire) then
        @@list.delete url
        @@checked_at.delete url
      end
      @@list.push(url)
      @@checked_at[url] = Time.now
      @@response[url] = response
    end

    def find?(url, expire=0)
      found = @@list.include?(url)
      if expire != 0 then
        (@@checked_at.key?(url)) ? (@@checked_at[url] < expire) ? false : true : false
      else
        found
      end
    end

    def find(url, expire=0)
      if find?(url, expire) then
        @@response[url]
      else
        nil
      end
    end

    def load
      return unless File.file? FILE_PATH

      data = ''
      File.open(FILE_PATH) {|f|
        data = f.read
      }
      tmp = Marshal.load(data)
      @@list = tmp[:list] || []
      @@checked_at = tmp[:checked_at] || {}
    end

    def save
      data = Marshal.dump({:list => @@list, :checked_at => @@checked_at})
      File.open(FILE_PATH, 'w') {|f|
        f.write(data)
      }
    end
  end
end

