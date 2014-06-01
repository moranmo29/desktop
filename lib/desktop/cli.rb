require 'thor'
require 'uri'
require 'desktop'

module Desktop
  class CLI < Thor
    desc 'set IMAGE_PATH', 'Set all desktops to the image at IMAGE_PATH'
    long_desc <<-LONGDESC
      `desktop set` will set the desktop image of all spaces on all monitors to
      the image at `IMAGE_PATH`.

      > $ desktop set /path/to/image.png

      `IMAGE_PATH` can be a local file path or a URL.

      > $ desktop set http://url.to/image.jpg
    LONGDESC
    option :default_image_path, :hide => true
    option :skip_reload, :type => :boolean, :hide => true
    def set(path, already_failed = false)
      is_uri = begin
        %w[http https].include? URI.parse(path).scheme
      rescue URI::BadURIError, URI::InvalidURIError
        false
      end

      begin
        osx = OSX.new(options[:default_image_path], options[:skip_reload])
        osx.desktop_image = is_uri ? WebImage.new(path) : LocalImage.new(path)
      rescue OSX::DesktopImagePermissionsError => e
        fail(e) if already_failed
        print "It looks like this is the first time you've tried to change "
        puts  "your desktop."
        puts
        print "We need to make your desktop image writable before we can "
        puts  "change it. This only needs to be done once."
        puts
        puts "$ #{OSX.chown_command}"
        puts "$ #{OSX.chmod_command}"
        puts
        osx.update_desktop_image_permissions

        set path, true
      end
    end
  end
end
