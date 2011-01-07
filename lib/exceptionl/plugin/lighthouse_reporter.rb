require 'lighthouse-api'

# A simple plugin for reporting exceptions as new bugs in Lighthouse.
class Exceptionl::Plugin::LighthouseReporter < Exceptionl::Plugin::Base

  attr_reader :project_id
  def initialize(app, params = {})
    app.class.send(:include, Actions)
    app.lighthouse = self
    Lighthouse.account = params['account']
    Lighthouse.token = params['token']
    @project_id = params['project_id']
  end
  
  def exception_links(exception_report)
    [["Report to Lighthouse", "/lighthouse/report/#{exception_report.id}.html"]]
  end

  # Create a new lighthouse ticket object populated with information
  # about +exception+.
  def new_ticket(request, exception)
    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = "Exception: #{exception.exception}"
    ticket_link = "#{request.scheme}://#{request.host}:#{request.port}/exceptions/#{exception.id}.html"
    ticket.body = ticket_link
    ticket.tags = "exception"
    ticket
  end

  # Post a new ticket to lighthouse with the params specified in +params+.
  def post_ticket(params)
    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = params[:title]
    ticket.body = params[:body]
    ticket.tags = params[:tags]
    ticket.save
  end

  module Actions

    def self.included(base)
      base.class_eval do

        attr_accessor :lighthouse

        get '/lighthouse/report/:id.html' do
          @exception = store.find(params["id"])
          @ticket = lighthouse.new_ticket(request, @exception)
          erb File.read(File.expand_path('views/report.erb', File.dirname(__FILE__)))
        end

        post '/lighthouse/report/:id.html' do
          if lighthouse.post_ticket(params)
            redirect "/exceptions/#{params[:id]}.html"
          else
            @error = "There was an error submitting the ticket: <br />#{@ticket.errors.join("<br />")}"
            erb File.read(File.expand_path('views/report.erb', File.dirname(__FILE__)))
          end
        end
      end
    end
  end
end

