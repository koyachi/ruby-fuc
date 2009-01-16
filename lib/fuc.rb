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
require dir / 'model'
require dir / 'queue'
require dir / 'processer'
require dir / 'processer' / 'notify_urls_via'
require dir / 'processer' / 'downloader'
require dir / 'processer' / 'webservices'

module Fuc
  VERSION = '0.0.3'

  class << self
    cattr_accessor :work_dir
    self.work_dir = Dir.tmpdir + '/fuc'

    def setup_workdir(dir='')
      self.workdir = dir if dir != ''
      Dir.mkdir(self.work_dir) unless File.directory? self.work_dir
    end

    cattr_accessor :url_queue

    def run(url)
      setup_workdir
      # FIXME
      setup_model
      self.url_queue = URLQueue.new

      if url.instance_of? String then
        self.url_queue.push(Entry.new(:url => url))
      elsif url.instance_of? Array then
        url.map {|u|
          self.url_queue.push(Entry.new(:url => u))
        }
      end
      
      while url_entry = self.url_queue.pop() do
        print "%-10s %s\n" % ["pop", url_entry.url]
        now = DateTime.now.to_time
        # FIXME: 直値 -> Config
        expire = (url_entry.via_url.nil?) ? now : now - 10 * 60
        # 前回チェックから一定時間が経っていなければスキップ
        unless url_entry.should_crawl? then
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
            response = url_entry.body
            if response.nil? then
              Net::HTTP.start(host, port) {|http|
                response = http.head(path)
                if response['content-type'] =~ %r!text/html! then
                  response = http.get(path).body
                else
                  response = nil
                end
              }
              url_entry.body = response
              url_entry.save
              sleep 1
            end
            result = p.process(url_entry)
          rescue Timeout::Error
            print "timeout\n"
          end  
          #break
        end
        url_entry.checked = true
        url_entry.save
        print "\n"
      end
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

