require "sinatra/base"
require "active_record"
require "./db/ar_config"
require "./helpers/application_helper"
require "sinatra/content_for2"
require "sinatra/reloader"
require "sinatra_more/routing_plugin"
require 'sinatra_more/markup_plugin'
require "sinatra/flash"
require "json"
require_relative "admin"

Dir[File.dirname(__FILE__) + "/db/models/*.rb"].each { |file| require file }


class Main < Sinatra::Base

  register Sinatra::Reloader
  register SinatraMore::RoutingPlugin
  register SinatraMore::MarkupPlugin
  register Sinatra::Flash

  enable :sessions

  map(:home).to('/')
  map(:feedback).to('/feedback')
  map(:sign_up).to('/sign_up')
  map(:login).to('/login')
  map(:view_lesson).to('/lesson/:id')
  map(:lookup_words).to("/lesson/:id/lookup_words")
  map(:content_suggestion).to("/suggest_content")
  map(:sign_out).to('/sign_out')
  map(:question_page).to('/lesson/:lesson_id/question/page/:page')
  map(:fetch_microblog).to('/lesson/:lesson_id/microblog/:page')


  configure :development do

    register Sinatra::Reloader

  end



  set :ref_img_dir, 'assets/ref_img'
  set :lesson_dir, 'assets/lesson_av'

  get :home do

    @categories = Category.where(:parent_id => nil)

    erb :index

  end

  # -----------Sign Up--------------------------
  post :sign_up do
    fb = params[:sign_up]

    user = User.new
    user.name = fb['name']
    user.mail_address = fb['mail_address']
    user.password = fb['password']

    user.save

    #flash[:notice] = "Your account Was Created ."

    redirect url_for(:home)

  end

  #----------------- Sign In --------------------

  post :login do

    fb = params[:login]

    u = fb['user_name']
    p = fb['password']

    user = User.find_by_mail_address_and_password(fb['user_name'], fb['password'])

    if user.present?  && user.enable

      session['user_name'] = u

    end

    redirect url_for(:home)

  end

  # -----------  Sign  out --------------------------

  get :sign_out do

    session['user_name']=nil

    redirect url_for(:home)

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

  get :question_page do

    @lesson_id=params[:lesson_id].to_i
    @page=params[:page].to_i
    @rows=Lesson.find(@lesson_id).questions.offset(5*@page ).limit(5)

    erb :'lesson/partial/question_row', :layout => false

  end

  # ----- Lesson -----

  get :view_lesson do
    #exception handling required!

    @lesson = Lesson.where(:id => params[:id])
      .includes(:objectives, :references, :category)
      .first

    @categories = Category.where(:parent_id => nil).includes(:sub_categories)

    erb :'lesson/index'

  end

  # ----- Load microblogs -----

  get :fetch_microblog do
    #TODO: exception handling required

    lesson_id = params[:lesson_id].to_i
    page = params[:page].to_i
    microblogs = BlogPost.where(:lesson_id => lesson_id).includes(:comments => :user).offset(5 * page).limit(5)

    content_type :json

    microblogs.to_json(:only => [:id, :title, :content], :methods => :posted_on, :include =>
        {:comments => {:include => :user}})

  end


  get :lookup_words do

    words = Lesson.find(params[:id]).glossary_words

    #TODO: word lookup can be optimized
    #word_w_defs = GlossaryEntry.where(:entry => words.split(','))

    definitions = get_meaning_for words
    content_type :json

    Hash[words.split(",").zip(definitions)].to_json

  end

  # ----- Content Suggestion -----

  post :content_suggestion do

    fb = params[:content_suggestion]

    content_suggestion = ContentSuggestion.new

    content_suggestion.name = fb['name']
    content_suggestion.email = fb['email']
    content_suggestion.subject = fb['subject']
    content_suggestion.content = fb['content']

    content_suggestion.save

  end


  use SalaamPodAdmin

end