require 'lighthouse'

# A simple plugin for reporting exceptions as new bugs in
# {Lighthouse}[http://lighthouseapp.com]. When this plugin is enabled,
# a new link will show up on the exception detail page that
# pre-populates a form for sending the exception report to Lighthouse.
class Exceptionl::Plugin::LighthouseReporter < Exceptionl::Plugin::Base

  # The lighthouse project id that this plugin will report bugs to.
  attr_reader :project_id

  # Creates a new instance of this plugin. There are a few parameters
  # that must be passed in in order for this plugin to work correctly:
  #
  # [params['account']] The Lighthouse account name these exceptions
  #                     will be posted as
  # 
  # [params['token']] The read/write token assigned by Lighthouse for
  #                   API access
  # 
  # [params['project_id']] The Lighthouse project these exceptions
  #                        will be reported to
  def initialize(app, params = {})
    super(app, params)
    app.class.send(:include, Actions)
    app.lighthouse = self
    Lighthouse.account = params['account']
    Lighthouse.token = params['token']
    @project_id = params['project_id']
  end

  # A list containing the link that will show up on the exception
  # report's detail page. This link hooks into one of the new actions
  # defined by this plugin.
  def exception_links(exception_report)
    super(exception_report) + [["Report to Lighthouse", "/lighthouse/report/#{exception_report.id}.html"]]
  end

  # Create a new Lighthouse ticket object pre-populated with information
  # about +exception+.
  def new_ticket(request, exception)
    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = "Exception: #{exception.exception}"
    host_with_port = request.host
    host_with_port << ":#{request.port}" if request.port != 80
    ticket_link = "#{request.scheme}://#{host_with_port}/exceptions/#{exception.id}.html"
    ticket.body = ticket_link
    ticket.tags = "exception"
    ticket
  end

  # Post a new ticket to lighthouse with the params specified in
  # +params+.
  def post_ticket(params)
    ticket = Lighthouse::Ticket.new(:project_id => project_id)
    ticket.title = params[:title]
    ticket.body = params[:body]
    ticket.tags = params[:tags]
    ticket.save
  end

  # Extra actions that will be added to the Exceptionl::Server
  # instance when this plugin is enabled. Provides actions for
  # creating a new Lighthouse ticket with exception details and
  # posting the ticket to Lighthouse. This module also adds a
  # +lighthouse+ accessor to the server instance that can be used to
  # build and send tickets to Lighthouse.
  module Actions

    # Adds the actions described above to the Exceptionl::Server
    # instance.
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

