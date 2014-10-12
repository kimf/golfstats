js_files =  %w(jquery-2.1.1.min handlebars-v2.0.0 moment array tmp_functions helpers svg_graphs app)

guard :concat, type: "js", files: js_files, input_dir: "js", output: "public/js/golfstats" do
  watch 'js/*.js'
end

guard 'livereload', apply_css_live: true do
  watch(%r{public/.+\.(css|js|html)})
end