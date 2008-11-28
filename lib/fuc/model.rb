# -*- coding: utf-8 -*-
require 'rubygems'
require 'dm-core'
require 'dm-types'

DataMapper.setup(:default, "sqlite3:///#{Dir.pwd}/fuc.db")

# 他のプロセッサからpost_url(url,... 'storage')したものが保存される
# modelだけ他から使われる可能性おおきいので単独requireできるようにしよう
module Fuc; end
#module Fuc::Model
  def setup_model
    DataMapper.auto_migrate!
#    Entry.auto_migrate!
#    Tag.auto_migrate!
#    Bundle.auto_migrate!
  end

  class Entry
    include DataMapper::Resource
    include DataMapper::Types

    property :id, Serial
    property :url, String
    property :via_url, String
    property :summary, Text
    property :body, Object #=>URLCacheのresponseみたいな使い方,
    property :checked, Boolean, :default => false
    property :created_at, DateTime, :default => Proc.new {|r,p| DateTime.now}

    has n, :tags, :through => Resource

    def should_crawl?
      !self.checked || self.created_at.to_time < DateTime.now.to_time - 10 * 60
    end
  end

  class Tag
    include DataMapper::Resource
    include DataMapper::Types
    
    property :id, Serial
    property :title, String

    has n, :entries, :through => Resource
    has n, :bundles, :through => Resource
  end

  # view, queue(host)
  class Bundle
    include DataMapper::Resource
    include DataMapper::Types

    property :id, Serial
    property :title, String
    
    has n, :tags, :through => Resource
  end
#end

__END__

# 使用例

# 必要なbundle各自作ってそこから取り出すようにする
# push_urlにtagとbundle指定できるようにしないと。
class YourProcesser < Fuc::Processer
  include Fuc::Storage

  def match(url_entry)
    # 例えば[youtube|vimeo]なら
    nil
  end

  def process
    # viewバンドルのvideoタグつけてpush_url
  end
end

# 参照側
require 'fuc-processer-storage'
class Foo
  include Fuc::Storage

  def process_entry
    entry = Entry.find(0)
  end

  # 条件(type)指定してentry取得したいのはどんなときか?
  # - entry数が多くてselect likeでの抽出に時間がかかりそうな場合
  # - 
  def process_entry_by_some_type(type)
    type = Type.find(title => 'type_a')
    type.entries.each do |entry|
      
    end
  end
end
