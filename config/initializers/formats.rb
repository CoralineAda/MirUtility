custom_date_formats = {
  :concise => '%m/%d/%Y',
  :date => '%B %e, %Y',
  :date_time => '%b %e, %Y %I:%M %p',
  :day_only => '%d',
  :filename => '%m_%d_%y',
  :month_year => '%B %Y',
  :reverse => '%Y/%m/%d',
  :short_date_time => '%m/%d/%y at %l:%M %p',
  :short_month => '%b',
  :short_month_day => '%b %d',
  :short_month_year => '%b %Y',
  :time => '%I:%M %p',
  :no_year => '%B %d',
  :year_month => '%Y-%m'
}
Date::DATE_FORMATS.merge!(custom_date_formats)
Time::DATE_FORMATS.merge!(custom_date_formats)
