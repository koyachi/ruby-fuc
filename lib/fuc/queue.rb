# -*- coding: utf-8 -*-
module Fuc
  class URLQueue
    def initialize
      @current_slot = 0
      @queue = Bundle.first_or_create(:title => 'queue')
      _make_slotid_list
    end

    def _make_slotid_list
      @slot_ids = @queue.tags.map {|t| t.id}
      p @slot_ids
    end

    def _add_slotid(slot)
      @slot_ids.push(slot.id)
    end

    def push(url_entry)
      host = URI.split(url_entry.url.to_s)[2]
      slot = @queue.tags.first(:title => host)
      unless slot then
        p "create Tag #{host}"
        slot = Tag.create(:title => host)
        @queue.tags << slot
        @queue.save
        _add_slotid(slot)
      end
      slot.entries << url_entry
      slot.save
    end

    def _pop_one
      Entry.first(:checked => false)
    end

    # FIXME: 優先度低め Fuc.runのループと合わせて見直し
    def _pop_one_auto
      url_entry = nil
      nil_count = 0
      while url_entry == nil do
        p "@crrent_slot = #{@current_slot}"
        host_name = @queue.tags.get(@slot_ids[@current_slot])
        p host_name
        host = @queue.tags.first(:title => host_name.title)
        url_entry = host.entries.first(:checked => false)
        if url_entry == nil then
          host.destroy
          host.save
          nil_count = nil_count + 1
          if nil_count == @slot_ids.length then
            break
          end
          next
        end
        @current_slot = (@current_slot < @slot_ids.length - 1) ? @current_slot + 1 : 0
      end
      url_entry
    end

    # host毎にプロセス分けて並列処理するようなときはhostsとあわせてこっち使う
    def _pop_by_host(host)
      url_entry = @queue.tags(host).first
      url_entry
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
      @queue.tags.map {|host| host.title}
    end
  end
end

