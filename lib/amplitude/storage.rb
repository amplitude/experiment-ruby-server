require 'monitor'
module AmplitudeAnalytics
  # Storage
  class Storage
    include MonitorMixin

    def initialize
      super
    end

    def push(event, delay = 0)
      raise NotImplementedError, 'push method must be implemented in subclasses'
    end

    def pull(batch_size)
      raise NotImplementedError, 'pull method must be implemented in subclasses'
    end

    def pull_all
      raise NotImplementedError, 'pull_all method must be implemented in subclasses'
    end
  end

  # StorageProvider class
  class StorageProvider
    def storage
      raise NotImplementedError, 'get_storage method must be implemented in subclasses'
    end
  end

  # InMemoryStorage class
  class InMemoryStorage < Storage

    attr_accessor :total_events, :ready_queue, :workers, :buffer_data, :monitor

    def initialize
      super
      @total_events = 0
      @buffer_data = []
      @ready_queue = []
      @monitor = Monitor.new
      @buffer_lock_cv = @monitor.new_cond
      @configuration = nil
      @workers = nil
    end

    def lock
      @buffer_lock_cv
    end

    def max_retry
      @configuration.flush_max_retries
    end

    def wait_time
      if @ready_queue.any?
        0
      elsif @buffer_data.any?
        [@buffer_data[0][0] - AmplitudeAnalytics.current_milliseconds, @configuration.flush_interval_millis].min
      else
        @configuration.flush_interval_millis
      end
    end

    def setup(configuration, workers)
      @configuration = configuration
      @workers = workers
    end

    def push(event, delay = 0)
      if event.retry && @total_events >= MAX_BUFFER_CAPACITY
        return false, 'Destination buffer full. Retry temporarily disabled'
      end

      return false, "Event reached max retry times #{max_retry}." if event.retry >= max_retry

      total_delay = delay + retry_delay(event.retry)
      insert_event(total_delay, event)
      @workers.start
      [true, nil]
    end

    def pull(batch_size)
      current_time = AmplitudeAnalytics.current_milliseconds
      synchronize do
        result = @ready_queue.shift(batch_size)
        index = 0
        while index < @buffer_data.length && index < batch_size - result.length &&
          current_time >= @buffer_data[index][0]
          event = @buffer_data[index][1]
          result << event
          index += 1
        end
        @buffer_data.slice!(0, index)
        @total_events -= result.length
        result
      end
    end

    def pull_all
      synchronize do
        result = @ready_queue + @buffer_data.map { |element| element[1] }
        @buffer_data.clear
        @ready_queue.clear
        @total_events = 0
        result
      end
    end

    def insert_event(total_delay, event)
      current_time = AmplitudeAnalytics.current_milliseconds
      synchronize do
        @ready_queue << @buffer_data.shift[1] while @buffer_data.any? && @buffer_data[0][0] <= current_time

        if total_delay == 0
          @ready_queue << event
        else
          time_stamp = current_time + total_delay
          left = 0
          right = @buffer_data.length - 1
          while left <= right
            mid = (left + right) / 2
            if @buffer_data[mid][0] > time_stamp
              right = mid - 1
            else
              left = mid + 1
            end
          end
          @buffer_data.insert(left, [time_stamp, event])
        end

        @total_events += 1

        @buffer_lock_cv.signal if @ready_queue.length >= @configuration.flush_queue_size
      end
    end

    def retry_delay(ret)
      if ret > max_retry
        3200
      elsif ret <= 0
        0
      else
        100 * (2 ** ((ret - 1) / 2))
      end
    end
  end

  # InMemoryStorageProvider class
  class InMemoryStorageProvider < StorageProvider

    def storage
      InMemoryStorage.new
    end
  end
end
