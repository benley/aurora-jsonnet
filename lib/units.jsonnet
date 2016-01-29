{
  byte: 1,
  KB: 1024 * self.byte,
  MB: 1024 * self.KB,
  GB: 1024 * self.MB,
  TB: 1024 * self.GB,
  PB: 1024 * self.TB,

  second: 1,
  minute: 60 * self.second,
  hour: 60 * self.minute,
  day: 24 * self.hour,
  week: 7 * self.day,
  month: 30.5 * self.day,  # *average* month. Do not use this for calendaring.
  year: 365.25 * self.day, # Likewise, this is an *Average Year*. Don't use this for calendaring.
}
