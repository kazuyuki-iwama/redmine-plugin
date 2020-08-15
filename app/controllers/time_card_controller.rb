class TimeCardController < ApplicationController
  before_action :require_login

  def require_login
    unless User.current.logged?
      flash[:error] = l(:require_login_msg)
      redirect_to :signin
    end
  end
  
  def index
    @selectUser = params["user"].blank? ? User.current.id : params["user"]
    selectMonth = params["month"].blank? ? Date.today : params["month"].to_date
    getrecords(@selectUser ,selectMonth)
    @monthcurrent = selectMonth.strftime('%Y/%-m')
    @monthprev = selectMonth.beginning_of_month.yesterday.strftime('%Y-%m-%d')
    @monthnext = selectMonth.end_of_month.tomorrow.strftime('%Y-%m-%d')
  end

  def paging
    begin
      @selectUser = params["user"].blank? ? User.current.id : params["user"]
      selectMonth = params["month"].to_date
      getrecords(@selectUser ,selectMonth)
      @monthcurrent = selectMonth.strftime('%Y-%-m')
      @monthprev = selectMonth.beginning_of_month.yesterday.strftime('%Y-%m-%d')
      @monthnext = selectMonth.end_of_month.tomorrow.strftime('%Y-%m-%d')
    rescue => e
      @errmsg = e
    end
    render action: :index
  end

  def punchin
    @selectUser = params["user"].blank? ? User.current.id : params["user"]
    @errmsg = ''
    @printtime = DateTime.now
    begin
      # upsert
      timerecorder = Timecard.find_by!(key: getkey(User.current.id,@printtime))
      timerecorder.punchin_tm  = @printtime
      timerecorder.save
    rescue ActiveRecord::RecordNotFound => e
      begin
        timerecorder = Timecard.create(key:getkey(User.current.id,@printtime) ,calender_dt:@printtime.strftime('%Y/%m/%d'),user_id:User.current.id ,punchin_tm:@printtime,punchout_tm:"",edit_fg:"",remarks_tx:"")
      rescue => e
        @errmsg = e
      end
    rescue => e
      @errmsg = e
    end
    if @errmsg.blank?
      getrecords(User.current.id ,@printtime)
      @monthcurrent = @printtime.strftime('%Y/%-m')
      @monthprev = @printtime.beginning_of_month.yesterday.strftime('%Y-%m-%d')
      @monthnext = @printtime.end_of_month.tomorrow.strftime('%Y-%m-%d')
      render action: :index
    end
  end

  def punchout
    @selectUser = params["user"].blank? ? User.current.id : params["user"]
    @errmsg = ''
    @printtime = DateTime.now
    begin
      timerecorder = Timecard.find_by!(key: getkey(User.current.id,@printtime))
      timerecorder.update(punchout_tm:@printtime)
      timerecorder.save
    rescue ActiveRecord::RecordNotFound => e
      begin
        timerecorder = Timecard.create(key:getkey(User.current.id,@printtime) ,calender_dt:@printtime.strftime('%Y/%m/%d'),user_id:User.current.id ,punchin_tm:"",punchout_tm:@printtime,edit_fg:"",remarks_tx:"")
      rescue => e
        @errmsg = e
      end
    rescue => e
      @errmsg = e
    end
    if @errmsg.blank?
      getrecords(User.current.id ,@printtime)
      @monthcurrent = @printtime.strftime('%Y/%-m')
      @monthprev = @printtime.beginning_of_month.yesterday.strftime('%Y-%m-%d')
      @monthnext = @printtime.end_of_month.tomorrow.strftime('%Y-%m-%d')
      render action: :index
    end
  end

  def edit
    begin
      @editday = params["editday"].to_date
      timerecorder = Timecard.find_by!(key: getkey(User.current.id,@editday))
      @edittimepunchin = timerecorder.punchin_tm
      @edittimepunchout = timerecorder.punchout_tm
      @editremarks = timerecorder.remarks_tx
    rescue ActiveRecord::RecordNotFound => e
      @edittimepunchin = nil
      @edittimepunchout = nil
      @editremarks = ""
    rescue => e
      @errmsg = e
    end
  end

  def edited
    @selectUser = params["user"].blank? ? User.current.id : params["user"]
    begin
      # check value
      begin
        if !params["edit_time_punchin"].blank?
          wk = Time.strptime('2000-01-01T'+params["edit_time_punchin"], '%Y-%m-%dT%H:%M')
        end
      rescue => e
        @errmsg = params["edit_time_punchin"]+l(:edit_time_format_err)
        return
      end
      begin
        if !params["edit_time_punchout"].blank?
          wk = Time.strptime('2000-01-01T'+params["edit_time_punchout"], '%Y-%m-%dT%H:%M')
        end
      rescue => e
        @errmsg = params["edit_time_punchout"]+l(:edit_time_format_err)
        return
      end
      
      # upsert
      @editday = params["editday"].to_date
      if params["edit_time_punchin"].blank?
        edit_time_punchin = nil
      else
        edit_time_punchin = Time.strptime(@editday.strftime('%Y-%m-%d')+'T'+params["edit_time_punchin"], '%Y-%m-%dT%H:%M')
      end
      if params["edit_time_punchout"].blank?
        edit_time_punchout = nil
      else
        edit_time_punchout = Time.strptime(@editday.strftime('%Y-%m-%d')+'T'+params["edit_time_punchout"], '%Y-%m-%dT%H:%M')
      end
      edit_remarks = params["edit_remarks"]
      
      timerecorder = Timecard.find_by!(key: getkey(User.current.id,@editday))
      timerecorder.punchin_tm  = edit_time_punchin
      timerecorder.punchout_tm = edit_time_punchout
      timerecorder.edit_fg    = true
      timerecorder.remarks_tx = edit_remarks
      timerecorder.save
    rescue ActiveRecord::RecordNotFound => e
      begin
        timerecorder = Timecard.create(key:getkey(User.current.id,@editday) ,calender_dt:@editday.strftime('%Y/%m/%d'),user_id:User.current.id ,punchin_tm:edit_time_punchin,punchout_tm:edit_time_punchout,edit_fg:true,remarks_tx:edit_remarks)
      rescue => e
        @errmsg = e
      end
    rescue => e
      @errmsg = e
    end
    if @errmsg.blank?
      getrecords(User.current.id ,@editday)
      @monthcurrent = @editday.strftime('%Y/%-m')
      @monthprev = @editday.beginning_of_month.yesterday.strftime('%Y-%m-%d')
      @monthnext = @editday.end_of_month.tomorrow.strftime('%Y-%m-%d')
      render action: :index
    else
      render action: :edit
    end
  end

  def getrecords(userid ,searchdt)
    entry = Hash.new
    begin
      wk = Timecard.where("user_id = ? and calender_dt between ? and ?" ,userid , searchdt.beginning_of_month ,searchdt.end_of_month)
      wk.each { |r|
        entry[r.calender_dt.strftime('%d')] = r
      }
    rescue => e
      @errmsg = e
    end
    @timerecords = []
    (searchdt.beginning_of_month..searchdt.end_of_month).each { |date|
      timeentry = TimeEntry.where("user_id = ? and spent_on = ?" ,userid ,date.strftime('%Y/%m/%d'))
      if timeentry.nil?
        entryhour = nil
      else
        entryhour = timeentry.all.sum(:hours)
      end
      if entry.has_key?(date.strftime('%d')) 
        @timerecords << { "day" => date ,"punchin_tm" => entry[date.strftime('%d')].punchin_tm ,"punchout_tm" => entry[date.strftime('%d')].punchout_tm ,"remarks_tx" => entry[date.strftime('%d')].remarks_tx ,"hours" => entryhour}
      else
        @timerecords << { "day" => date ,"punchin_tm" => nil ,"punchout_tm" => nil ,"remarks_tx" => nil ,"hours" => entryhour}
      end
    }
    timerecorder = Timecard.find_by(key: getkey(userid,DateTime.now))
    if !timerecorder.nil?
      @todaypunchin = timerecorder.punchin_tm
      @todaypunchout = timerecorder.punchout_tm
    else
      @todaypunchin = ""
      @todaypunchout = ""
    end
  end

  def getkey(userid,searchdt)
    return "#{userid}_#{searchdt.strftime('%Y%m%d')}"
  end
end
