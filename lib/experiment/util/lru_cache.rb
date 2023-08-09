module AmplitudeExperiment
  # ListNode
  class ListNode
    attr_accessor :prev, :next, :data

    def initialize(data)
      @prev = nil
      @next = nil
      @data = data
    end
  end

  # CacheItem
  class CacheItem
    attr_accessor :key, :value, :created_at

    def initialize(key, value)
      @key = key
      @value = value
      @created_at = Time.now.to_f * 1000
    end
  end

  # Cache
  class LRUCache
    def initialize(capacity, ttl_millis)
      @capacity = capacity
      @ttl_millis = ttl_millis
      @cache = {}
      @head = nil
      @tail = nil
    end

    def put(key, value)
      if @cache.key?(key)
        remove_from_list(key)
      elsif @cache.size >= @capacity
        evict_lru
      end

      cache_item = CacheItem.new(key, value)
      node = ListNode.new(cache_item)
      @cache[key] = node
      insert_to_list(node)
    end

    def get(key)
      node = @cache[key]
      return nil unless node

      time_elapsed = Time.now.to_f * 1000 - node.data.created_at
      if time_elapsed > @ttl_millis
        remove(key)
        return nil
      end

      remove_from_list(key)
      insert_to_list(node)
      node.data.value
    end

    def remove(key)
      remove_from_list(key)
      @cache.delete(key)
    end

    def clear
      @cache.clear
      @head = nil
      @tail = nil
    end

    private

    def evict_lru
      remove(@head.data.key) if @head
    end

    def remove_from_list(key)
      node = @cache[key]
      return unless node

      if node.prev
        node.prev.next = node.next
      else
        @head = node.next
      end

      if node.next
        node.next.prev = node.prev
      else
        @tail = node.prev
      end
    end

    def insert_to_list(node)
      if @tail
        @tail.next = node
        node.prev = @tail
        node.next = nil
      else
        @head = node
      end
      @tail = node
    end
  end
end
