require "sinatra/base"
require "active_record"
require "./db/ar_config"
require "./helpers/application_helper"
require "sinatra/content_for2"
require "sinatra/reloader"
require "sinatra_more/routing_plugin"
require_relative "admin"
Dir[File.dirname(__FILE__) + "/db/models/*.rb"].each {|file| require file }

class Main < Sinatra::Base

  register Sinatra::Reloader
  register SinatraMore::RoutingPlugin
  register SinatraMore::MarkupPlugin
  helpers Sinatra::ContentFor2

  map(:home).to('/')
  map(:feedback).to('/feedback')
  map(:view_lesson).to('/lesson/:id')

  set :ref_img_dir, 'assets/ref_img'
  set :lesson_dir, 'assets/lesson_av'

  get :home do

    @categories = Category.where(:parent_id => nil)

    erb :index

  end

  # ----- Feedback -----

  post :feedback do
    fb = params[:feedback]

    feedback = Feedback.new
    feedback.user_name = fb['user_name']
    feedback.email = fb['email']
    feedback.subject = fb['subject']
    feedback.comment = fb['comment']
    feedback.url = fb['url']

    feedback.save
  end


  # ----- Lesson -----

  get :view_lesson do
    #exception handling required!

    @lesson = Lesson.find(params[:id])
    @categories = Category.where(:parent_id => nil)

    erb :'lesson/index'
  end

  use SalaamPodAdmin

end