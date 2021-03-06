# encoding: UTF-8
module Transcode
  class Watch
    def start
      FSSM.monitor(Transcode.config.rips, '*', directories: true) do |path|
        path.create do |base, name, type|
          if is_movie_candidate?(name, type)
            Jobs.enqueue_scan(base, name)
          end
        end
        path.update {|base, name, type|}
        path.delete {|base, name, type|}
      end
    end

    def is_movie_candidate?(name, type)
      type.to_s === 'directory' && name.end_with?('.ripit') == false
    end
  end
end
