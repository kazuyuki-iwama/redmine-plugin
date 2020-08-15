module TimeCardHelper
  def getMyDateTime(i_datetime)
    return i_datetime.in_time_zone(User.current.time_zone)
  end
end
