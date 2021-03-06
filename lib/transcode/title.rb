module Transcode
  class Title
    # Public: Returns the String id stored in the database
    attr_reader :id

    # Public: Returns the Integer number of the title
    attr_reader :title

    # Public: Returns the Integer length of the title
    attr_reader :duration

    # Public: Returns the String length of title in HH:MM:SS
    attr_reader :timecode

    # Public: Returns the Boolean value of whether or not handbrake thinks this
    # is the feature
    attr_reader :feature

    # Public: Returns the Boolean value of whether or not this has been queued
    attr_accessor :queued

    # Public: Returns the Boolean value of whether or this has been
    # successfully transcoded
    attr_accessor :transcoded

    # Public: Returns the String value of the location of the progress file
    attr_reader :progress_file

    # Public: Returns the Interger value of the percentage completeness of the
    # transcode
    attr_reader :progress

    # Public: Returns an array of blocks belonging to this title
    attr_accessor :blocks

    # Public: Returns a bool of whether or not this title was marked to auto transcode
    attr_accessor :auto_transcode

    # Public: Returns the id of the parent disc
    attr_accessor :disc_id

    # Public: Gets and sets the name of the disc
    attr_accessor :disc_name

    # Public: Gets and sets the name of the disc
    attr_accessor :disc_path

    def initialize(options)
      @id             = options['id']
      @title          = options['title']
      @duration       = options['duration']
      @timecode       = options['timecode']
      @feature        = Transcode.to_bool(options['feature'])
      @queued         = Transcode.to_bool(options['queued'])
      @transcoded     = Transcode.to_bool(options['transcoded'])
      @progress_file  = options['progress_file']
      @progress       = options['progress']
      @blocks         = options['blocks']
      @auto_transcode = options['auto_transcode']
      @disc_id        = options['disc_id']
      @disc_name      = options['disc_name']
      @disc_path      = options['disc_path']
    end

    # Instantiate new title instance from database
    def self.find(id)
      Title.new($redis.hgetall(id))
    end

    def self.find_all(set_id)
      titles = []
      $redis.smembers(set_id).each do |title|
        titles << Title.find(title)
      end
      titles
    end

    def self.initialize_from_string(disc, title)
      options = {}
      options['title']          = title.match(/^([0-9]+):/)[1].to_i
      options['timecode']       = title.match(/\+ duration: (.*)/)[1]
      options['duration']       = timecode_to_seconds(options['timecode'])
      options['feature']        = title.include?('Main Feature')
      options['queued']         = false
      options['transcoded']     = false
      options['progress']       = 0
      options['blocks']         = title.scan(/([0-9]+) blocks,/).flatten.map{|block| block.to_i }
      options['id']             = "#{disc['id']}:title:#{options['title']}"
      options['disc_id']        = disc['id']
      options['disc_name']      = disc['name']
      options['disc_path']      = disc['path']
      options['auto_transcode'] = nil
      Title.new(options)
    end

    def self.get_titles_from_string(disc, info)
      # split by title and remove first
      info.split(/^\+ title /m)[1..-1].map { |title| initialize_from_string(disc, title) }
    end

    def self.timecode_to_seconds(timecode)
      multipliers = [1, 60, 3600]
      seconds = timecode.split(':').map { |time| time.to_i * multipliers.pop }
      seconds.inject {|sum, n| sum + n }
    end

    def to_a
  	  hash = {}
  	  self.instance_variables.each {|var| hash[var.to_s.delete("@")] = self.instance_variable_get(var) }
      hash.delete('blocks')
  	  hash
    end

    def auto_transcode?
      @auto_transcode && false == @queued
    end

    def save
      $redis.sadd("#{@disc_id}:titles", @id)

      # Add to block set
      $redis.sadd("#{@disc_id}:blocks", "#{@id}:blocks")

      # Add block set
      $redis.sadd("#{@id}:blocks", @blocks)

      $redis.mapped_hmset(@id, self)
    end
  end
end
