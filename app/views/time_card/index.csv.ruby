require 'csv'
bom = "\uFEFF"
CSV.generate(bom) do |csv|
  csv_column_names = %W(#{l(:table_title_day)} #{l(:table_title_punchin)} #{l(:table_title_punchout)} #{l(:table_title_worked)} #{l(:table_title_remarks)})
  csv << csv_column_names
  @timerecords.each do |rec|
    csv_column_values = [
      rec["day"].strftime("%d")+"("+l(:weekday).split(/\s+/)[rec["day"].wday]+")",
      rec["punchin_tm"].nil? ? "" : getMyDateTime(rec["punchin_tm"]).strftime("%H:%M"),
      rec["punchout_tm"].nil? ? "" : getMyDateTime(rec["punchout_tm"]).strftime("%H:%M"),
      rec["hours"] == 0 ? "" : rec["hours"],
      rec["remarks_tx"]
    ]
    csv << csv_column_values
  end
end