#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
#
# fuckin' useful crawler
# 2008-11-25 t.koyachi
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'extlib'
require 'net/http'
require 'uri'
require 'tmpdir'
require 'digest/md5'

dir = Pathname(__FILE__).dirname.expand_path / 'fuc'
require dir / 'queue'
require dir / 'processer'
require dir / 'processer' / 'notify_urls_via'
require dir / 'processer' / 'downloader'
require dir / 'processer' / 'webservices'

module Fuc
  VERSION = '0.0.1'

  class << self
    cattr_accessor :work_dir
    self.work_dir = Dir.tmpdir + '/fuc'

    def setup_workdir(dir='')
      self.workdir = dir if dir != ''
      Dir.mkdir(self.work_dir) unless File.directory? self.work_dir
    end

    cattr_accessor :url_queue, :url_cache
    self.url_queue = URLQueue.new
    self.url_cache = URLCache.new

    def run(url)
      setup_workdir
      if url.instance_of? String then
        self.url_queue.push(URLEntry.new(url,
                                         {:url => 'root', :info => ''}))
      elsif url.instance_of? Array then
        url.map {|u|
          self.url_queue.push(URLEntry.new(u,
                                           {:url => 'root', :info => ''}))
        }
      end
      
      while url_entry = self.url_queue.pop() do
        print "%-10s %s\n" % ["pop", url_entry.url]
        expire = (url_entry.via[:url] == 'root') ? Time.now - 10 * 60 : 0
        if self.url_cache.find?(url_entry.url, expire) then
          print "skip\n"
          next
        end

        response = nil
        self.processers.each do |p|
          next unless p.match(url_entry)

          print "%-10s %s\n" % ["process", p.class.name]
          uri_parts = URI.split(url_entry.url)
          host, port, path = uri_parts[2], uri_parts[3],
                             (uri_parts[5] == '') ? '/index.html' : uri_parts[5]
          begin
            response = self.url_cache.find(url_entry.url)
            if response.nil? then
              Net::HTTP.start(host, port) {|http|
                response = http.head(path)
                if response['content-type'] =~ %r!text/html! then
                  response = http.get(path).body
                else
                  response = nil
                end
              }
              self.url_cache.push(url_entry.url, response)
              sleep 1
            end
            result = p.process(url_entry.url, response, url_entry.via)
          rescue Timeout::Error
            print "timeout\n"
          end  
          #break
        end
        print "\n"
      end
      self.url_cache.save
    end

    def output_processer_log(user_class)
      def mixin(cls)
        cls.class_eval <<-MIXIN
          def log(msg)
            print msg + "\n"
          end
        MIXIN
      end
      if user_class.instance_of? Array then
        user_class.each do |cls|
          mixin(cls)
        end
      else
        mixin(user_class)
      end
    end
  end
end

