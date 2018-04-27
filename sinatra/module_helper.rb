require 'sinatra/base'

module Sinatra
  module CleanViewsCode
    def title(value = nil)
      @title = value || settings.set_title || 'untitle'
    end

    def title_tag
      @head = '<head>'
      @head << "<title>#{@title}</title>"
    end

    def path_to(script)
      case script
      when :jquery then "<script src='/js/jquery-3.3.1.min.js'></script>"
      when :bootstrapjs then "<script src='/js/bootstrap.min.js'></script>"
      else "/js/#{script}.js" # In case there are other js files
      end
    end

    def webfonts(*fonts)
      arr = []
      fonts.each { |elem| arr << elem.gsub(/\s/, '+') }
      @my_fonts = arr.join('|')
      "<link href=\"https://fonts.googleapis.com/css?family=#{@my_fonts}\" rel=\"stylesheet\" />"
    end

    def styles
      a = Dir[File.join(settings.root, 'public/css', '*.css')]
      a.map do |file|
        "<link rel=\"stylesheet\" type=\"text/css\" href=\"../css/#{File.basename(file)}\">"
      end.join
    end
  end

  helpers CleanViewsCode
end
