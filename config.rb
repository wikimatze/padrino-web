# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false
page '/guides/*', layout: :guide, data: { sidebar: '/_partials/guides_sidebar' }
page '/blog/*', data: { sidebar: '/_partials/blog_sidebar' }
page '/blog.html', layout: :sidebar, data: { sidebar: '/_partials/blog_sidebar' }
proxy '/guides.html', '/guides/01_introduction/01_overview.html'
proxy '/introduction.html', '/guides/01_introduction/01_overview.html'

require "middleman-core/renderers/redcarpet"

class CustomRenderer < Middleman::Renderers::MiddlemanRedcarpetHTML
  def header(text, header_level)
    "<h%s id=\"%s\">%s</h%s>" % [header_level, text.parameterize, text, header_level]
  end
end

# Helpers
helpers do
  def nav_link_to(link_text, url, options = {})
    root = options.delete(:root)
    is_active = (!root && current_page.url.start_with?(url)) ||
      current_page.url == url
    options[:class] ||= ''
    options[:class] << '--is-active' if is_active
    link_to(link_text, url, options)
  end

  def head_title
    page_title = current_page.data.title
    "Padrino - #{page_title.nil? ? config.default_title : page_title}"
  end

  def recent_release_post
    blog.articles.find { |a| a.tags.include?("release") }
  end

  def guides
    resources = sitemap.resources.select do |r|
      r.path.start_with?('guides/') && !r.path.match(/^guides\/\d{2}_/) &&
      r.path != 'guides/README.html'
    end

    resources.sort_by(&:target)
  end

  def guides_by_chapter
    guides.group_by { |c| c.data.chapter }
  end

  # blog-categories
  def categories(page)
    category_array(page.data[:categories])
  end

  def category_path(category)
    "/category/#{category.parameterize}/index.html"
  end

  def all_categories
    @all_categories ||= Hash[all_categories_unsorted.sort]
  end

  def category_array(categories)
    (categories || "Uncategorized").split(" ")
  end

  private

  def all_categories_unsorted
    Hash.new { [] }.tap do |all_categories|
      blog.articles.each do |article|
        categories(article).each do |ac|
          all_categories[ac] <<= article
        end
      end
    end
  end
end

# General configuration
set :layout, :content
set :css_dir, 'assets/stylesheets'
set :js_dir, 'assets/javascripts'
set :markdown_engine, :redcarpet
set :markdown, :tables => true, :autolink => true, :gh_blockcode => true,
    :fenced_code_blocks => true, renderer: CustomRenderer
set :default_title, 'The Elegant Ruby Web Framework'
set :url_root, 'http://padrinorb.com'

activate :blog,
  prefix: 'blog',
  layout: :blog_article,
  permalink: '{title}.html',
  paginate: true,
  per_page: 2,
  publish_future_dated: true

activate :directory_indexes
activate :syntax, css_class: 'syntax'
activate :search_engine_sitemap,
  exclude_if: -> (resource) {
    # Exclude all paths from sitemap that are sub-date indexes
    resource.path.match(/[0-9]{4}(\/[0-9]{2})*.html/)
    resource.path.match(/category\/*/)
  },
  default_change_frequency: 'weekly'
activate :robots,
  rules: [
    { user_agent: '*', allow: %w(/), disallow: %w(CNAME /*.js /*.css) }
  ],
  sitemap: 'http://padrinorb.com/sitemap.xml'
activate :external_pipeline,
  name: :webpack,
  command: build? ? 'npm run build' : './node_modules/webpack/bin/webpack.js --watch -d',
  source: '.tmp/dist',
  latency: 1
activate :deploy, deploy_method: :git

ready do
  sitemap.resources.select { |r| r.path.start_with?('guides/') }.each do |resource|
    path = resource.path.split('/')

    if path.size >= 3
      chapter = path[1][3..-1]
      title = path[2][3..-1]
      locals = { sidebar: '/_partials/guides_sidebar' }
      proxy "guides/#{chapter}/#{title}", path.join('/'), locals: locals
    end
  end
  sitemap.resources
    .map { |r| (r.data["categories"] || "Uncategorized").split(" ") }
    .flatten
    .uniq
    .each do |category|
    proxy "/category/#{category.parameterize}.html", "category.html", locals: { category: category }
  end
end

# Development-specific configuration
configure :development do
  activate :livereload
  activate :disqus, :shortname => nil
end

ignore 'category.html.slim'

# Build-specific configuration
configure :build do
  activate :minify_css
  activate :minify_javascript
  activate :asset_hash
  activate :relative_assets
  activate :disqus, :shortname => "padrinorb"
end
