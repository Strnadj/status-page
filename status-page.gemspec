$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'status-page/version'

Gem::Specification.new do |s|
  s.name = 'status-page'
  s.version = StatusPage::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Leonid Beder', 'Jason Lee']
  s.email = ['leonid.beder@gmail.com', 'huacnlee@gmail.com']
  s.license = 'MIT'
  s.homepage = 'https://github.com/rails-engine/status-page'
  s.summary = 'Health monitoring Rails plug-in, which checks various services (db, cache, '\
    'sidekiq, redis, etc.)'
  s.description = 'Health monitoring Rails plug-in, which checks various services (db, cache, '\
    'sidekiq, redis, etc.).'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '>= 4.0'
end
