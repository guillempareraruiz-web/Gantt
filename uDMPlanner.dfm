object DMPlanner: TDMPlanner
  Height = 240
  Width = 320
  PixelsPerInch = 96
  object ADOConnection: TADOConnection
    CommandTimeout = 60
    ConnectionString = 
      'Provider=MSOLEDBSQL.1;Integrated Security=SSPI;Persist Security ' +
      'Info=False;User ID="";Initial Catalog=FS;Data Source=localhost\S' +
      'QLEXPRESS;Initial File Name="";Server SPN="";Authentication="";A' +
      'ccess Token="";'
    LoginPrompt = False
    Provider = 'MSOLEDBSQL.1'
    Left = 56
    Top = 32
  end
end
