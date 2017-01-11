module RZWaveWay
  class Property
    attr_reader :value
    attr_reader :update_time

    def initialize(options)
      @previous_value = @value = options[:value]
      @previous_update_time = @update_time = options[:update_time]
      @read_only = options[:read_only]
    end

    def changed?
      @previous_value != @value
    end

    def read_only?
      @read_only == true
    end

    def save
      @previous_value = @value
      @previous_update_time = @update_time
    end

    def update(value, update_time)
      if @update_time <= update_time
        @update_time = update_time
        if @value != value
          @value = value
          true
        else
          false
        end
      else
        false
      end
    end
  end
end
