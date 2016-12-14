require 'active_support'
require 'active_support/core_ext'
require 'active_support/inflector'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = {})
    @req = req
    @res = res
    @params = params
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    !!@already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise if already_built_response?
    res.location = url
    res.status = 302
    @already_built_response = true
    session.store_session(res)
    nil
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise if already_built_response?
    res.set_header('Content-Type', content_type)
    res.write(content)
    @already_built_response = true
    session.store_session(res)
    nil
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    folder = self.class.name.underscore
    file = "#{template_name}.html.erb"
    path = "./views/#{folder}/#{file}"

    content = ERB.new(File.read(path)).result(binding)
    render_content(content, 'text/html')
  end

  # method exposing a `Session` object
  def session
    ##Construct session from Request
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render(name) unless already_built_response?
  end
end
