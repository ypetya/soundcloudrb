#!/usr/bin/env ruby

PLAYER_TEMPLATE = case
                    when RUBY_PLATFORM =~/linux/
                      "aoss mplayer -msglevel all=-1 -quiet -really-quiet STREAM_URL > /dev/null 2>&1"
                    else
                      "mplayer STREAM_URL"
                    end

require 'rubygems'
# if this fails, run:
# sudo gem install soundcloud-ruby-api-wrapper --no-ri --no-rdoc --source http://gems.github.com
gem 'soundcloud-ruby-api-wrapper'
require 'soundcloud'
require 'mechanize'

class Music
  
  def initialize
    @defaultsearch = ARGV[0] || 'fine-cut-bodies'
    
    @sc_client = Soundcloud.register

    @agent = WWW::Mechanize.new

    the_loop
    puts 'bye'
  end

  # Api documentation:
  # Here => http://wiki.github.com/soundcloud/api/102-resources-tracks 
  def question
    puts <<EOT
Enter search, like : #{@defaultsearch} or just hit enter to start player! 
t search -> track search
u search -> user search
q -> exit! :)
EOT
    search = STDIN.gets.strip
    if search.empty?
      @defaultsearch
    else
      search
    end
  end

  # search query: if there is a leading search by character, use it:
  # u for uer search
  # t for track search
  def get_tracks search
    sa = search.split(' ')

    if sa.size > 1
      case sa.first
      when 'u' 
        sa.shift
        @sc_client.User.find(sa.join('-')).tracks
      when 't'
        sa.shift
        @sc_client.Track.find(:all,:params => { :q => sa.join('-') } )
      else
        @sc_client.Track.find(:all,:params => { :q => sa.join('-')} )
      end
    else
      @sc_client.Track.find(:all,:params => { :q => search } )
    end
  end

  def the_loop
    while search=question and search.downcase != 'q'

      begin
        tracks = get_tracks( search )

        if tracks.length > 0
          
          @page = @agent.get 'http://spreadsheets.google.com/embeddedform?key=tpSZ6ITsuuTeIpCpmjvuxqA'
          # submit to googlf
          form = @page.forms.first
          tomb = search.split(' ')
          tomb.shift
          form.fields.first.value = tomb.join('-')
          @page = @agent.submit(form,form.buttons.first)


          puts "Track count: #{tracks.length}"

          tracks.each do |track|
            puts "#{track.title} @#{track.user.permalink}"
            stream_url = ( track.stream_url rescue next)
            system PLAYER_TEMPLATE.gsub('STREAM_URL'){ stream_url }
          end
        end

      rescue Exception => e
        puts e.message
      end
    end
  end
end

Music.new
