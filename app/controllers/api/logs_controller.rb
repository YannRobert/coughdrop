class Api::LogsController < ApplicationController
  before_filter :require_api_token, :except => [:lam]
  def index
    user = User.find_by_path(params['user_id'])
    return unless allowed?(user, 'supervise')
    user_ids = [user.id]
    user_ids = [] if params['supervisees']
    if params['supervisees']
      user_ids += user.supervisees.map(&:id)
    end
    user_ids = user_ids.uniq
    
    options = {:start => params['start'], :end => params['end']}
    Stats.sanitize_find_options!(options)
    logs = LogSession.where({:user_id => user_ids}).where.not({:started_at => nil})
    params['type'] ||= 'all'
    if params['type'] != 'all'
      logs = logs.where(:log_type => params['type'])
    end
    if params['location_id']
      location = ClusterLocation.find_by_global_id(params['location_id'])
      if location
        if location.cluster_type == 'geo'
          logs = logs.where(:geo_cluster_id => location.id)
        else
          logs = logs.where(:ip_cluster_id => location.id)
        end
      else
        logs = logs.where(:id => 0)
      end
    end
    if params['device_id']
      device = Device.find_by_global_id(params['device_id'])
      if device
        logs = logs.where(:device_id => device.id)
      else
        logs = logs.where(:id => 0)
      end
    end
    if params['start']
      logs = logs.where(['started_at > ?', options[:start_at]])
    end
    if params['end']
      logs = logs.where(['ended_at < ?', options[:end_at]])
    end
    logs = logs.order('started_at DESC, id')
    render json: JsonApi::Log.paginate(params, logs)
  end
  
  def show
    log = LogSession.find_by_global_id(params['id'])
    user = log && log.user
    return unless allowed?(user, 'supervise')
    
    render json: JsonApi::Log.as_json(log, :wrapper => true).to_json
  end

  def create
    ip = request.env["HTTP_X_FORWARDED_FOR"] || request.remote_ip
    user_id = params['user_id'] || (params['log'] && params['log']['user_id'])
    user = user_id ? User.find_by_path(user_id) : @api_user
    return unless allowed?(user, 'supervise')
    
    log = LogSession.process_as_follow_on(params['log'], {
      :author => @api_user,
      :ip_address => ip,
      :user => user,
      :device => @api_device
    })
    if !log || log.errored?
      api_error(400, {error: "log creation failed", errors: log && log.processing_errors})
    else
      render json: JsonApi::Log.as_json(log, :wrapper => true).to_json
    end
  end
  
  def update
    log = LogSession.find_by_global_id(params['id'])
    user = log && log.user
    return unless allowed?(user, 'supervise')
    
    log.process(params['log'], {
      :author => @api_user,
      :user => user,
      :device => @api_device,
      :update_only => true
    })
    
    render json: JsonApi::Log.as_json(log, :wrapper => true).to_json
  end
  
  def lam
    log = LogSession.find_by_global_id(params['log_id'])
    if !log || (log.data['nonce'] != params['nonce'])
      render plain: "Not found"
    else
      render plain: Stats.lam([log])
    end
  end
  
end
