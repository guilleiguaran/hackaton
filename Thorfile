ROOT =  File.expand_path(File.dirname(__FILE__) + "/..")
 
class Convert < Thor
  desc "sass", "converts and puts sass in www"
  def sass
    `sass --update #{ROOT}/src/css:#{ROOT}/www/css`
  end

  desc "coffee", "converts and puts coffeescript in www"
  def coffee
    `coffee -o #{ROOT}/www/js -c #{ROOT}/src/js/`
  end

  desc "all", "Convert haml, sass and coffee"
  def all
    invoke :sass
    invoke :coffee
  end

  desc "watch", "Start watchr to convert sass and coffee source as it is modified"
  def watch
    invoke :all
    system "cd #{ROOT} && watchr Watchfile"
  end
end
